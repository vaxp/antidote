import 'dart:io';
import 'package:flutter/foundation.dart';


class SystemService {
  

  
  Future<String> getCurrentLanguage() async {
    try {
      final result = await Process.run('locale', []);
      if (result.exitCode == 0) {
        final locale = result.stdout.toString();
        if (locale.contains('LANG=')) {
          final match = RegExp(r'LANG=([^\n]+)').firstMatch(locale);
          if (match != null) {
            return match.group(1) ?? 'en_US.UTF-8';
          }
        }
      }
    } catch (e) {
      debugPrint('Get language error: $e');
    }
    return 'en_US.UTF-8';
  }

  

  
  Future<String> getCurrentTimezone() async {
    try {
      final result = await Process.run('timedatectl', [
        'show',
        '--property=Timezone',
        '--value',
      ]);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
    } catch (e) {
      debugPrint('Get timezone error: $e');
    }
    return 'UTC';
  }

  
  Future<List<String>> getAvailableTimezones() async {
    try {
      final result = await Process.run('timedatectl', ['list-timezones']);
      if (result.exitCode == 0) {
        return result.stdout
            .toString()
            .split('\n')
            .where((tz) => tz.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
      }
    } catch (e) {
      debugPrint('Get timezones error: $e');
    }
    return [];
  }

  
  Future<bool> isAutomaticTimeEnabled() async {
    try {
      final result = await Process.run('timedatectl', [
        'show',
        '--property=NTP',
        '--value',
      ]);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim() == 'yes';
      }
    } catch (e) {
      debugPrint('Check NTP error: $e');
    }
    return true;
  }

  
  Future<bool> setAutomaticTime(bool enabled) async {
    try {
      final result = await Process.run('timedatectl', [
        'set-ntp',
        enabled.toString(),
      ]);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('Set NTP error: $e');
      return false;
    }
  }

  
  Future<bool> setTimezone(String timezone) async {
    try {
      final result = await Process.run('sudo', [
        'timedatectl',
        'set-timezone',
        timezone,
      ]);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('Set timezone error: $e');
      return false;
    }
  }

  

  
  Future<List<Map<String, String>>> getUsers() async {
    final List<Map<String, String>> users = [];
    try {
      final result = await Process.run('getent', ['passwd']);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        for (final line in lines) {
          final parts = line.split(':');
          if (parts.length >= 7) {
            final username = parts[0];
            final uid = parts[2];
            final home = parts[5];
            final shell = parts[6];

            final uidInt = int.tryParse(uid) ?? 0;
            if (uidInt >= 1000 &&
                (shell.contains('bash') ||
                    shell.contains('zsh') ||
                    shell.contains('fish'))) {
              users.add({'username': username, 'uid': uid, 'home': home});
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Get users error: $e');
    }
    return users;
  }

  

  
  Future<bool> isRemoteDesktopEnabled() async {
    try {
      final result = await Process.run('gsettings', [
        'get',
        'org.gnome.desktop.remote-desktop.rdp',
        'enable',
      ]);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim() == 'true';
      }
    } catch (e) {
      debugPrint('Check remote desktop error: $e');
    }
    return false;
  }

  
  Future<bool> setRemoteDesktopEnabled(bool enabled) async {
    try {
      final result = await Process.run('gsettings', [
        'set',
        'org.gnome.desktop.remote-desktop.rdp',
        'enable',
        enabled.toString(),
      ]);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('Set remote desktop error: $e');
      return false;
    }
  }

  

  
  Future<bool> isSSHEnabled() async {
    try {
      final result = await Process.run('systemctl', ['is-active', 'sshd']);
      return result.stdout.toString().trim() == 'active';
    } catch (e) {
      debugPrint('Check SSH error: $e');
      return false;
    }
  }

  
  Future<bool> setSSHEnabled(bool enabled) async {
    try {
      final action = enabled ? 'start' : 'stop';
      final result = await Process.run('sudo', ['systemctl', action, 'sshd']);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('Set SSH error: $e');
      return false;
    }
  }

  

  
  Future<String> getHostname() async {
    try {
      final result = await Process.run('hostname', []);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
    } catch (e) {
      debugPrint('Get hostname error: $e');
    }
    return 'Unknown';
  }

  
  Future<String> getOSName() async {
    try {
      final result = await Process.run('lsb_release', ['-d', '-s']);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
    } catch (e) {
      debugPrint('Get OS name error: $e');
    }
    return 'Linux';
  }

  
  Future<String> getKernelVersion() async {
    try {
      final result = await Process.run('uname', ['-r']);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
    } catch (e) {
      debugPrint('Get kernel error: $e');
    }
    return 'Unknown';
  }

  
  Future<String> getTotalMemory() async {
    try {
      final result = await Process.run('free', ['-h']);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        for (final line in lines) {
          if (line.startsWith('Mem:')) {
            final parts = line.split(RegExp(r'\s+'));
            if (parts.length > 1) {
              return parts[1];
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Get memory error: $e');
    }
    return 'Unknown';
  }

  
  Future<String> getCPUInfo() async {
    try {
      final result = await Process.run('bash', [
        '-c',
        "grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2",
      ]);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
    } catch (e) {
      debugPrint('Get CPU info error: $e');
    }
    return 'Unknown';
  }
}
