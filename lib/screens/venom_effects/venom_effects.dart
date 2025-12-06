import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:antidote/screens/venom_effects/widgets/shadows_section.dart';
import 'package:antidote/screens/venom_effects/widgets/blur_section.dart';
import 'package:antidote/screens/venom_effects/widgets/animations_section.dart';
import 'package:antidote/screens/venom_effects/widgets/geometry_section.dart';

class CompositorSettingsPage extends StatefulWidget {
  const CompositorSettingsPage({Key? key}) : super(key: key);

  @override
  State<CompositorSettingsPage> createState() => _CompositorSettingsPageState();
}

class _CompositorSettingsPageState extends State<CompositorSettingsPage> {
  bool _isLoading = true;
  // ignore: unused_field
  String? _errorMessage;
  Timer? _debounce;
  final String _configPath =
      '${Platform.environment['HOME']}/.config/picom/picom.conf';

  // --- Shadows ---
  bool _shadowEnabled = true;
  double _shadowRadius = 35.0;
  double _shadowOpacity = 0.5;
  double _shadowRed = 0.0;
  double _shadowGreen = 0.0;
  double _shadowBlue = 0.0;

  // --- Blur ---
  bool _blurEnabled = true;
  double _blurStrength = 5.0;

  // --- Animations (Fading) ---
  bool _fadingEnabled = true;
  double _fadeSpeed = 50.0; // من 0 إلى 100 لسهولة الاستخدام

  // --- Geometry ---
  double _cornerRadius = 10.0;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _resetToDefaults() {
    setState(() {
      _shadowEnabled = true;
      _shadowRadius = 35.0;
      _shadowOpacity = 0.5;
      _shadowRed = 0.0;
      _shadowGreen = 0.0;
      _shadowBlue = 0.0;

      _blurEnabled = true;
      _blurStrength = 5.0;

      _fadingEnabled = true;
      _fadeSpeed = 70.0; // سرعة متوسطة جيدة

      _cornerRadius = 10.0;
      _updateConfig();
    });
  }

  Future<void> _loadConfig() async {
    try {
      final file = File(_configPath);
      if (!await file.exists()) throw Exception("Config file not found");
      final content = await file.readAsString();

      setState(() {
        // --- Shadows ---
        final shadowMatch = RegExp(
          r'^\s*shadow\s*=\s*(true|false)',
          multiLine: true,
        ).firstMatch(content);
        if (shadowMatch != null)
          _shadowEnabled = shadowMatch.group(1) == 'true';

        final sRadiusMatch = RegExp(
          r'^\s*shadow-radius\s*=\s*(\d+)',
          multiLine: true,
        ).firstMatch(content);
        if (sRadiusMatch != null)
          _shadowRadius = double.tryParse(sRadiusMatch.group(1)!) ?? 35.0;

        final sOpacityMatch = RegExp(
          r'^\s*shadow-opacity\s*=\s*([\d\.]+)',
          multiLine: true,
        ).firstMatch(content);
        if (sOpacityMatch != null)
          _shadowOpacity = double.tryParse(sOpacityMatch.group(1)!) ?? 0.5;

        // Colors
        final sRedMatch = RegExp(
          r'^\s*shadow-red\s*=\s*([\d\.]+)',
          multiLine: true,
        ).firstMatch(content);
        if (sRedMatch != null)
          _shadowRed = double.tryParse(sRedMatch.group(1)!) ?? 0.0;
        final sGreenMatch = RegExp(
          r'^\s*shadow-green\s*=\s*([\d\.]+)',
          multiLine: true,
        ).firstMatch(content);
        if (sGreenMatch != null)
          _shadowGreen = double.tryParse(sGreenMatch.group(1)!) ?? 0.0;
        final sBlueMatch = RegExp(
          r'^\s*shadow-blue\s*=\s*([\d\.]+)',
          multiLine: true,
        ).firstMatch(content);
        if (sBlueMatch != null)
          _shadowBlue = double.tryParse(sBlueMatch.group(1)!) ?? 0.0;

        // --- Blur ---
        final bStrengthMatch = RegExp(
          r'strength\s*=\s*(\d+)',
        ).firstMatch(content);
        if (bStrengthMatch != null)
          _blurStrength = double.tryParse(bStrengthMatch.group(1)!) ?? 5.0;

        final bMethodMatch = RegExp(
          r'method\s*=\s*"(\w+)"',
        ).firstMatch(content);
        if (bMethodMatch != null)
          _blurEnabled = (bMethodMatch.group(1) != "none");

        // --- Animations (Fading) ---
        final fadeMatch = RegExp(
          r'^\s*fading\s*=\s*(true|false)',
          multiLine: true,
        ).firstMatch(content);
        if (fadeMatch != null) _fadingEnabled = fadeMatch.group(1) == 'true';

        // قراءة سرعة الفيد وتحويلها لنسبة مئوية (0.01-0.1) -> (0-100)
        final fadeStepMatch = RegExp(
          r'^\s*fade-in-step\s*=\s*([\d\.]+)',
          multiLine: true,
        ).firstMatch(content);
        if (fadeStepMatch != null) {
          double rawStep = double.tryParse(fadeStepMatch.group(1)!) ?? 0.07;
          // معادلة عكسية تقريبية: (step - 0.01) / 0.0009
          _fadeSpeed = ((rawStep - 0.01) * 1000).clamp(0.0, 100.0);
        }

        // --- Geometry ---
        final cRadiusMatch = RegExp(
          r'^\s*corner-radius\s*=\s*(\d+)',
          multiLine: true,
        ).firstMatch(content);
        if (cRadiusMatch != null)
          _cornerRadius = double.tryParse(cRadiusMatch.group(1)!) ?? 10.0;

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _updateConfig() async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final file = File(_configPath);
        String content = await file.readAsString();

        String replaceValue(String key, String newValue) {
          return content.replaceAllMapped(
            RegExp(
              r'(^\s*' + RegExp.escape(key) + r'\s*=\s*)([^;]+)',
              multiLine: true,
            ),
            (match) => '${match.group(1)}$newValue',
          );
        }

        String replaceBlockValue(String key, String newValue) {
          return content.replaceAllMapped(
            RegExp(r'(\s*' + RegExp.escape(key) + r'\s*=\s*)([^;]+)'),
            (match) => '${match.group(1)}$newValue',
          );
        }

        // Shadows
        content = replaceValue('shadow', _shadowEnabled.toString());
        content = replaceValue(
          'shadow-radius',
          _shadowRadius.toInt().toString(),
        );
        content = replaceValue(
          'shadow-opacity',
          _shadowOpacity.toStringAsFixed(2),
        );
        content = replaceValue('shadow-red', _shadowRed.toStringAsFixed(2));
        content = replaceValue('shadow-green', _shadowGreen.toStringAsFixed(2));
        content = replaceValue('shadow-blue', _shadowBlue.toStringAsFixed(2));

        // Blur
        content = replaceBlockValue(
          'strength',
          _blurStrength.toInt().toString(),
        );
        content = replaceBlockValue(
          'method',
          _blurEnabled ? '"dual_kawase"' : '"none"',
        );

        // Animations
        content = replaceValue('fading', _fadingEnabled.toString());
        // معادلة التحويل من 0-100 إلى 0.01-0.10
        // كلما زاد الرقم زادت السرعة (Step أكبر)
        double stepValue = 0.01 + (_fadeSpeed / 1000);
        content = replaceValue('fade-in-step', stepValue.toStringAsFixed(3));
        content = replaceValue('fade-out-step', stepValue.toStringAsFixed(3));

        // Geometry
        content = replaceValue(
          'corner-radius',
          _cornerRadius.toInt().toString(),
        );

        await file.writeAsString(content);
        debugPrint("Config updated successfully!");
      } catch (e) {
        debugPrint("Error saving config: $e");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CupertinoActivityIndicator());

    return Stack(
      children: [
        Container(color: const Color.fromARGB(0, 0, 0, 0)),
        Center(
          child: Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(0, 0, 0, 0),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(28, 0, 0, 0),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(30, 25, 30, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Venom Effects",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.restart_alt_rounded,
                          color: Color(0xFFBB9AF7),
                          size: 28,
                        ),
                        onPressed: _resetToDefaults,
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10, indent: 30, endIndent: 30),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 10,
                    ),
                    children: [
                      // === SHADOWS ===
                      ShadowsSection(
                        enabled: _shadowEnabled,
                        radius: _shadowRadius,
                        opacity: _shadowOpacity,
                        red: _shadowRed,
                        green: _shadowGreen,
                        blue: _shadowBlue,
                        onEnabledChanged: (v) {
                          setState(() => _shadowEnabled = v);
                          _updateConfig();
                        },
                        onRadiusChanged: (v) {
                          setState(() => _shadowRadius = v);
                          _updateConfig();
                        },
                        onOpacityChanged: (v) {
                          setState(() => _shadowOpacity = v);
                          _updateConfig();
                        },
                        onRedChanged: (v) {
                          setState(() => _shadowRed = v);
                          _updateConfig();
                        },
                        onGreenChanged: (v) {
                          setState(() => _shadowGreen = v);
                          _updateConfig();
                        },
                        onBlueChanged: (v) {
                          setState(() => _shadowBlue = v);
                          _updateConfig();
                        },
                      ),

                      const SizedBox(height: 20),

                      // === BLUR ===
                      BlurSection(
                        enabled: _blurEnabled,
                        strength: _blurStrength,
                        onEnabledChanged: (v) {
                          setState(() => _blurEnabled = v);
                          _updateConfig();
                        },
                        onStrengthChanged: (v) {
                          setState(() => _blurStrength = v);
                          _updateConfig();
                        },
                      ),

                      const SizedBox(height: 20),

                      // === NEW: ANIMATIONS ===
                      AnimationsSection(
                        enabled: _fadingEnabled,
                        speed: _fadeSpeed,
                        onEnabledChanged: (v) {
                          setState(() => _fadingEnabled = v);
                          _updateConfig();
                        },
                        onSpeedChanged: (v) {
                          setState(() => _fadeSpeed = v);
                          _updateConfig();
                        },
                      ),

                      const SizedBox(height: 20),

                      // === GEOMETRY ===
                      GeometrySection(
                        cornerRadius: _cornerRadius,
                        onCornerRadiusChanged: (v) {
                          setState(() => _cornerRadius = v);
                          _updateConfig();
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
