import 'dart:io';
import 'package:flutter/foundation.dart';

/// Service class that handles all gsettings calls for mouse/touchpad settings
class MouseService {
  // ========== Mouse Settings ==========

  /// Get primary button setting
  Future<String> getPrimaryButton() async {
    try {
      final result = await Process.run('gsettings', [
        'get',
        'org.gnome.desktop.peripherals.mouse',
        'left-handed',
      ]);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim() == 'true' ? 'right' : 'left';
      }
    } catch (e) {
      debugPrint('Get primary button error: $e');
    }
    return 'left';
  }

  /// Get mouse pointer speed
  Future<double> getMousePointerSpeed() async {
    try {
      final result = await Process.run('gsettings', [
        'get',
        'org.gnome.desktop.peripherals.mouse',
        'speed',
      ]);
      if (result.exitCode == 0) {
        final value = double.tryParse(result.stdout.toString().trim()) ?? 0.0;
        return (value + 1.0) / 2.0; // Convert -1.0 to 1.0 → 0.0 to 1.0
      }
    } catch (e) {
      debugPrint('Get mouse pointer speed error: $e');
    }
    return 0.5;
  }

  /// Get mouse acceleration
  Future<bool> getMouseAcceleration() async {
    try {
      final result = await Process.run('gsettings', [
        'get',
        'org.gnome.desktop.peripherals.mouse',
        'accel-profile',
      ]);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim() != "'flat'";
      }
    } catch (e) {
      debugPrint('Get mouse acceleration error: $e');
    }
    return true;
  }

  /// Get scroll direction
  Future<String> getScrollDirection() async {
    try {
      final result = await Process.run('gsettings', [
        'get',
        'org.gnome.desktop.peripherals.mouse',
        'natural-scroll',
      ]);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim() == 'true' ? 'natural' : 'traditional';
      }
    } catch (e) {
      debugPrint('Get scroll direction error: $e');
    }
    return 'traditional';
  }

  /// Set primary button
  Future<void> setPrimaryButton(String button) async {
    try {
      await Process.run('gsettings', [
        'set',
        'org.gnome.desktop.peripherals.mouse',
        'left-handed',
        button == 'right' ? 'true' : 'false',
      ]);
    } catch (e) {
      debugPrint('Set primary button error: $e');
    }
  }

  /// Set mouse pointer speed
  Future<void> setMousePointerSpeed(double value) async {
    try {
      final speed = (value * 2.0) - 1.0; // Convert 0.0-1.0 → -1.0 to 1.0
      await Process.run('gsettings', [
        'set',
        'org.gnome.desktop.peripherals.mouse',
        'speed',
        speed.toStringAsFixed(2),
      ]);
    } catch (e) {
      debugPrint('Set mouse pointer speed error: $e');
    }
  }

  /// Set mouse acceleration
  Future<void> setMouseAcceleration(bool enabled) async {
    try {
      await Process.run('gsettings', [
        'set',
        'org.gnome.desktop.peripherals.mouse',
        'accel-profile',
        enabled ? "'adaptive'" : "'flat'",
      ]);
    } catch (e) {
      debugPrint('Set mouse acceleration error: $e');
    }
  }

  /// Set scroll direction
  Future<void> setScrollDirection(String direction) async {
    try {
      await Process.run('gsettings', [
        'set',
        'org.gnome.desktop.peripherals.mouse',
        'natural-scroll',
        direction == 'natural' ? 'true' : 'false',
      ]);
    } catch (e) {
      debugPrint('Set scroll direction error: $e');
    }
  }

  // ========== Touchpad Settings ==========

  /// Get touchpad enabled
  Future<bool> getTouchpadEnabled() async {
    try {
      final result = await Process.run('gsettings', [
        'get',
        'org.gnome.desktop.peripherals.touchpad',
        'send-events',
      ]);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim() != "'disabled'";
      }
    } catch (e) {
      debugPrint('Get touchpad enabled error: $e');
    }
    return true;
  }

  /// Get disable while typing
  Future<bool> getDisableWhileTyping() async {
    try {
      final result = await Process.run('gsettings', [
        'get',
        'org.gnome.desktop.peripherals.touchpad',
        'disable-while-typing',
      ]);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim() == 'true';
      }
    } catch (e) {
      debugPrint('Get disable while typing error: $e');
    }
    return true;
  }

  /// Get touchpad pointer speed
  Future<double> getTouchpadPointerSpeed() async {
    try {
      final result = await Process.run('gsettings', [
        'get',
        'org.gnome.desktop.peripherals.touchpad',
        'speed',
      ]);
      if (result.exitCode == 0) {
        final value = double.tryParse(result.stdout.toString().trim()) ?? 0.0;
        return (value + 1.0) / 2.0;
      }
    } catch (e) {
      debugPrint('Get touchpad pointer speed error: $e');
    }
    return 0.5;
  }

  /// Get secondary click method
  Future<String> getSecondaryClick() async {
    try {
      final result = await Process.run('gsettings', [
        'get',
        'org.gnome.desktop.peripherals.touchpad',
        'click-method',
      ]);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim() == "'fingers'" ? 'two-finger' : 'corner';
      }
    } catch (e) {
      debugPrint('Get secondary click error: $e');
    }
    return 'two-finger';
  }

  /// Get tap to click
  Future<bool> getTapToClick() async {
    try {
      final result = await Process.run('gsettings', [
        'get',
        'org.gnome.desktop.peripherals.touchpad',
        'tap-to-click',
      ]);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim() == 'true';
      }
    } catch (e) {
      debugPrint('Get tap to click error: $e');
    }
    return true;
  }

  /// Set touchpad enabled
  Future<void> setTouchpadEnabled(bool enabled) async {
    try {
      await Process.run('gsettings', [
        'set',
        'org.gnome.desktop.peripherals.touchpad',
        'send-events',
        enabled ? "'enabled'" : "'disabled'",
      ]);
    } catch (e) {
      debugPrint('Set touchpad enabled error: $e');
    }
  }

  /// Set disable while typing
  Future<void> setDisableWhileTyping(bool enabled) async {
    try {
      await Process.run('gsettings', [
        'set',
        'org.gnome.desktop.peripherals.touchpad',
        'disable-while-typing',
        enabled.toString(),
      ]);
    } catch (e) {
      debugPrint('Set disable while typing error: $e');
    }
  }

  /// Set touchpad pointer speed
  Future<void> setTouchpadPointerSpeed(double value) async {
    try {
      final speed = (value * 2.0) - 1.0;
      await Process.run('gsettings', [
        'set',
        'org.gnome.desktop.peripherals.touchpad',
        'speed',
        speed.toStringAsFixed(2),
      ]);
    } catch (e) {
      debugPrint('Set touchpad pointer speed error: $e');
    }
  }

  /// Set secondary click method
  Future<void> setSecondaryClick(String method) async {
    try {
      await Process.run('gsettings', [
        'set',
        'org.gnome.desktop.peripherals.touchpad',
        'click-method',
        method == 'two-finger' ? "'fingers'" : "'areas'",
      ]);
    } catch (e) {
      debugPrint('Set secondary click error: $e');
    }
  }

  /// Set tap to click
  Future<void> setTapToClick(bool enabled) async {
    try {
      await Process.run('gsettings', [
        'set',
        'org.gnome.desktop.peripherals.touchpad',
        'tap-to-click',
        enabled.toString(),
      ]);
    } catch (e) {
      debugPrint('Set tap to click error: $e');
    }
  }
}
