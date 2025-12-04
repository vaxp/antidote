import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/audio_device.dart';

/// Service class that handles all system calls for audio settings
class AudioService {
  /// Get output devices using pactl
  Future<List<AudioDevice>> getOutputDevices() async {
    try {
      final result = await Process.run('pactl', ['list', 'short', 'sinks']);
      if (result.exitCode != 0) return [];

      final lines = result.stdout.toString().split('\n');
      final List<AudioDevice> devices = [];
      String? defaultSink;

      // Get default sink
      final defaultResult = await Process.run('pactl', ['get-default-sink']);
      if (defaultResult.exitCode == 0) {
        defaultSink = defaultResult.stdout.toString().trim();
      }

      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final parts = line.split('\t');
        if (parts.length >= 2) {
          final sinkIndex = parts[0];
          final sinkName = parts[1];
          String description = sinkName;

          // Get better description
          try {
            final sinkInfo = await Process.run('pactl', ['list', 'sinks']);
            if (sinkInfo.exitCode == 0) {
              final sinkInfoLines = sinkInfo.stdout.toString().split('\n');
              bool inSink = false;
              for (final infoLine in sinkInfoLines) {
                if (infoLine.contains('Sink #$sinkIndex') ||
                    infoLine.contains('Name: $sinkName')) {
                  inSink = true;
                  continue;
                }
                if (inSink && infoLine.contains('Description:')) {
                  description = infoLine.split('Description:')[1].trim();
                  break;
                }
                if (inSink && infoLine.startsWith('Sink #')) {
                  break;
                }
              }
            }
          } catch (_) {}

          final isDefault = sinkName == defaultSink;

          if (!devices.any((d) => d.name == sinkName)) {
            devices.add(
              AudioDevice(
                name: sinkName,
                description: description,
                isInput: false,
                isDefault: isDefault,
              ),
            );
          }
        }
      }
      return devices;
    } catch (e) {
      debugPrint('Get output devices error: $e');
      return [];
    }
  }

  /// Get input devices using pactl
  Future<List<AudioDevice>> getInputDevices() async {
    try {
      final result = await Process.run('pactl', ['list', 'short', 'sources']);
      if (result.exitCode != 0) return [];

      final lines = result.stdout.toString().split('\n');
      final List<AudioDevice> devices = [];
      String? defaultSource;

      // Get default source
      final defaultResult = await Process.run('pactl', ['get-default-source']);
      if (defaultResult.exitCode == 0) {
        defaultSource = defaultResult.stdout.toString().trim();
      }

      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final parts = line.split('\t');
        if (parts.length >= 2) {
          final sourceIndex = parts[0];
          final sourceName = parts[1];

          // Skip monitor sources
          if (sourceName.contains('.monitor')) continue;

          String description = sourceName;

          // Get better description
          try {
            final sourceInfo = await Process.run('pactl', ['list', 'sources']);
            if (sourceInfo.exitCode == 0) {
              final sourceInfoLines = sourceInfo.stdout.toString().split('\n');
              bool inSource = false;
              for (final infoLine in sourceInfoLines) {
                if (infoLine.contains('Source #$sourceIndex') ||
                    infoLine.contains('Name: $sourceName')) {
                  inSource = true;
                  continue;
                }
                if (inSource && infoLine.contains('Description:')) {
                  description = infoLine.split('Description:')[1].trim();
                  break;
                }
                if (inSource && infoLine.startsWith('Source #')) {
                  break;
                }
              }
            }
          } catch (_) {}

          final isDefault = sourceName == defaultSource;

          if (!devices.any((d) => d.name == sourceName)) {
            devices.add(
              AudioDevice(
                name: sourceName,
                description: description,
                isInput: true,
                isDefault: isDefault,
              ),
            );
          }
        }
      }
      return devices;
    } catch (e) {
      debugPrint('Get input devices error: $e');
      return [];
    }
  }

  /// Get output volume
  Future<double> getOutputVolume() async {
    try {
      final result = await Process.run('pactl', [
        'get-sink-volume',
        '@DEFAULT_SINK@',
      ]);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final match = RegExp(r'(\d+)%').firstMatch(output);
        if (match != null) {
          return (int.tryParse(match.group(1) ?? '') ?? 75).toDouble();
        }
      }
    } catch (e) {
      debugPrint('Get output volume error: $e');
    }
    return 75.0;
  }

  /// Get input volume
  Future<double> getInputVolume() async {
    try {
      final result = await Process.run('pactl', [
        'get-source-volume',
        '@DEFAULT_SOURCE@',
      ]);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final match = RegExp(r'(\d+)%').firstMatch(output);
        if (match != null) {
          return (int.tryParse(match.group(1) ?? '') ?? 75).toDouble();
        }
      }
    } catch (e) {
      debugPrint('Get input volume error: $e');
    }
    return 75.0;
  }

  /// Get audio balance
  Future<double> getBalance() async {
    try {
      final result = await Process.run('pactl', [
        'get-sink-volume',
        '@DEFAULT_SINK@',
      ]);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final matches = RegExp(r'(\d+)%').allMatches(output).toList();
        if (matches.length >= 2) {
          final left = int.tryParse(matches[0].group(1) ?? '') ?? 50;
          final right = int.tryParse(matches[1].group(1) ?? '') ?? 50;
          final balance = ((right - left) / 2) + 50;
          return balance.clamp(0.0, 100.0);
        }
      }
    } catch (e) {
      debugPrint('Get balance error: $e');
    }
    return 50.0;
  }

  /// Set output device
  Future<bool> setOutputDevice(AudioDevice device) async {
    try {
      await Process.run('pactl', ['set-default-sink', device.name]);
      return true;
    } catch (e) {
      debugPrint('Set output device error: $e');
      return false;
    }
  }

  /// Set input device
  Future<bool> setInputDevice(AudioDevice device) async {
    try {
      await Process.run('pactl', ['set-default-source', device.name]);
      return true;
    } catch (e) {
      debugPrint('Set input device error: $e');
      return false;
    }
  }

  /// Set output volume
  Future<bool> setOutputVolume(double value) async {
    try {
      final volumePercent = value.toInt();
      await Process.run('pactl', [
        'set-sink-volume',
        '@DEFAULT_SINK@',
        '$volumePercent%',
      ]);
      return true;
    } catch (e) {
      debugPrint('Set output volume error: $e');
      return false;
    }
  }

  /// Set input volume
  Future<bool> setInputVolume(double value) async {
    try {
      final volumePercent = value.toInt();
      await Process.run('pactl', [
        'set-source-volume',
        '@DEFAULT_SOURCE@',
        '$volumePercent%',
      ]);
      return true;
    } catch (e) {
      debugPrint('Set input volume error: $e');
      return false;
    }
  }

  /// Set audio balance
  Future<bool> setBalance(double value, double outputVolume) async {
    try {
      final diff = (value - 50) * 2;
      final leftPercent = (outputVolume - diff).clamp(0.0, 100.0);
      final rightPercent = (outputVolume + diff).clamp(0.0, 100.0);

      await Process.run('pactl', [
        'set-sink-volume',
        '@DEFAULT_SINK@',
        '${leftPercent.toInt()}%',
        '${rightPercent.toInt()}%',
      ]);
      return true;
    } catch (e) {
      debugPrint('Set balance error: $e');
      return false;
    }
  }

  /// Test audio output
  Future<void> testOutput() async {
    try {
      await Process.run('paplay', [
        '/usr/share/sounds/freedesktop/stereo/bell.ogg',
      ]);
    } catch (_) {
      try {
        await Process.run('speaker-test', [
          '-t',
          'sine',
          '-f',
          '1000',
          '-l',
          '1',
          '-c',
          '2',
        ]);
      } catch (_) {}
    }
  }
}
