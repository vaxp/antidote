import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dbus/dbus.dart';

class DisplaySettingsPage extends StatefulWidget {
  const DisplaySettingsPage({super.key});

  @override
  State<DisplaySettingsPage> createState() => _DisplaySettingsPageState();
}

class DisplayResolution {
  final int width;
  final int height;
  final String aspectRatio;
  final String mode;

  DisplayResolution({
    required this.width,
    required this.height,
    required this.aspectRatio,
    required this.mode,
  });

  @override
  String toString() => '$width x $height ($aspectRatio)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DisplayResolution &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => width.hashCode ^ height.hashCode;
}

class _DisplaySettingsPageState extends State<DisplaySettingsPage> {
  late DBusClient _sysbus;
  Timer? _updateTimer;

  // Display states
  String _orientation = 'Landscape';
  DisplayResolution? _currentResolution;
  List<DisplayResolution> _availableResolutions = [];
  String _refreshRate = '59.88 Hz';
  int _scale = 100; // 100 or 200
  bool _fractionalScaling = false;
  bool _nightLight = false;

  @override
  void initState() {
    super.initState();
    _sysbus = DBusClient.system();
    _initDisplaySettings();
    _updateTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _refreshDisplayInfo(),
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _sysbus.close();
    super.dispose();
  }

  Future<void> _initDisplaySettings() async {
    await _refreshDisplayInfo();
  }

  Future<void> _refreshDisplayInfo() async {
    if (!mounted) return;
    try {
      await _getCurrentDisplayInfo();
      await _getAvailableResolutions();
      await _getNightLightStatus();
    } catch (e) {
      debugPrint('Display refresh error: $e');
    }
  }

  Future<void> _getCurrentDisplayInfo() async {
    try {
      // Use xrandr to get current display info
      final result = await Process.run('xrandr', ['--current']);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final lines = output.split('\n');

        // Parse current mode
        for (final line in lines) {
          if (line.contains(' connected') && line.contains('+')) {
            // Extract resolution and refresh rate
            final modeMatch = RegExp(r'(\d+)x(\d+)\s+\+.*?(\d+\.\d+)\s*Hz').firstMatch(line);
            if (modeMatch != null) {
              final width = int.tryParse(modeMatch.group(1) ?? '') ?? 1680;
              final height = int.tryParse(modeMatch.group(2) ?? '') ?? 1050;
              final refresh = modeMatch.group(3) ?? '59.88';

              // Calculate aspect ratio
              final gcd = _gcd(width, height);
              final aspectW = width ~/ gcd;
              final aspectH = height ~/ gcd;
              final aspectRatio = '$aspectW : $aspectH';

              setState(() {
                // Try to find matching resolution from available list first
                DisplayResolution? matching;
                if (_availableResolutions.isNotEmpty) {
                  try {
                    matching = _availableResolutions.firstWhere(
                      (r) => r.width == width && r.height == height,
                    );
                  } catch (_) {
                    // Not found, create new one
                  }
                }
                _currentResolution = matching ?? DisplayResolution(
                  width: width,
                  height: height,
                  aspectRatio: aspectRatio,
                  mode: '${width}x${height}',
                );
                _refreshRate = '$refresh Hz';
              });
            }

            // Check orientation
            if (line.contains('left') || line.contains('inverted')) {
              setState(() => _orientation = 'Portrait');
            } else {
              setState(() => _orientation = 'Landscape');
            }

            // Check scale (look for scale factor in xrandr output or use gsettings)
            try {
              final scaleResult = await Process.run('gsettings', [
                'get',
                'org.gnome.desktop.interface',
                'text-scaling-factor',
              ]);
              if (scaleResult.exitCode == 0) {
                final scaleStr = scaleResult.stdout.toString().trim();
                final scaleValue = double.tryParse(scaleStr) ?? 1.0;
                setState(() => _scale = (scaleValue * 100).round());
              }
            } catch (_) {}

            break;
          }
        }
      }
    } catch (e) {
      debugPrint('Get display info error: $e');
      // Set defaults if xrandr fails
      if (_currentResolution == null) {
        setState(() {
          // Try to find default from available list first
          DisplayResolution? matching;
          if (_availableResolutions.isNotEmpty) {
            try {
              matching = _availableResolutions.firstWhere(
                (r) => r.width == 1680 && r.height == 1050,
              );
            } catch (_) {
              // Not found, create new one
            }
          }
          _currentResolution = matching ?? DisplayResolution(
            width: 1680,
            height: 1050,
            aspectRatio: '16 : 10',
            mode: '1680x1050',
          );
        });
      }
    }
  }

  Future<void> _getAvailableResolutions() async {
    try {
      final result = await Process.run('xrandr', []);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final lines = output.split('\n');
        final List<DisplayResolution> resolutions = [];

        for (final line in lines) {
          // Match resolution lines like "   1920x1080     60.00*+"
          final match = RegExp(r'\s+(\d+)x(\d+)\s+').firstMatch(line);
          if (match != null) {
            final width = int.tryParse(match.group(1) ?? '') ?? 0;
            final height = int.tryParse(match.group(2) ?? '') ?? 0;

            if (width > 0 && height > 0) {
              final gcd = _gcd(width, height);
              final aspectW = width ~/ gcd;
              final aspectH = height ~/ gcd;
              final aspectRatio = '$aspectW : $aspectH';

              // Check if already added
              if (!resolutions.any((r) => r.width == width && r.height == height)) {
                resolutions.add(DisplayResolution(
                  width: width,
                  height: height,
                  aspectRatio: aspectRatio,
                  mode: '${width}x${height}',
                ));
              }
            }
          }
        }

        // Sort by resolution (largest first)
        resolutions.sort((a, b) {
          final aArea = a.width * a.height;
          final bArea = b.width * b.height;
          return bArea.compareTo(aArea);
        });

        if (mounted) {
          setState(() {
            _availableResolutions = resolutions;
            // Update current resolution to match one from the list if available
            if (_currentResolution != null) {
              final matching = resolutions.firstWhere(
                (r) => r.width == _currentResolution!.width &&
                    r.height == _currentResolution!.height,
                orElse: () => _currentResolution!,
              );
              _currentResolution = matching;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Get resolutions error: $e');
    }
  }

  Future<void> _getNightLightStatus() async {
    try {
      // Try to get night light status from gsettings
      final result = await Process.run('gsettings', [
        'get',
        'org.gnome.settings-daemon.plugins.color',
        'night-light-enabled',
      ]);
      if (result.exitCode == 0) {
        final value = result.stdout.toString().trim();
        if (mounted) {
          setState(() => _nightLight = value == 'true');
        }
      }
    } catch (_) {
      // If gsettings fails, try D-Bus
      try {
        final color = DBusRemoteObject(
          _sysbus,
          name: 'org.gnome.SettingsDaemon.Color',
          path: DBusObjectPath('/org/gnome/SettingsDaemon/Color'),
        );
        final enabled = await color.getProperty(
          'org.gnome.SettingsDaemon.Color',
          'NightLightEnabled',
        );
        if (mounted) {
          setState(() => _nightLight = (enabled as DBusBoolean).value);
        }
      } catch (_) {}
    }
  }

  int _gcd(int a, int b) {
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a;
  }

  Future<void> _setOrientation(String orientation) async {
    try {
      final output = await Process.run('xrandr', ['--listmonitors']);
      if (output.exitCode == 0) {
        final lines = output.stdout.toString().split('\n');
        String? displayName;
        for (final line in lines) {
          if (line.contains('+') && line.contains('connected')) {
            final match = RegExp(r'(\S+)\s+connected').firstMatch(line);
            if (match != null) {
              displayName = match.group(1);
              break;
            }
          }
        }

        if (displayName == null) {
          // Try to get primary display
          final primaryResult = await Process.run('xrandr', ['--listmonitors']);
          if (primaryResult.exitCode == 0) {
            final primaryLines = primaryResult.stdout.toString().split('\n');
            for (final line in primaryLines) {
              if (line.contains('*')) {
                final match = RegExp(r'(\S+)').firstMatch(line);
                if (match != null) {
                  displayName = match.group(1);
                  break;
                }
              }
            }
          }
        }

        if (displayName == null) {
          // Fallback: try common display names
          final xrandrResult = await Process.run('xrandr', []);
          if (xrandrResult.exitCode == 0) {
            final xrandrLines = xrandrResult.stdout.toString().split('\n');
            for (final line in xrandrLines) {
              if (line.contains(' connected')) {
                final match = RegExp(r'^(\S+)\s+connected').firstMatch(line);
                if (match != null) {
                  displayName = match.group(1);
                  break;
                }
              }
            }
          }
        }

        if (displayName != null && _currentResolution != null) {
          String rotation = 'normal';
          if (orientation == 'Portrait') {
            rotation = 'left';
          }

          await Process.run('xrandr', [
            '--output',
            displayName,
            '--mode',
            _currentResolution!.mode,
            '--rotate',
            rotation,
          ]);

          setState(() => _orientation = orientation);
        }
      }
    } catch (e) {
      debugPrint('Set orientation error: $e');
    }
  }

  Future<void> _setResolution(DisplayResolution resolution) async {
    try {
      final output = await Process.run('xrandr', ['--listmonitors']);
      String? displayName;
      if (output.exitCode == 0) {
        final lines = output.stdout.toString().split('\n');
        for (final line in lines) {
          if (line.contains('+') && line.contains('connected')) {
            final match = RegExp(r'(\S+)\s+connected').firstMatch(line);
            if (match != null) {
              displayName = match.group(1);
              break;
            }
          }
        }
      }

      if (displayName == null) {
        final xrandrResult = await Process.run('xrandr', []);
        if (xrandrResult.exitCode == 0) {
          final xrandrLines = xrandrResult.stdout.toString().split('\n');
          for (final line in xrandrLines) {
            if (line.contains(' connected')) {
              final match = RegExp(r'^(\S+)\s+connected').firstMatch(line);
              if (match != null) {
                displayName = match.group(1);
                break;
              }
            }
          }
        }
      }

      if (displayName != null) {
        await Process.run('xrandr', [
          '--output',
          displayName,
          '--mode',
          resolution.mode,
        ]);

        setState(() => _currentResolution = resolution);
      }
    } catch (e) {
      debugPrint('Set resolution error: $e');
    }
  }

  Future<void> _setScale(int scale) async {
    try {
      final scaleFactor = scale / 100.0;
      await Process.run('gsettings', [
        'set',
        'org.gnome.desktop.interface',
        'text-scaling-factor',
        scaleFactor.toString(),
      ]);
      setState(() => _scale = scale);
    } catch (e) {
      debugPrint('Set scale error: $e');
    }
  }

  Future<void> _setFractionalScaling(bool enabled) async {
    try {
      await Process.run('gsettings', [
        'set',
        'org.gnome.mutter',
        'experimental-features',
        enabled ? "['scale-monitor-framebuffer']" : '[]',
      ]);
      setState(() => _fractionalScaling = enabled);
    } catch (e) {
      debugPrint('Set fractional scaling error: $e');
    }
  }

  Future<void> _setNightLight(bool enabled) async {
    try {
      await Process.run('gsettings', [
        'set',
        'org.gnome.settings-daemon.plugins.color',
        'night-light-enabled',
        enabled.toString(),
      ]);
      setState(() => _nightLight = enabled);
    } catch (e) {
      // Try D-Bus as fallback
      try {
        final color = DBusRemoteObject(
          _sysbus,
          name: 'org.gnome.SettingsDaemon.Color',
          path: DBusObjectPath('/org/gnome/SettingsDaemon/Color'),
        );
        await color.setProperty(
          'org.gnome.SettingsDaemon.Color',
          'NightLightEnabled',
          DBusBoolean(enabled),
        );
        setState(() => _nightLight = enabled);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(0, 0, 0, 0),
      body: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color.fromARGB(220, 28, 32, 44),
                Color.fromARGB(180, 18, 20, 30),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Display',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                // Orientation
                _buildDropdownSetting(
                  'Orientation',
                  _orientation,
                  ['Landscape', 'Portrait'],
                  (value) => _setOrientation(value),
                ),
                const SizedBox(height: 24),
                // Resolution
                _buildResolutionDropdown(),
                const SizedBox(height: 24),
                // Refresh Rate (read-only)
                _buildReadOnlySetting('Refresh Rate', _refreshRate),
                const SizedBox(height: 24),
                // Scale
                _buildScaleButtons(),
                const SizedBox(height: 24),
                // Fractional Scaling
                _buildToggleSetting(
                  'Fractional Scaling',
                  _fractionalScaling,
                  'May increase power usage, lower speed, or reduce display sharpness.',
                  (value) => _setFractionalScaling(value),
                ),
                const SizedBox(height: 24),
                // Night Light
                _buildNightLightSetting(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownSetting(
    String label,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: const Color.fromARGB(255, 45, 45, 45),
            style: const TextStyle(color: Colors.white),
            items: options.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(option),
                    const Icon(Icons.arrow_drop_down, color: Colors.white54),
                  ],
                ),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) onChanged(newValue);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResolutionDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resolution',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: DropdownButton<DisplayResolution>(
            value: _currentResolution,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: const Color.fromARGB(255, 45, 45, 45),
            style: const TextStyle(color: Colors.white),
            hint: const Text(
              'Select Resolution',
              style: TextStyle(color: Colors.white54),
            ),
            items: _availableResolutions.map((resolution) {
              return DropdownMenuItem<DisplayResolution>(
                value: resolution,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(resolution.toString()),
                    const Icon(Icons.arrow_drop_down, color: Colors.white54),
                  ],
                ),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) _setResolution(newValue);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlySetting(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScaleButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Scale',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildScaleButton('100 %', 100),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildScaleButton('200 %', 200),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScaleButton(String label, int scale) {
    final isSelected = _scale == scale;
    return InkWell(
      onTap: () => _setScale(scale),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.white.withOpacity(0.3)
                : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleSetting(
    String label,
    bool value,
    String? description,
    ValueChanged<bool> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.tealAccent,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNightLightSetting() {
    return InkWell(
      onTap: () => _setNightLight(!_nightLight),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Night Light',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            Row(
              children: [
                Text(
                  _nightLight ? 'On' : 'Off',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.white54,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

