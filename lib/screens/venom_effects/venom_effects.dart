import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

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
  final String _configPath = '${Platform.environment['HOME']}/.config/picom/picom.conf';

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
      _shadowRed = 0.0; _shadowGreen = 0.0; _shadowBlue = 0.0;
      
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
        final shadowMatch = RegExp(r'^\s*shadow\s*=\s*(true|false)', multiLine: true).firstMatch(content);
        if (shadowMatch != null) _shadowEnabled = shadowMatch.group(1) == 'true';
        
        final sRadiusMatch = RegExp(r'^\s*shadow-radius\s*=\s*(\d+)', multiLine: true).firstMatch(content);
        if (sRadiusMatch != null) _shadowRadius = double.tryParse(sRadiusMatch.group(1)!) ?? 35.0;

        final sOpacityMatch = RegExp(r'^\s*shadow-opacity\s*=\s*([\d\.]+)', multiLine: true).firstMatch(content);
        if (sOpacityMatch != null) _shadowOpacity = double.tryParse(sOpacityMatch.group(1)!) ?? 0.5;
        
        // Colors
        final sRedMatch = RegExp(r'^\s*shadow-red\s*=\s*([\d\.]+)', multiLine: true).firstMatch(content);
        if (sRedMatch != null) _shadowRed = double.tryParse(sRedMatch.group(1)!) ?? 0.0;
        final sGreenMatch = RegExp(r'^\s*shadow-green\s*=\s*([\d\.]+)', multiLine: true).firstMatch(content);
        if (sGreenMatch != null) _shadowGreen = double.tryParse(sGreenMatch.group(1)!) ?? 0.0;
        final sBlueMatch = RegExp(r'^\s*shadow-blue\s*=\s*([\d\.]+)', multiLine: true).firstMatch(content);
        if (sBlueMatch != null) _shadowBlue = double.tryParse(sBlueMatch.group(1)!) ?? 0.0;

        // --- Blur ---
        final bStrengthMatch = RegExp(r'strength\s*=\s*(\d+)').firstMatch(content);
        if (bStrengthMatch != null) _blurStrength = double.tryParse(bStrengthMatch.group(1)!) ?? 5.0;
        
        final bMethodMatch = RegExp(r'method\s*=\s*"(\w+)"').firstMatch(content);
        if (bMethodMatch != null) _blurEnabled = (bMethodMatch.group(1) != "none");

        // --- Animations (Fading) ---
        final fadeMatch = RegExp(r'^\s*fading\s*=\s*(true|false)', multiLine: true).firstMatch(content);
        if (fadeMatch != null) _fadingEnabled = fadeMatch.group(1) == 'true';
        
        // قراءة سرعة الفيد وتحويلها لنسبة مئوية (0.01-0.1) -> (0-100)
        final fadeStepMatch = RegExp(r'^\s*fade-in-step\s*=\s*([\d\.]+)', multiLine: true).firstMatch(content);
        if (fadeStepMatch != null) {
          double rawStep = double.tryParse(fadeStepMatch.group(1)!) ?? 0.07;
          // معادلة عكسية تقريبية: (step - 0.01) / 0.0009
          _fadeSpeed = ((rawStep - 0.01) * 1000).clamp(0.0, 100.0);
        }

        // --- Geometry ---
        final cRadiusMatch = RegExp(r'^\s*corner-radius\s*=\s*(\d+)', multiLine: true).firstMatch(content);
        if (cRadiusMatch != null) _cornerRadius = double.tryParse(cRadiusMatch.group(1)!) ?? 10.0;

        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; _errorMessage = e.toString(); });
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
            RegExp(r'(^\s*' + RegExp.escape(key) + r'\s*=\s*)([^;]+)', multiLine: true),
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
        content = replaceValue('shadow-radius', _shadowRadius.toInt().toString());
        content = replaceValue('shadow-opacity', _shadowOpacity.toStringAsFixed(2));
        content = replaceValue('shadow-red', _shadowRed.toStringAsFixed(2));
        content = replaceValue('shadow-green', _shadowGreen.toStringAsFixed(2));
        content = replaceValue('shadow-blue', _shadowBlue.toStringAsFixed(2));
        
        // Blur
        content = replaceBlockValue('strength', _blurStrength.toInt().toString());
        content = replaceBlockValue('method', _blurEnabled ? '"dual_kawase"' : '"none"');

        // Animations
        content = replaceValue('fading', _fadingEnabled.toString());
        // معادلة التحويل من 0-100 إلى 0.01-0.10
        // كلما زاد الرقم زادت السرعة (Step أكبر)
        double stepValue = 0.01 + (_fadeSpeed / 1000); 
        content = replaceValue('fade-in-step', stepValue.toStringAsFixed(3));
        content = replaceValue('fade-out-step', stepValue.toStringAsFixed(3));

        // Geometry
        content = replaceValue('corner-radius', _cornerRadius.toInt().toString());

        await file.writeAsString(content);
        debugPrint("Config updated successfully!");

      } catch (e) {
        debugPrint("Error saving config: $e");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Stack(
        children: [
          Container(color: const Color.fromARGB(0, 0, 0, 0),),
          Center(
            child: Container(
              // width: 550,
              // height: 750, // زيادة الارتفاع لاستيعاب الأنيميشن
              decoration: BoxDecoration(
                color: const Color.fromARGB(0, 0, 0, 0), 
                // borderRadius: BorderRadius.circular(25),
                // border: Border.all(color: const Color.fromARGB(255, 7, 7, 7).withOpacity(0.6), width: 1.5),
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
                        const Text("Venom Effects", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                        IconButton(
                          icon: const Icon(Icons.restart_alt_rounded, color: Color(0xFFBB9AF7), size: 28),
                          onPressed: _resetToDefaults,
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white10, indent: 30, endIndent: 30),
                  
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      children: [
                        
                        // === SHADOWS ===
                        _buildSectionContainer(
                          context,
                          "Shadows", Icons.layers_outlined,
                          [
                            _buildSwitch("Enable Shadows", _shadowEnabled, (v) {
                              setState(() => _shadowEnabled = v);
                              _updateConfig();
                            }),
                            _buildSlider("Radius", _shadowRadius, 0, 100, (v) {
                              setState(() => _shadowRadius = v);
                              _updateConfig();
                            }, enabled: _shadowEnabled),
                            _buildSlider("Opacity", _shadowOpacity, 0.0, 1.0, (v) {
                              setState(() => _shadowOpacity = v);
                              _updateConfig();
                            }, enabled: _shadowEnabled),
                             const SizedBox(height: 10),
                             // Color Sliders (Compact)
                            Row(
                              children: [
                                Expanded(child: _buildColorSlider(_shadowRed, Colors.redAccent, (v) { setState(() => _shadowRed = v); _updateConfig(); }, _shadowEnabled)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildColorSlider(_shadowGreen, Colors.greenAccent, (v) { setState(() => _shadowGreen = v); _updateConfig(); }, _shadowEnabled)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildColorSlider(_shadowBlue, Colors.blueAccent, (v) { setState(() => _shadowBlue = v); _updateConfig(); }, _shadowEnabled)),
                              ],
                            ),
                          ],
                        ),
            
                        const SizedBox(height: 20),
            
                        // === BLUR ===
                        _buildSectionContainer(
                          context,
                          "Blur (Glass)", Icons.blur_on,
                          [
                            _buildSwitch("Enable Blur", _blurEnabled, (v) {
                              setState(() => _blurEnabled = v);
                              _updateConfig();
                            }),
                            _buildSlider("Blur Strength", _blurStrength, 0, 20, (v) {
                              setState(() => _blurStrength = v);
                              _updateConfig();
                            }, enabled: _blurEnabled),
                          ],
                        ),
            
                        const SizedBox(height: 20),
            
                        // === NEW: ANIMATIONS ===
                        _buildSectionContainer(
                          context,
                          "Animations", Icons.animation,
                          [
                            _buildSwitch("Enable Fading", _fadingEnabled, (v) {
                              setState(() => _fadingEnabled = v);
                              _updateConfig();
                            }),
                            // كلما زادت القيمة زادت سرعة الأنيميشن
                            _buildSlider("Animation Speed", _fadeSpeed, 10, 100, (v) {
                              setState(() => _fadeSpeed = v);
                              _updateConfig();
                            }, enabled: _fadingEnabled),
                          ],
                        ),
            
                        const SizedBox(height: 20),
            
                        // === GEOMETRY ===
                        _buildSectionContainer(
                          context,
                          "Geometry", Icons.rounded_corner,
                          [
                            _buildSlider("Corner Radius", _cornerRadius, 0, 30, (v) {
                              setState(() => _cornerRadius = v);
                              _updateConfig();
                            }),
                          ],
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

  // --- Helpers --- (نفس الـ Helpers السابقة تماماً)
  Widget _buildSectionContainer(BuildContext context, String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFBB9AF7), size: 20),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitch(String title, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70)),
        Transform.scale(scale: 0.8, child: Switch(value: value, onChanged: onChanged)),
      ],
    );
  }

  Widget _buildSlider(String title, double value, double min, double max, Function(double) onChanged, {bool enabled = true}) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.white60)),
              Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 12, color: Color(0xFFBB9AF7), fontWeight: FontWeight.bold)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(overlayShape: SliderComponentShape.noOverlay),
            child: Slider(value: value, min: min, max: max, onChanged: enabled ? onChanged : null),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSlider(double value, Color color, Function(double) onChanged, bool enabled) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: SizedBox(
        height: 20,
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color, thumbColor: Colors.white, trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6), overlayShape: SliderComponentShape.noOverlay),
          child: Slider(value: value, min: 0, max: 1, onChanged: enabled ? onChanged : null),
        ),
      ),
    );
  }
}