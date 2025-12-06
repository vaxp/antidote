// Mouse Service - D-Bus wrapper for venom_input
//
// This service wraps the D-Bus classes from venom_input_service.dart
// and provides the interface expected by MouseSettingsBloc.

import 'package:dbus/dbus.dart';

// Import the D-Bus service classes
import 'package:antidote/venom_input_service.dart' as venom;

/// Unified Mouse/Touchpad service for BLoC integration
class MouseService {
  final DBusClient _bus = DBusClient.session();
  late venom.MouseService _mouse;
  late venom.TouchpadService _touchpad;

  MouseService() {
    _mouse = venom.MouseService(_bus);
    _touchpad = venom.TouchpadService(_bus);
  }

  /// Dispose the D-Bus connection
  Future<void> dispose() async {
    await _bus.close();
  }

  // ========== Mouse Settings ==========

  /// Get primary button (left/right)
  Future<String> getPrimaryButton() => _mouse.getPrimaryButton();

  /// Set primary button
  Future<void> setPrimaryButton(String button) async {
    await _mouse.setPrimaryButton(button);
  }

  /// Get mouse pointer speed (returns raw D-Bus value: -1.0 to 1.0)
  Future<double> getMousePointerSpeed() => _mouse.getPointerSpeed();

  /// Set mouse pointer speed
  Future<void> setMousePointerSpeed(double speed) async {
    await _mouse.setPointerSpeed(speed);
  }

  /// Get mouse acceleration enabled
  Future<bool> getMouseAcceleration() => _mouse.getAccelerationEnabled();

  /// Set mouse acceleration
  Future<void> setMouseAcceleration(bool enabled) async {
    await _mouse.setAccelerationEnabled(enabled);
  }

  /// Get scroll direction as string (traditional/natural)
  Future<String> getScrollDirection() async {
    final natural = await _mouse.getNaturalScroll();
    return natural ? 'natural' : 'traditional';
  }

  /// Set scroll direction
  Future<void> setScrollDirection(String direction) async {
    await _mouse.setNaturalScroll(direction == 'natural');
  }

  // ========== Touchpad Settings ==========

  /// Get touchpad enabled
  Future<bool> getTouchpadEnabled() => _touchpad.getEnabled();

  /// Set touchpad enabled
  Future<void> setTouchpadEnabled(bool enabled) async {
    await _touchpad.setEnabled(enabled);
  }

  /// Get disable while typing
  Future<bool> getDisableWhileTyping() => _touchpad.getDisableWhileTyping();

  /// Set disable while typing
  Future<void> setDisableWhileTyping(bool enabled) async {
    await _touchpad.setDisableWhileTyping(enabled);
  }

  /// Get touchpad pointer speed
  Future<double> getTouchpadPointerSpeed() => _touchpad.getPointerSpeed();

  /// Set touchpad pointer speed
  Future<void> setTouchpadPointerSpeed(double speed) async {
    await _touchpad.setPointerSpeed(speed);
  }

  /// Get secondary click method (two-finger/corner)
  Future<String> getSecondaryClick() => _touchpad.getSecondaryClick();

  /// Set secondary click method
  Future<void> setSecondaryClick(String method) async {
    await _touchpad.setSecondaryClick(method);
  }

  /// Get tap to click
  Future<bool> getTapToClick() => _touchpad.getTapToClick();

  /// Set tap to click
  Future<void> setTapToClick(bool enabled) async {
    await _touchpad.setTapToClick(enabled);
  }
}
