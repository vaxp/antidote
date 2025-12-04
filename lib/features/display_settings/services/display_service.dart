import 'dart:io';
import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';
import '../models/display_resolution.dart';

/// Service class that handles all display-related operations
class DisplayService {
  DBusClient? _sysbus;
  String? _cachedDisplayName;

  DBusClient get sysbus {
    _sysbus ??= DBusClient.system();
    return _sysbus!;
  }

  // ========== Display Server Detection ==========

  /// Detect the display server (X11 or Wayland)
  Future<String> detectDisplayServer() async {
    try {
      final waylandDisplay = Platform.environment['WAYLAND_DISPLAY'];
      if (waylandDisplay != null && waylandDisplay.isNotEmpty) {
        return 'Wayland';
      }

      final sessionType = Platform.environment['XDG_SESSION_TYPE'];
      if (sessionType != null) {
        return sessionType.toLowerCase() == 'wayland' ? 'Wayland' : 'X11';
      }

      try {
        final result = await Process.run('xrandr', ['--version']);
        if (result.exitCode == 0) {
          return 'X11';
        }
      } catch (_) {}

      return 'Wayland';
    } catch (e) {
      debugPrint('Detect display server error: $e');
      return 'Unknown';
    }
  }

  // ========== Display Name ==========

  /// Get display name for xrandr commands
  Future<String?> getDisplayName() async {
    if (_cachedDisplayName != null) return _cachedDisplayName;

    try {
      final result = await Process.run('xrandr', []);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        for (final line in lines) {
          if (line.contains(' connected')) {
            final match = RegExp(r'^(\S+)\s+connected').firstMatch(line);
            if (match != null) {
              _cachedDisplayName = match.group(1);
              return _cachedDisplayName;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Get display name error: $e');
    }
    return null;
  }

  // ========== Resolution ==========

  /// Get X11 available resolutions
  Future<List<DisplayResolution>> getX11AvailableResolutions() async {
    final List<DisplayResolution> resolutions = [];
    try {
      final result = await Process.run('xrandr', []);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final lines = output.split('\n');
        bool inConnectedOutput = false;

        for (final line in lines) {
          if (line.contains(' connected')) {
            inConnectedOutput = true;
            continue;
          }
          if (line.contains(' disconnected')) {
            inConnectedOutput = false;
            continue;
          }

          if (inConnectedOutput) {
            final match = RegExp(r'\s+(\d+)x(\d+)\s+').firstMatch(line);
            if (match != null) {
              final width = int.tryParse(match.group(1) ?? '') ?? 0;
              final height = int.tryParse(match.group(2) ?? '') ?? 0;
              if (width > 0 && height > 0) {
                final gcd = _gcd(width, height);
                final aspectW = width ~/ gcd;
                final aspectH = height ~/ gcd;
                final aspectRatio = '$aspectW:$aspectH';

                if (!resolutions.any(
                  (r) => r.width == width && r.height == height,
                )) {
                  resolutions.add(
                    DisplayResolution(
                      width: width,
                      height: height,
                      aspectRatio: aspectRatio,
                      isNative: line.contains('+'),
                    ),
                  );
                }
              }
            }
          }
        }

        resolutions.sort(
          (a, b) => (b.width * b.height).compareTo(a.width * a.height),
        );
      }
    } catch (e) {
      debugPrint('Get X11 resolutions error: $e');
    }
    return resolutions;
  }

  /// Get current X11 resolution
  Future<Map<String, dynamic>> getX11DisplayInfo() async {
    try {
      final result = await Process.run('xrandr', ['--current']);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final lines = output.split('\n');

        for (final line in lines) {
          if (line.contains(' connected') && line.contains('+')) {
            final modeMatch = RegExp(
              r'(\d+)x(\d+)\+.*?(\d+\.\d+)\s*Hz',
            ).firstMatch(line);
            if (modeMatch != null) {
              final width = int.tryParse(modeMatch.group(1) ?? '') ?? 1680;
              final height = int.tryParse(modeMatch.group(2) ?? '') ?? 1050;
              final refresh = modeMatch.group(3) ?? '60.00';

              final gcd = _gcd(width, height);
              final aspectW = width ~/ gcd;
              final aspectH = height ~/ gcd;

              return {
                'width': width,
                'height': height,
                'aspectRatio': '$aspectW:$aspectH',
                'refreshRate': '$refresh Hz',
                'orientation':
                    (line.contains('left') || line.contains('inverted'))
                    ? 'Portrait'
                    : 'Landscape',
              };
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Get X11 display info error: $e');
    }
    return {};
  }

  /// Get X11 available refresh rates
  Future<List<String>> getX11AvailableRefreshRates(
    int width,
    int height,
  ) async {
    final List<String> rates = [];
    try {
      final result = await Process.run('xrandr', []);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final lines = output.split('\n');

        for (final line in lines) {
          if (line.contains('${width}x$height')) {
            final rateMatches = RegExp(r'(\d+\.\d+)\s*\+?\*?').allMatches(line);
            for (final match in rateMatches) {
              final rate = match.group(1);
              if (rate != null && !rates.contains('$rate Hz')) {
                rates.add('$rate Hz');
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Get X11 refresh rates error: $e');
    }
    return rates;
  }

  /// Set X11 resolution
  Future<bool> setResolution(DisplayResolution resolution) async {
    try {
      final displayName = await getDisplayName();
      if (displayName == null) return false;

      final result = await Process.run('xrandr', [
        '--output',
        displayName,
        '--mode',
        '${resolution.width}x${resolution.height}',
      ]);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('Set resolution error: $e');
      return false;
    }
  }

  /// Set refresh rate
  Future<bool> setRefreshRate(String refreshRate) async {
    try {
      final displayName = await getDisplayName();
      if (displayName == null) return false;

      final rate = refreshRate.replaceAll(' Hz', '');
      final result = await Process.run('xrandr', [
        '--output',
        displayName,
        '--rate',
        rate,
      ]);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('Set refresh rate error: $e');
      return false;
    }
  }

  // ========== Orientation ==========

  /// Set display orientation
  Future<bool> setOrientation(String orientation, String displayServer) async {
    try {
      final displayName = await getDisplayName();
      if (displayName == null) return false;

      String xrandrOrientation;
      switch (orientation) {
        case 'Portrait Left':
          xrandrOrientation = 'left';
          break;
        case 'Portrait Right':
          xrandrOrientation = 'right';
          break;
        case 'Landscape Inverted':
          xrandrOrientation = 'inverted';
          break;
        default:
          xrandrOrientation = 'normal';
      }

      final result = await Process.run('xrandr', [
        '--output',
        displayName,
        '--rotate',
        xrandrOrientation,
      ]);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('Set orientation error: $e');
      return false;
    }
  }

  // ========== Scale ==========

  /// Set display scale
  Future<bool> setScale(int scale) async {
    try {
      final scaleFactor = scale / 100.0;
      final result = await Process.run('gsettings', [
        'set',
        'org.gnome.desktop.interface',
        'text-scaling-factor',
        scaleFactor.toString(),
      ]);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('Set scale error: $e');
      return false;
    }
  }

  /// Get current scale
  Future<int> getScale() async {
    try {
      final result = await Process.run('gsettings', [
        'get',
        'org.gnome.desktop.interface',
        'text-scaling-factor',
      ]);
      if (result.exitCode == 0) {
        final scaleValue =
            double.tryParse(result.stdout.toString().trim()) ?? 1.0;
        return (scaleValue * 100).round();
      }
    } catch (e) {
      debugPrint('Get scale error: $e');
    }
    return 100;
  }

  /// Set fractional scaling
  Future<bool> setFractionalScaling(bool enabled) async {
    try {
      final result = await Process.run('gsettings', [
        'set',
        'org.gnome.mutter',
        'experimental-features',
        enabled ? "['scale-monitor-framebuffer']" : '[]',
      ]);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('Set fractional scaling error: $e');
      return false;
    }
  }

  // ========== Brightness ==========

  /// Initialize brightness and detect method
  Future<Map<String, dynamic>> initBrightness() async {
    // Try xrandr first
    try {
      final xrandrCheck = await Process.run('xrandr', ['--version']);
      if (xrandrCheck.exitCode == 0) {
        final displayName = await getDisplayName();
        if (displayName != null) {
          return {
            'brightness': 100.0,
            'maxBrightness': 100.0,
            'brightnessSupported': true,
            'brightnessMethod': 'xrandr',
          };
        }
      }
    } catch (e) {
      debugPrint('xrandr brightness failed: $e');
    }

    // Try brightnessctl
    try {
      final maxResult = await Process.run('brightnessctl', ['m']);
      final currentResult = await Process.run('brightnessctl', ['g']);
      if (maxResult.exitCode == 0 && currentResult.exitCode == 0) {
        final max =
            double.tryParse(maxResult.stdout.toString().trim()) ?? 100.0;
        final current =
            double.tryParse(currentResult.stdout.toString().trim()) ?? 100.0;
        if (max > 0) {
          return {
            'brightness': (current / max * 100).clamp(0.0, 100.0),
            'maxBrightness': max,
            'brightnessSupported': true,
            'brightnessMethod': 'brightnessctl',
          };
        }
      }
    } catch (e) {
      debugPrint('brightnessctl failed: $e');
    }

    return {
      'brightness': 100.0,
      'maxBrightness': 100.0,
      'brightnessSupported': false,
      'brightnessMethod': 'none',
    };
  }

  /// Set brightness
  Future<bool> setBrightness(
    double value,
    String method,
    double maxBrightness,
  ) async {
    try {
      if (method == 'xrandr') {
        final displayName = await getDisplayName();
        if (displayName != null) {
          final brightnessValue = (value / 100.0).clamp(0.0, 1.0);
          final result = await Process.run('xrandr', [
            '--output',
            displayName,
            '--brightness',
            brightnessValue.toStringAsFixed(2),
          ]);
          return result.exitCode == 0;
        }
      } else if (method == 'brightnessctl') {
        final absoluteValue = (value / 100.0 * maxBrightness).round();
        final result = await Process.run('brightnessctl', [
          's',
          absoluteValue.toString(),
        ]);
        return result.exitCode == 0;
      }
    } catch (e) {
      debugPrint('Set brightness error: $e');
    }
    return false;
  }

  // ========== Night Light ==========

  /// Get night light status
  Future<bool> getNightLightStatus() async {
    try {
      final result = await Process.run('gsettings', [
        'get',
        'org.gnome.settings-daemon.plugins.color',
        'night-light-enabled',
      ]);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim() == 'true';
      }
    } catch (e) {
      debugPrint('Get night light status error: $e');
    }
    return false;
  }

  /// Set night light
  Future<bool> setNightLight(bool enabled) async {
    try {
      final result = await Process.run('gsettings', [
        'set',
        'org.gnome.settings-daemon.plugins.color',
        'night-light-enabled',
        enabled.toString(),
      ]);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('Set night light error: $e');
      return false;
    }
  }

  // ========== Helpers ==========

  int _gcd(int a, int b) {
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a;
  }

  void dispose() {
    _sysbus?.close();
    _sysbus = null;
  }
}
