import 'dart:io';
import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';

/// Service class that handles all system calls for power settings
class PowerService {
  DBusClient? _sysbus;

  DBusClient get sysbus {
    _sysbus ??= DBusClient.system();
    return _sysbus!;
  }

  /// Get battery level and charging status
  Future<Map<String, dynamic>> getBatteryInfo() async {
    try {
      final object = DBusRemoteObject(
        sysbus,
        name: 'org.freedesktop.UPower',
        path: DBusObjectPath('/org/freedesktop/UPower/devices/DisplayDevice'),
      );

      final percent =
          (await object.getProperty(
                'org.freedesktop.UPower.Device',
                'Percentage',
              ))
              as DBusDouble;

      final state =
          (await object.getProperty('org.freedesktop.UPower.Device', 'State'))
              as DBusUint32;

      return {'batteryLevel': percent.value, 'isCharging': state.value == 1};
    } catch (e) {
      debugPrint('Get battery info error: $e');
      return {'batteryLevel': 0.0, 'isCharging': false};
    }
  }

  /// Get current power profile
  Future<String> getPowerProfile() async {
    try {
      final ppd = DBusRemoteObject(
        sysbus,
        name: 'org.freedesktop.UPower.PowerProfiles',
        path: DBusObjectPath('/org/freedesktop/UPower/PowerProfiles'),
      );

      final active =
          (await ppd.getProperty(
                'org.freedesktop.UPower.PowerProfiles',
                'ActiveProfile',
              ))
              as DBusString;

      return active.value;
    } catch (e) {
      debugPrint('Get power profile error: $e');
      return 'balanced';
    }
  }

  /// Set power profile
  Future<bool> setPowerProfile(String profile) async {
    try {
      final ppd = DBusRemoteObject(
        sysbus,
        name: 'org.freedesktop.UPower.PowerProfiles',
        path: DBusObjectPath('/org/freedesktop/UPower/PowerProfiles'),
      );

      await ppd.setProperty(
        'org.freedesktop.UPower.PowerProfiles',
        'ActiveProfile',
        DBusString(profile),
      );

      return true;
    } catch (e) {
      debugPrint('Set power profile error: $e');
      return false;
    }
  }

  /// Perform a power action (shutdown, reboot, suspend, logout)
  Future<void> performPowerAction(String action) async {
    switch (action) {
      case 'shutdown':
        await Process.run('systemctl', ['poweroff']);
        break;
      case 'reboot':
        await Process.run('systemctl', ['reboot']);
        break;
      case 'suspend':
        await Process.run('systemctl', ['suspend']);
        break;
      case 'logout':
        final user = Platform.environment['USER'];
        if (user != null) {
          await Process.run('loginctl', ['terminate-user', user]);
        }
        break;
    }
  }

  /// Close DBus connection
  void dispose() {
    _sysbus?.close();
    _sysbus = null;
  }
}
