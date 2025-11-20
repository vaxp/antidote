import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dbus/dbus.dart';
import 'package:antidote/glassmorphic_container.dart';

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
  bool _isInitialized = false;
  String? _cachedDisplayName; // Cache display name to avoid repeated lookups

  // Display states
  String _orientation = 'Landscape';
  DisplayResolution? _currentResolution;
  DisplayResolution? _nativeResolution; // True/native screen resolution
  List<DisplayResolution> _availableResolutions = [];
  String _refreshRate = '60.00 Hz';
  List<String> _availableRefreshRates = []; // Available refresh rates for current resolution
  int _scale = 100; // 100 or 200
  bool _fractionalScaling = false;
  bool _nightLight = false;
  String _displayServer = 'Unknown'; // 'X11' or 'Wayland'
  
  // Brightness states
  double _brightness = 100.0; // 0-100
  double _maxBrightness = 100.0;
  bool _brightnessSupported = false;
  String _brightnessMethod = 'none'; // 'brightnessctl', 'xrandr', 'wayland', 'dbus'

  @override
  void initState() {
    super.initState();
    _sysbus = DBusClient.system();
    _initDisplaySettings();
  }

  @override
  void dispose() {
    _sysbus.close();
    super.dispose();
  }

  Future<void> _initDisplaySettings() async {
    if (_isInitialized) return;
    
    await _detectDisplayServer();
    await _refreshDisplayInfo();
    await _initBrightness();
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _detectDisplayServer() async {
    try {
      // Check WAYLAND_DISPLAY environment variable
      final waylandDisplay = Platform.environment['WAYLAND_DISPLAY'];
      if (waylandDisplay != null && waylandDisplay.isNotEmpty) {
        if (mounted) {
          setState(() => _displayServer = 'Wayland');
        }
        return;
      }

      // Check XDG_SESSION_TYPE
      final sessionType = Platform.environment['XDG_SESSION_TYPE'];
      if (sessionType != null) {
        if (mounted) {
          setState(() => _displayServer = sessionType.toLowerCase() == 'wayland' ? 'Wayland' : 'X11');
        }
        return;
      }

      // Fallback: try to detect via xrandr (if it works, it's X11)
      try {
        final result = await Process.run('xrandr', ['--version']);
        if (result.exitCode == 0) {
          if (mounted) {
            setState(() => _displayServer = 'X11');
          }
        }
      } catch (_) {
        // If xrandr doesn't work, likely Wayland
        if (mounted) {
          setState(() => _displayServer = 'Wayland');
        }
      }
    } catch (e) {
      debugPrint('Detect display server error: $e');
      if (mounted) {
        setState(() => _displayServer = 'Unknown');
      }
    }
  }

  Future<void> _refreshDisplayInfo() async {
    if (!mounted) return;
    if (_isInitialized) return; // Only fetch once
    try {
      if (_displayServer == 'Wayland') {
        await _getWaylandDisplayInfo();
        await _getWaylandAvailableResolutions();
      } else {
        await _getX11DisplayInfo();
      }
      await _getNightLightStatus();
    } catch (e) {
      debugPrint('Display refresh error: $e');
    }
  }

  Future<String?> _getDisplayName() async {
    // Return cached display name if available
    if (_cachedDisplayName != null) {
      return _cachedDisplayName;
    }
    
    try {
      if (_displayServer == 'X11') {
        final output = await Process.run('xrandr', ['--listmonitors']);
        if (output.exitCode == 0) {
          final lines = output.stdout.toString().split('\n');
          for (final line in lines) {
            if (line.contains('+') && line.contains('connected')) {
              final match = RegExp(r'(\S+)\s+connected').firstMatch(line);
              if (match != null) {
                _cachedDisplayName = match.group(1);
                return _cachedDisplayName;
              }
            }
          }
        }
        
        // Fallback: try xrandr without --listmonitors
        final xrandrResult = await Process.run('xrandr', []);
        if (xrandrResult.exitCode == 0) {
          final xrandrLines = xrandrResult.stdout.toString().split('\n');
          for (final line in xrandrLines) {
            if (line.contains(' connected')) {
              final match = RegExp(r'^(\S+)\s+connected').firstMatch(line);
              if (match != null) {
                _cachedDisplayName = match.group(1);
                return _cachedDisplayName;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Get display name error: $e');
    }
    
    return null;
  }
  
  Future<void> _initBrightness() async {
    try {
      // xrandr --brightness is the PRIMARY method (works for all displays without permissions)
      // It uses software gamma adjustment, so it works on X11 and can work on Wayland if xrandr is available
      // This should be tried first since it doesn't require special permissions
      try {
        // Check if xrandr is available
        final xrandrCheck = await Process.run('xrandr', ['--version']);
        if (xrandrCheck.exitCode == 0) {
          final displayName = await _getDisplayName();
          if (displayName != null) {
            // xrandr brightness is 0.0-1.0, we'll use it as percentage
            // This works for laptops, external monitors, and TVs without special permissions
            if (mounted) {
              setState(() {
                _brightness = 100.0; // Default to 100%
                _maxBrightness = 100.0;
                _brightnessSupported = true;
                _brightnessMethod = 'xrandr';
              });
            }
            return;
          } else {
            debugPrint('xrandr available but no display name found');
          }
        }
      } catch (e) {
        debugPrint('xrandr brightness failed: $e');
      }
      
      // Try gsettings for Wayland/GNOME (works without permissions)
      try {
        final brightnessResult = await Process.run('gsettings', [
          'get',
          'org.gnome.settings-daemon.plugins.power',
          'brightness',
        ]);
        if (brightnessResult.exitCode == 0) {
          final brightnessStr = brightnessResult.stdout.toString().trim();
          final brightness = int.tryParse(brightnessStr) ?? 100;
          if (mounted) {
            setState(() {
              _brightness = brightness.toDouble();
              _maxBrightness = 100.0;
              _brightnessSupported = true;
              _brightnessMethod = 'wayland';
            });
          }
          return;
        }
      } catch (e) {
        debugPrint('gsettings brightness failed: $e');
      }
      
      // Try D-Bus for GNOME Settings Daemon (works for all displays without permissions)
      try {
        final power = DBusRemoteObject(
          _sysbus,
          name: 'org.gnome.SettingsDaemon.Power',
          path: DBusObjectPath('/org/gnome/SettingsDaemon/Power'),
        );
        
        // Try to get brightness from ScreenBrightness interface
        try {
          final brightness = await power.getProperty(
            'org.gnome.SettingsDaemon.Power.Screen',
            'Brightness',
          );
          if (brightness is DBusUint32) {
            if (mounted) {
              setState(() {
                _brightness = brightness.value.toDouble();
                _maxBrightness = 100.0;
                _brightnessSupported = true;
                _brightnessMethod = 'dbus';
              });
            }
            return;
          }
        } catch (e) {
          debugPrint('D-Bus Screen brightness failed: $e');
          // Try alternative D-Bus path
          try {
            final brightness = await power.getProperty(
              'org.freedesktop.UPower',
              'Brightness',
            );
            if (brightness is DBusUint32 || brightness is DBusDouble) {
              final value = brightness is DBusUint32 
                  ? brightness.value.toDouble() 
                  : (brightness as DBusDouble).value;
              if (mounted) {
                setState(() {
                  _brightness = value;
                  _maxBrightness = 100.0;
                  _brightnessSupported = true;
                  _brightnessMethod = 'dbus';
                });
              }
              return;
            }
          } catch (e2) {
            debugPrint('D-Bus UPower brightness failed: $e2');
          }
        }
      } catch (e) {
        debugPrint('D-Bus power object failed: $e');
      }
      
      // Try brightnessctl last (only if it works without special permissions)
      // Skip if it requires root or special permissions
      try {
        final maxResult = await Process.run('brightnessctl', ['m']);
        final currentResult = await Process.run('brightnessctl', ['g']);
        if (maxResult.exitCode == 0 && currentResult.exitCode == 0) {
          final currentValue = currentResult.stdout.toString().trim();
          // Test if we can actually set brightness (check permissions)
          // Try to set to current value (should succeed if permissions are OK)
          final testResult = await Process.run('brightnessctl', ['s', currentValue]);
          if (testResult.exitCode == 0) {
            // Permissions are OK, use brightnessctl
            final max = double.tryParse(maxResult.stdout.toString().trim()) ?? 100.0;
            final current = double.tryParse(currentValue) ?? 100.0;
            if (max > 0) {
              if (mounted) {
                setState(() {
                  _maxBrightness = max;
                  _brightness = (current / max * 100).clamp(0.0, 100.0);
                  _brightnessSupported = true;
                  _brightnessMethod = 'brightnessctl';
                });
              }
              return;
            }
          } else {
            // Check if it's a permission error
            final errorOutput = testResult.stderr.toString();
            if (errorOutput.contains('Permission') || errorOutput.contains('root')) {
              debugPrint('brightnessctl requires permissions, skipping');
            }
          }
        }
      } catch (e) {
        debugPrint('brightnessctl failed: $e');
      }
      
      // No brightness control available
      debugPrint('No brightness control method available');
      if (mounted) {
        setState(() {
          _brightnessSupported = false;
        });
      }
    } catch (e) {
      debugPrint('Init brightness error: $e');
      if (mounted) {
        setState(() {
          _brightnessSupported = false;
        });
      }
    }
  }
  
  Future<void> _setBrightness(double value) async {
    if (!_brightnessSupported) {
      debugPrint('Brightness not supported, cannot set to $value');
      return;
    }
    
    try {
      if (_brightnessMethod == 'brightnessctl') {
        // brightnessctl uses absolute values, not percentages
        final absoluteValue = (value / 100.0 * _maxBrightness).round();
        final result = await Process.run('brightnessctl', ['s', absoluteValue.toString()]);
        if (result.exitCode != 0) {
          debugPrint('brightnessctl set failed: ${result.stderr}');
        }
      } else if (_brightnessMethod == 'wayland') {
        // Use gsettings for GNOME Wayland
        final result = await Process.run('gsettings', [
          'set',
          'org.gnome.settings-daemon.plugins.power',
          'brightness',
          value.round().toString(),
        ]);
        if (result.exitCode != 0) {
          debugPrint('gsettings brightness set failed: ${result.stderr}');
        }
      } else if (_brightnessMethod == 'dbus') {
        // Use D-Bus to set brightness via GNOME Settings Daemon
        try {
          final power = DBusRemoteObject(
            _sysbus,
            name: 'org.gnome.SettingsDaemon.Power',
            path: DBusObjectPath('/org/gnome/SettingsDaemon/Power'),
          );
          
          try {
            await power.setProperty(
              'org.gnome.SettingsDaemon.Power.Screen',
              'Brightness',
              DBusUint32(value.round().clamp(0, 100)),
            );
          } catch (e) {
            debugPrint('D-Bus setProperty failed: $e');
            // Try alternative method
            try {
              await power.callMethod(
                'org.gnome.SettingsDaemon.Power.Screen',
                'SetBrightness',
                [DBusUint32(value.round().clamp(0, 100))],
                replySignature: DBusSignature(''),
              );
            } catch (e2) {
              debugPrint('D-Bus callMethod failed: $e2');
              // Fallback to gsettings
              await Process.run('gsettings', [
                'set',
                'org.gnome.settings-daemon.plugins.power',
                'brightness',
                value.round().toString(),
              ]);
            }
          }
        } catch (e) {
          debugPrint('D-Bus brightness set error: $e');
          // Fallback to gsettings
          await Process.run('gsettings', [
            'set',
            'org.gnome.settings-daemon.plugins.power',
            'brightness',
            value.round().toString(),
          ]);
        }
      } else if (_brightnessMethod == 'xrandr') {
        // xrandr brightness works for all displays (laptops, external monitors, TVs)
        // Uses software gamma adjustment (0.0-1.0)
        final displayName = await _getDisplayName();
        if (displayName != null) {
          final brightnessValue = (value / 100.0).clamp(0.0, 1.0);
          final result = await Process.run('xrandr', [
            '--output',
            displayName,
            '--brightness',
            brightnessValue.toStringAsFixed(2),
          ]);
          if (result.exitCode != 0) {
            debugPrint('xrandr brightness set failed: ${result.stderr}');
          }
        } else {
          debugPrint('xrandr brightness: display name is null');
        }
      }
      
      if (mounted) {
        setState(() {
          _brightness = value;
        });
      }
    } catch (e) {
      debugPrint('Set brightness error: $e');
    }
  }

  Future<void> _getX11DisplayInfo() async {
    try {
      // Get native resolution first (from EDID or modeline)
      await _getX11NativeResolution();
      
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
              final refresh = modeMatch.group(3) ?? '60.00';

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
      
      // Get available resolutions and refresh rates
      await _getX11AvailableResolutions();
      await _getX11AvailableRefreshRates();
    } catch (e) {
      debugPrint('Get X11 display info error: $e');
    }
  }

  Future<void> _getX11NativeResolution() async {
    try {
      // Try to get native resolution from xrandr --verbose (shows preferred mode)
      final result = await Process.run('xrandr', ['--verbose']);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final lines = output.split('\n');
        
        String? currentDisplay;
        for (final line in lines) {
          // Find connected display
          if (line.contains(' connected')) {
            final match = RegExp(r'^(\S+)\s+connected').firstMatch(line);
            if (match != null) {
              currentDisplay = match.group(1);
            }
          }
          
          // Look for preferred mode or highest resolution
          if (currentDisplay != null && line.contains('$currentDisplay connected')) {
            // Extract native resolution from EDID info or preferred mode
            final preferredMatch = RegExp(r'(\d+)x(\d+)\s+.*preferred').firstMatch(line);
            if (preferredMatch != null) {
              final width = int.tryParse(preferredMatch.group(1) ?? '') ?? 0;
              final height = int.tryParse(preferredMatch.group(2) ?? '') ?? 0;
              if (width > 0 && height > 0) {
                final gcd = _gcd(width, height);
                final aspectW = width ~/ gcd;
                final aspectH = height ~/ gcd;
                final aspectRatio = '$aspectW : $aspectH';
                
                if (mounted) {
                  setState(() {
                    _nativeResolution = DisplayResolution(
                      width: width,
                      height: height,
                      aspectRatio: aspectRatio,
                      mode: '${width}x${height}',
                    );
                  });
                }
                return;
              }
            }
          }
        }
        
        // Fallback: use the highest available resolution as native
        final xrandrResult = await Process.run('xrandr', []);
        if (xrandrResult.exitCode == 0) {
          final xrandrOutput = xrandrResult.stdout.toString();
          final xrandrLines = xrandrOutput.split('\n');
          int maxWidth = 0;
          int maxHeight = 0;
          
          for (final line in xrandrLines) {
            final match = RegExp(r'\s+(\d+)x(\d+)\s+').firstMatch(line);
            if (match != null) {
              final width = int.tryParse(match.group(1) ?? '') ?? 0;
              final height = int.tryParse(match.group(2) ?? '') ?? 0;
              if (width * height > maxWidth * maxHeight) {
                maxWidth = width;
                maxHeight = height;
              }
            }
          }
          
          if (maxWidth > 0 && maxHeight > 0) {
            final gcd = _gcd(maxWidth, maxHeight);
            final aspectW = maxWidth ~/ gcd;
            final aspectH = maxHeight ~/ gcd;
            final aspectRatio = '$aspectW : $aspectH';
            
            if (mounted) {
              setState(() {
                _nativeResolution = DisplayResolution(
                  width: maxWidth,
                  height: maxHeight,
                  aspectRatio: aspectRatio,
                  mode: '${maxWidth}x${maxHeight}',
          );
        });
      }
          }
        }
      }
    } catch (e) {
      debugPrint('Get X11 native resolution error: $e');
    }
  }

  Future<void> _getWaylandDisplayInfo() async {
    try {
      // Try wlr-randr first (for wlroots-based compositors)
      try {
        final result = await Process.run('wlr-randr', []);
        if (result.exitCode == 0) {
          await _parseWlrRandrOutput(result.stdout.toString());
          return;
        }
      } catch (_) {}

      // Try gsettings for GNOME on Wayland
      try {
        await _getWaylandInfoFromGsettings();
      } catch (_) {}

      // Try DBus for Wayland
      try {
        await _getWaylandInfoFromDBus();
      } catch (_) {}
    } catch (e) {
      debugPrint('Get Wayland display info error: $e');
    }
  }

  Future<void> _parseWlrRandrOutput(String output) async {
    try {
      final lines = output.split('\n');
      String? currentOutput;
      int? nativeWidth, nativeHeight;
      int? currentWidth, currentHeight;
      String? refreshRate;
      final Set<double> refreshRates = {};

      for (final line in lines) {
        // Find output name
        if (line.trim().isNotEmpty && !line.startsWith(' ')) {
          currentOutput = line.trim().split(' ').first;
          continue;
        }

        if (currentOutput != null) {
          // Parse resolution
          final resMatch = RegExp(r'(\d+)x(\d+)\s+px').firstMatch(line);
          if (resMatch != null) {
            final width = int.tryParse(resMatch.group(1) ?? '') ?? 0;
            final height = int.tryParse(resMatch.group(2) ?? '') ?? 0;
            if (width > 0 && height > 0) {
              if (line.contains('current')) {
                currentWidth = width;
                currentHeight = height;
              } else if (line.contains('preferred') || nativeWidth == null) {
                nativeWidth = width;
                nativeHeight = height;
              }
            }
          }

          // Parse refresh rate (current)
          final refreshMatch = RegExp(r'(\d+\.?\d*)\s*Hz').firstMatch(line);
          if (refreshMatch != null) {
            final rate = double.tryParse(refreshMatch.group(1) ?? '');
            if (rate != null) {
              refreshRate = refreshMatch.group(1);
              if (rate >= 30.0 && rate <= 360.0) {
                refreshRates.add(rate);
              }
            }
          }
        }
      }

      if (nativeWidth != null && nativeHeight != null) {
        final nw = nativeWidth;
        final nh = nativeHeight;
        final gcd = _gcd(nw, nh);
        final aspectW = nw ~/ gcd;
        final aspectH = nh ~/ gcd;
        final aspectRatio = '$aspectW : $aspectH';

        // Get all available refresh rates from wlr-randr modes
        await _getWaylandAvailableRefreshRates();

        if (mounted) {
          setState(() {
            _nativeResolution = DisplayResolution(
              width: nw,
              height: nh,
              aspectRatio: aspectRatio,
              mode: '${nw}x${nh}',
            );
            
            if (currentWidth != null && currentHeight != null) {
              final cw = currentWidth;
              final ch = currentHeight;
              _currentResolution = DisplayResolution(
                width: cw,
                height: ch,
                aspectRatio: aspectRatio,
                mode: '${cw}x${ch}',
              );
            } else {
              _currentResolution = _nativeResolution;
            }
            
            if (refreshRate != null) {
              _refreshRate = '$refreshRate Hz';
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Parse wlr-randr output error: $e');
    }
  }

  Future<void> _getWaylandInfoFromGsettings() async {
    try {
      // Try to get resolution from gsettings or mutter
      final scaleResult = await Process.run('gsettings', [
        'get',
        'org.gnome.desktop.interface',
        'text-scaling-factor',
      ]);
      if (scaleResult.exitCode == 0) {
        final scaleStr = scaleResult.stdout.toString().trim();
        final scaleValue = double.tryParse(scaleStr) ?? 1.0;
        if (mounted) {
          setState(() => _scale = (scaleValue * 100).round());
        }
      }
    } catch (e) {
      debugPrint('Get Wayland info from gsettings error: $e');
    }
  }

  Future<void> _getWaylandInfoFromDBus() async {
    try {
      // Try to get display info from Mutter/GNOME via DBus
      final mutter = DBusRemoteObject(
        _sysbus,
        name: 'org.gnome.Mutter.DisplayConfig',
        path: DBusObjectPath('/org/gnome/Mutter/DisplayConfig'),
      );
      
      // Get current state
      // Note: Parsing Mutter DisplayConfig state is complex
      // We'll rely on wlr-randr or gsettings instead
      await mutter.callMethod(
        'org.gnome.Mutter.DisplayConfig',
        'GetCurrentState',
        [],
        replySignature: DBusSignature('uua(uxiiiiiu)a(uxiiiiiu)'),
      );
      
      // Parse the state to get resolutions
      // This is complex, so we'll use a simpler approach
    } catch (e) {
      debugPrint('Get Wayland info from DBus error: $e');
    }
  }

  Future<void> _getX11AvailableResolutions() async {
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
            
            // If native resolution not set, use the highest as native
            if (_nativeResolution == null && resolutions.isNotEmpty) {
              _nativeResolution = resolutions.first;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Get X11 resolutions error: $e');
    }
  }

  Future<void> _getX11AvailableRefreshRates() async {
    try {
      if (_currentResolution == null) return;
      
      final result = await Process.run('xrandr', []);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final lines = output.split('\n');
        final Set<double> refreshRates = {};
        final String targetMode = '${_currentResolution!.width}x${_currentResolution!.height}';
        bool foundTargetMode = false;

        for (final line in lines) {
          // Look for the line containing our target resolution
          if (line.contains(targetMode)) {
            foundTargetMode = true;
            // Extract all refresh rates from this line
            // Format: "   1920x1080     60.00*+  59.94    50.00    30.00    25.00    24.00"
            // First try with Hz suffix
            final refreshMatches = RegExp(r'(\d+\.?\d*)\s*Hz').allMatches(line);
            for (final match in refreshMatches) {
              final rate = double.tryParse(match.group(1) ?? '');
              if (rate != null && rate >= 30.0 && rate <= 360.0) {
                refreshRates.add(rate);
              }
            }
            
            // Also extract all numbers that could be refresh rates (after the resolution)
            // Pattern: resolution followed by whitespace, then numbers (refresh rates)
            final parts = line.split(RegExp(r'\s+'));
            for (int i = 0; i < parts.length; i++) {
              final part = parts[i];
              // Skip the resolution part (e.g., "1920x1080")
              if (part.contains('x')) continue;
              
              // Try to parse as refresh rate
              // Remove markers like *, +, current, preferred
              final cleanPart = part.replaceAll(RegExp(r'[*+\-]'), '');
              final rate = double.tryParse(cleanPart);
              if (rate != null && rate >= 30.0 && rate <= 360.0) {
                refreshRates.add(rate);
              }
            }
          } else if (foundTargetMode && line.trim().isNotEmpty && !line.startsWith(' ')) {
            // We've moved to a different mode, stop parsing
            break;
          }
        }

        // If no refresh rates found, try parsing from xrandr --verbose
        if (refreshRates.isEmpty) {
          final verboseResult = await Process.run('xrandr', ['--verbose']);
          if (verboseResult.exitCode == 0) {
            final verboseOutput = verboseResult.stdout.toString();
            final verboseLines = verboseOutput.split('\n');
            bool inTargetMode = false;
            
            for (final line in verboseLines) {
              if (line.contains(targetMode) && line.contains('connected')) {
                inTargetMode = true;
                continue;
              }
              
              if (inTargetMode) {
                // Look for refresh rate in modeline or mode details
                final refreshMatch = RegExp(r'(\d+\.?\d*)\s*Hz').firstMatch(line);
                if (refreshMatch != null) {
                  final rate = double.tryParse(refreshMatch.group(1) ?? '');
                  if (rate != null && rate >= 30.0 && rate <= 360.0) {
                    refreshRates.add(rate);
                  }
                }
                
                // Stop if we hit another mode or output
                if (line.trim().isNotEmpty && !line.startsWith(' ') && !line.startsWith('\t')) {
                  break;
                }
              }
            }
          }
        }

        // If still no refresh rates found, generate common ones
        if (refreshRates.isEmpty) {
          // Generate common refresh rates from 30Hz to 240Hz
          for (double rate = 30.0; rate <= 240.0; rate += 1.0) {
            if (rate == 30.0 || rate == 50.0 || rate == 59.94 || rate == 60.0 || 
                rate == 75.0 || rate == 100.0 || rate == 120.0 || rate == 144.0 || 
                rate == 165.0 || rate == 240.0) {
              refreshRates.add(rate);
            }
          }
        }

        // Sort refresh rates (highest first)
        final sortedRates = refreshRates.toList()..sort((a, b) => b.compareTo(a));
        
        // Format as strings with 2 decimal places
        final formattedRates = sortedRates.map((rate) {
          // Format to remove unnecessary decimals (e.g., 60.00 -> 60, 59.94 -> 59.94)
          if (rate == rate.roundToDouble()) {
            return '${rate.round()} Hz';
          } else {
            return '${rate.toStringAsFixed(2)} Hz';
          }
        }).toList();

        if (mounted) {
          setState(() {
            _availableRefreshRates = formattedRates;
            // Update current refresh rate if it's not in the list
            if (!formattedRates.contains(_refreshRate) && formattedRates.isNotEmpty) {
              _refreshRate = formattedRates.first;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Get X11 refresh rates error: $e');
    }
  }

  Future<void> _getWaylandAvailableResolutions() async {
    try {
      // Try wlr-randr for wlroots-based compositors
      try {
        final result = await Process.run('wlr-randr', []);
        if (result.exitCode == 0) {
          await _parseWlrRandrModes(result.stdout.toString());
          await _getWaylandAvailableRefreshRates();
          return;
        }
      } catch (_) {}

      // For GNOME Wayland, resolutions are managed by Mutter
      // We can't easily get all available modes, so we'll show common ones
      if (_nativeResolution != null) {
        _generateCommonResolutions(_nativeResolution!);
        await _getWaylandAvailableRefreshRates();
      }
    } catch (e) {
      debugPrint('Get Wayland resolutions error: $e');
    }
  }

  Future<void> _getWaylandAvailableRefreshRates() async {
    try {
      final Set<double> refreshRates = {};
      
      // Try wlr-randr for wlroots-based compositors
      try {
        final result = await Process.run('wlr-randr', []);
        if (result.exitCode == 0) {
          final output = result.stdout.toString();
          final lines = output.split('\n');
          
          for (final line in lines) {
            // Parse mode lines like "  1920x1080 px, 60.000000 Hz (preferred)"
            final refreshMatch = RegExp(r'(\d+\.?\d*)\s*Hz').firstMatch(line);
            if (refreshMatch != null) {
              final rate = double.tryParse(refreshMatch.group(1) ?? '');
              if (rate != null && rate >= 30.0 && rate <= 360.0) {
                refreshRates.add(rate);
              }
            }
          }
        }
      } catch (_) {}

      // If no refresh rates found, generate common ones
      if (refreshRates.isEmpty) {
        // Generate common refresh rates from 30Hz to 240Hz
        for (double rate = 30.0; rate <= 240.0; rate += 1.0) {
          if (rate == 30.0 || rate == 50.0 || rate == 59.94 || rate == 60.0 || 
              rate == 75.0 || rate == 100.0 || rate == 120.0 || rate == 144.0 || 
              rate == 165.0 || rate == 240.0) {
            refreshRates.add(rate);
          }
        }
      }

      // Sort refresh rates (highest first)
      final sortedRates = refreshRates.toList()..sort((a, b) => b.compareTo(a));
      
      // Format as strings
      final formattedRates = sortedRates.map((rate) {
        if (rate == rate.roundToDouble()) {
          return '${rate.round()} Hz';
        } else {
          return '${rate.toStringAsFixed(2)} Hz';
        }
      }).toList();

      if (mounted) {
        setState(() {
          _availableRefreshRates = formattedRates;
          // Update current refresh rate if it's not in the list
          if (!formattedRates.contains(_refreshRate) && formattedRates.isNotEmpty) {
            _refreshRate = formattedRates.first;
          }
        });
      }
    } catch (e) {
      debugPrint('Get Wayland refresh rates error: $e');
    }
  }

  Future<void> _parseWlrRandrModes(String output) async {
    try {
      final lines = output.split('\n');
      final List<DisplayResolution> resolutions = [];
      String? currentOutput;

      for (final line in lines) {
        if (line.trim().isNotEmpty && !line.startsWith(' ')) {
          currentOutput = line.trim().split(' ').first;
          continue;
        }

        if (currentOutput != null) {
          // Parse mode lines like "  1920x1080 px, 60.000000 Hz (preferred)"
          final modeMatch = RegExp(r'(\d+)x(\d+)\s+px').firstMatch(line);
          if (modeMatch != null) {
            final width = int.tryParse(modeMatch.group(1) ?? '') ?? 0;
            final height = int.tryParse(modeMatch.group(2) ?? '') ?? 0;

            if (width > 0 && height > 0) {
              final gcd = _gcd(width, height);
              final aspectW = width ~/ gcd;
              final aspectH = height ~/ gcd;
              final aspectRatio = '$aspectW : $aspectH';

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
        });
      }
    } catch (e) {
      debugPrint('Parse wlr-randr modes error: $e');
    }
  }

  void _generateCommonResolutions(DisplayResolution native) {
    // Generate common resolutions based on native resolution
    final List<DisplayResolution> resolutions = [native];
    
    // Add common fractional resolutions
    final commonRatios = [0.75, 0.5, 0.25];
    for (final ratio in commonRatios) {
      final width = (native.width * ratio).round();
      final height = (native.height * ratio).round();
      if (width > 640 && height > 480) {
        final gcd = _gcd(width, height);
        final aspectW = width ~/ gcd;
        final aspectH = height ~/ gcd;
        resolutions.add(DisplayResolution(
          width: width,
          height: height,
          aspectRatio: '$aspectW : $aspectH',
          mode: '${width}x${height}',
        ));
      }
    }
    
    // Add standard resolutions that are smaller than native
    final standardResolutions = [
      [3840, 2160], [2560, 1440], [1920, 1080], [1680, 1050],
      [1600, 900], [1440, 900], [1366, 768], [1280, 720], [1024, 768]
    ];
    
    for (final res in standardResolutions) {
      if (res[0] <= native.width && res[1] <= native.height) {
        final gcd = _gcd(res[0], res[1]);
        final aspectW = res[0] ~/ gcd;
        final aspectH = res[1] ~/ gcd;
        if (!resolutions.any((r) => r.width == res[0] && r.height == res[1])) {
          resolutions.add(DisplayResolution(
            width: res[0],
            height: res[1],
            aspectRatio: '$aspectW : $aspectH',
            mode: '${res[0]}x${res[1]}',
          ));
        }
      }
    }
    
    resolutions.sort((a, b) {
      final aArea = a.width * a.height;
      final bArea = b.width * b.height;
      return bArea.compareTo(aArea);
    });
    
    if (mounted) {
      setState(() {
        _availableResolutions = resolutions;
      });
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
    // Only set if orientation actually changed
    if (_orientation == orientation) {
      return;
    }
    
    try {
      if (_displayServer == 'X11') {
        final displayName = await _getDisplayName();
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

          if (mounted) {
          setState(() => _orientation = orientation);
          }
        }
      }
    } catch (e) {
      debugPrint('Set orientation error: $e');
    }
  }

  Future<void> _setResolution(DisplayResolution resolution) async {
    // Only set if resolution actually changed
    if (_currentResolution?.width == resolution.width && 
        _currentResolution?.height == resolution.height) {
      return;
    }
    
    try {
      if (_displayServer == 'X11') {
        final displayName = await _getDisplayName();
      if (displayName != null) {
        await Process.run('xrandr', [
          '--output',
          displayName,
          '--mode',
          resolution.mode,
        ]);

          if (mounted) {
        setState(() => _currentResolution = resolution);
          }
          
          // Refresh available refresh rates for the new resolution
          await _getX11AvailableRefreshRates();
        }
      } else if (_displayServer == 'Wayland') {
        // For Wayland, try wlr-randr or other methods
        try {
          await Process.run('wlr-randr', [
            '--output',
            'eDP-1', // Common laptop display name, may need detection
            '--mode',
            resolution.mode,
          ]);
          if (mounted) {
            setState(() => _currentResolution = resolution);
          }
          
          // Refresh available refresh rates for the new resolution
          await _getWaylandAvailableRefreshRates();
        } catch (_) {
          // Wayland resolution changes are typically managed by compositor
          debugPrint('Wayland resolution change not supported via command line');
        }
      }
    } catch (e) {
      debugPrint('Set resolution error: $e');
    }
  }

  Future<void> _setRefreshRate(String refreshRate) async {
    // Only set if refresh rate actually changed
    if (_refreshRate == refreshRate) {
      return;
    }
    
    try {
      if (_displayServer == 'X11') {
        final displayName = await _getDisplayName();
        if (displayName != null && _currentResolution != null) {
          // Extract numeric value from refresh rate string (e.g., "60.00 Hz" -> 60.00)
          final rateMatch = RegExp(r'(\d+\.?\d*)').firstMatch(refreshRate);
          if (rateMatch != null) {
            final rate = rateMatch.group(1);
            await Process.run('xrandr', [
              '--output',
              displayName,
              '--mode',
              _currentResolution!.mode,
              '--rate',
              rate ?? '60',
            ]);

            if (mounted) {
              setState(() => _refreshRate = refreshRate);
            }
          }
        }
      } else if (_displayServer == 'Wayland') {
        // For Wayland, try wlr-randr
        try {
          final rateMatch = RegExp(r'(\d+\.?\d*)').firstMatch(refreshRate);
          if (rateMatch != null) {
            final rate = rateMatch.group(1);
            await Process.run('wlr-randr', [
              '--output',
              'eDP-1', // Common laptop display name, may need detection
              '--mode',
              _currentResolution?.mode ?? '1920x1080',
              '--refresh',
              rate ?? '60',
            ]);
            if (mounted) {
              setState(() => _refreshRate = refreshRate);
            }
          }
        } catch (_) {
          debugPrint('Wayland refresh rate change not supported via command line');
        }
      }
    } catch (e) {
      debugPrint('Set refresh rate error: $e');
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
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Display',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your display settings',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 48),
            
            // Grid of settings - 2 columns
            LayoutBuilder(
              builder: (context, constraints) {
                bool isTwoColumn = constraints.maxWidth > 1200;
                return Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  children: [
                    // Resolution
                    SizedBox(
                      width: isTwoColumn ? (constraints.maxWidth - 24) / 2 : double.infinity,
                      child: _buildResolutionCard(),
                    ),
                    // Refresh Rate
                    SizedBox(
                      width: isTwoColumn ? (constraints.maxWidth - 24) / 2 : double.infinity,
                      child: _buildRefreshRateCard(),
                    ),
                    // Brightness
                    if (_brightnessSupported)
                      SizedBox(
                        width: isTwoColumn ? (constraints.maxWidth - 24) / 2 : double.infinity,
                        child: _buildBrightnessCard(),
                      ),
                    // Orientation
                    SizedBox(
                      width: isTwoColumn ? (constraints.maxWidth - 24) / 2 : double.infinity,
                      child: _buildOrientationCard(),
                    ),
                    // Scale
                    SizedBox(
                      width: isTwoColumn ? (constraints.maxWidth - 24) / 2 : double.infinity,
                      child: _buildScaleCard(),
                    ),
                    // Night Light
                    SizedBox(
                      width: isTwoColumn ? (constraints.maxWidth - 24) / 2 : double.infinity,
                      child: _buildNightLightCard(),
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Additional options
            _buildFractionalScalingSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildResolutionCard() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 150,
      borderRadius: 20,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color.fromARGB(30, 17, 17, 17).withOpacity(0.12),
          const Color.fromARGB(30, 17, 17, 17).withOpacity(0.08),
        ],
      ),
      border: 1.2,
      blur: 40,
      borderGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resolution',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_displayServer != 'Unknown')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _displayServer == 'Wayland'
                            ? Colors.blue.withOpacity(0.2)
                            : Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _displayServer == 'Wayland'
                              ? Colors.blue.withOpacity(0.5)
                              : Colors.green.withOpacity(0.5),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        _displayServer,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _displayServer == 'Wayland'
                              ? Colors.blueAccent
                              : Colors.greenAccent,
                        ),
                      ),
                    ),
                ],
              ),
              if (_nativeResolution != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Native',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    Text(
                      _nativeResolution!.mode,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_currentResolution != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentResolution!.width}x${_currentResolution!.height} (${_currentResolution!.aspectRatio})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          const SizedBox(height: 12),
          if (_availableResolutions.isNotEmpty)
            Expanded(
              child: DropdownButton<DisplayResolution>(
                value: _currentResolution,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: const Color.fromARGB(255, 12, 12, 12),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                hint: const Text(
                  'Select Resolution',
                  style: TextStyle(color: Colors.white54),
                ),
                items: _availableResolutions.map((resolution) {
                  return DropdownMenuItem<DisplayResolution>(
                    value: resolution,
                    child: Text(resolution.toString()),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) _setResolution(newValue);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRefreshRateCard() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 150,
      borderRadius: 20,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color.fromARGB(30, 17, 17, 17).withOpacity(0.12),
          const Color.fromARGB(30, 17, 17, 17).withOpacity(0.08),
        ],
      ),
      border: 1.2,
      blur: 40,
      borderGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Refresh Rate',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _refreshRate,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_availableRefreshRates.isNotEmpty)
            Expanded(
              child: DropdownButton<String>(
                value: _refreshRate,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: const Color.fromARGB(255, 12, 12, 12),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: _availableRefreshRates.map((rate) {
                  return DropdownMenuItem<String>(
                    value: rate,
                    child: Text(rate),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) _setRefreshRate(newValue);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBrightnessCard() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 150,
      borderRadius: 20,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color.fromARGB(30, 17, 17, 17).withOpacity(0.12),
          const Color.fromARGB(30, 17, 17, 17).withOpacity(0.08),
        ],
      ),
      border: 1.2,
      blur: 40,
      borderGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Brightness',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${_brightness.round()}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.brightness_low,
                  color: Colors.white.withOpacity(0.6),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: _brightness,
                    min: 0.0,
                    max: 100.0,
                    divisions: 100,
                    activeColor: const Color.fromARGB(255, 100, 200, 255),
                    inactiveColor: Colors.white.withOpacity(0.15),
                    thumbColor: const Color.fromARGB(255, 100, 200, 255),
                    onChanged: (value) {
                      setState(() {
                        _brightness = value;
                      });
                      _setBrightness(value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.brightness_high,
                  color: Colors.white.withOpacity(0.6),
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrientationCard() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 150,
      borderRadius: 20,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color.fromARGB(30, 17, 17, 17).withOpacity(0.12),
          const Color.fromARGB(30, 17, 17, 17).withOpacity(0.08),
        ],
      ),
      border: 1.2,
      blur: 40,
      borderGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Orientation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _orientation,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: DropdownButton<String>(
              value: _orientation,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: const Color.fromARGB(255, 12, 12, 12),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              items: ['Landscape', 'Portrait'].map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) _setOrientation(newValue);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScaleCard() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 150,
      borderRadius: 20,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color.fromARGB(30, 17, 17, 17).withOpacity(0.12),
          const Color.fromARGB(30, 17, 17, 17).withOpacity(0.08),
        ],
      ),
      border: 1.2,
      blur: 40,
      borderGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scale',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildScaleButton('100%', 100),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildScaleButton('200%', 200),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNightLightCard() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 150,
      borderRadius: 20,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color.fromARGB(30, 17, 17, 17).withOpacity(0.12),
          const Color.fromARGB(30, 17, 17, 17).withOpacity(0.08),
        ],
      ),
      border: 1.2,
      blur: 40,
      borderGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Night Light',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Switch(
                value: _nightLight,
                onChanged: (value) => _setNightLight(value),
                activeColor: Colors.orangeAccent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                _nightLight ? 'Reduces blue light' : 'Off',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFractionalScalingSection() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 100,
      borderRadius: 20,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color.fromARGB(30, 17, 17, 17).withOpacity(0.12),
          const Color.fromARGB(30, 17, 17, 17).withOpacity(0.08),
        ],
      ),
      border: 1.2,
      blur: 40,
      borderGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Fractional Scaling',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'May impact performance',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _fractionalScaling,
            onChanged: (value) => _setFractionalScaling(value),
            activeColor: Colors.tealAccent,
          ),
        ],
      ),
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
}
