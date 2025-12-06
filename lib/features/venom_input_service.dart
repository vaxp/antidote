// Venom Input D-Bus Service Layer
// يوفر واجهة Dart للتحكم بعفريت venom_input
//
// يتحكم في: الكيبورد، الماوس، التاتش باد

import 'package:dbus/dbus.dart';

/// خدمة التحكم بالماوس
class MouseService {
  final DBusClient _bus;
  late DBusRemoteObject _object;

  MouseService(this._bus) {
    _object = DBusRemoteObject(
      _bus,
      name: 'org.venom.Input',
      path: DBusObjectPath('/org/venom/Input/Mouse'),
    );
  }

  /// تعيين الزر الأساسي (left أو right)
  Future<bool> setPrimaryButton(String button) async {
    try {
      final result = await _object.callMethod(
        'org.venom.Input.Mouse',
        'SetPrimaryButton',
        [DBusString(button)],
        replySignature: DBusSignature('b'),
      );
      return result.values[0].asBoolean();
    } catch (e) {
      print('Error setPrimaryButton: $e');
      return false;
    }
  }

  /// الحصول على الزر الأساسي الحالي
  Future<String> getPrimaryButton() async {
    try {
      final result = await _object.callMethod(
        'org.venom.Input.Mouse',
        'GetPrimaryButton',
        [],
        replySignature: DBusSignature('s'),
      );
      return result.values[0].asString();
    } catch (e) {
      print('Error getPrimaryButton: $e');
      return 'left';
    }
  }

  /// تعيين سرعة المؤشر (-1.0 إلى 1.0)
  Future<bool> setPointerSpeed(double speed) async {
    try {
      final result = await _object.callMethod(
        'org.venom.Input.Mouse',
        'SetPointerSpeed',
        [DBusDouble(speed)],
        replySignature: DBusSignature('b'),
      );
      return result.values[0].asBoolean();
    } catch (e) {
      print('Error setPointerSpeed: $e');
      return false;
    }
  }

  /// الحصول على سرعة المؤشر الحالية
  Future<double> getPointerSpeed() async {
    try {
      final result = await _object.callMethod(
        'org.venom.Input.Mouse',
        'GetPointerSpeed',
        [],
        replySignature: DBusSignature('d'),
      );
      return result.values[0].asDouble();
    } catch (e) {
      print('Error getPointerSpeed: $e');
      return 0.0;
    }
  }

  /// تفعيل/تعطيل التسريع
  Future<bool> setAccelerationEnabled(bool enabled) async {
    try {
      final result = await _object.callMethod(
        'org.venom.Input.Mouse',
        'SetAccelerationEnabled',
        [DBusBoolean(enabled)],
        replySignature: DBusSignature('b'),
      );
      return result.values[0].asBoolean();
    } catch (e) {
      print('Error setAccelerationEnabled: $e');
      return false;
    }
  }

  /// الحصول على حالة التسريع
  Future<bool> getAccelerationEnabled() async {
    try {
      final result = await _object.callMethod(
        'org.venom.Input.Mouse',
        'GetAccelerationEnabled',
        [],
        replySignature: DBusSignature('b'),
      );
      return result.values[0].asBoolean();
    } catch (e) {
      print('Error getAccelerationEnabled: $e');
      return true;
    }
  }

  /// تفعيل/تعطيل التمرير الطبيعي
  Future<bool> setNaturalScroll(bool enabled) async {
    try {
      final result = await _object.callMethod(
        'org.venom.Input.Mouse',
        'SetNaturalScroll',
        [DBusBoolean(enabled)],
        replySignature: DBusSignature('b'),
      );
      return result.values[0].asBoolean();
    } catch (e) {
      print('Error setNaturalScroll: $e');
      return false;
    }
  }

  /// الحصول على حالة التمرير الطبيعي
  Future<bool> getNaturalScroll() async {
    try {
      final result = await _object.callMethod(
        'org.venom.Input.Mouse',
        'GetNaturalScroll',
        [],
        replySignature: DBusSignature('b'),
      );
      return result.values[0].asBoolean();
    } catch (e) {
      print('Error getNaturalScroll: $e');
      return false;
    }
  }
}

/// خدمة التحكم بالتاتش باد
class TouchpadService {
  final DBusClient _bus;
  late DBusRemoteObject _object;

  TouchpadService(this._bus) {
    _object = DBusRemoteObject(
      _bus,
      name: 'org.venom.Input',
      path: DBusObjectPath('/org/venom/Input/Touchpad'),
    );
  }

  /// تفعيل/تعطيل التاتش باد
  Future<bool> setEnabled(bool enabled) async {
    try {
      final result = await _object.callMethod(
        'org.venom.Input.Touchpad',
        'SetEnabled',
        [DBusBoolean(enabled)],
        replySignature: DBusSignature('b'),
      );
      return result.values[0].asBoolean();
    } catch (e) {
      print('Error setEnabled: $e');
      return false;
    }
  }

  /// الحصول على حالة التاتش باد
  Future<bool> getEnabled() async {
    try {
      final result = await _object.callMethod(
        'org.venom.Input.Touchpad',
        'GetEnabled',
        [],
        replySignature: DBusSignature('b'),
      );
      return result.values[0].asBoolean();
    } catch (e) {
      print('Error getEnabled: $e');
      return true;
    }
  }

  /// تفعيل/تعطيل اإيقاف أثناء الكتابة
  Future<bool> setDisableWhileTyping(bool enabled) async {
    try {
      final result = await _object.callMethod(
        'org.venom.Input.Touchpad',
        'SetDisableWhileTyping',
        [DBusBoolean(enabled)],
        replySignature: DBusSignature('b'),
      );
      return result.values[0].asBoolean();
    } catch (e) {
      print('Error setDisableWhileTyping: $e');
      return false;
    }
  }

  /// الحصول على حالة الإيقاف أثناء الكتابة
  Future<bool> getDisableWhileTyping() async {
    try {
      final result = await _object.callMethod(
        'org.venom.Input.Touchpad',
        'GetDisableWhileTyping',
        [],
        replySignature: DBusSignature('b'),
      );
      return result.values[0].asBoolean();
    } catch (e) {
      print('Error getDisableWhileTyping: $e');
      return true;
    }
  }

  /// تعيين سرعة المؤشر
  Future<bool> setPointerSpeed(double speed) async {
    try {
      final result = await _object.callMethod(
        'org.venom.Input.Touchpad',
        'SetPointerSpeed',
        [DBusDouble(speed)],
        replySignature: DBusSignature('b'),
      );
      return result.values[0].asBoolean();
    } catch (e) {
      print('Error setPointerSpeed: $e');
      return false;
    }
  }

  /// الحصول على سرعة المؤشر
  Future<double> getPointerSpeed() async {
    try {
      final result = await _object.callMethod(
        'org.venom.Input.Touchpad',
        'GetPointerSpeed',
        [],
        replySignature: DBusSignature('d'),
      );
      return result.values[0].asDouble();
    } catch (e) {
      print('Error getPointerSpeed: $e');
      return 0.0;
    }
  }

  /// تعيين طريقة النقر الثانوي (two-finger أو corner)
  Future<bool> setSecondaryClick(String method) async {
    try {
      final result = await _object.callMethod(
        'org.venom.Input.Touchpad',
        'SetSecondaryClick',
        [DBusString(method)],
        replySignature: DBusSignature('b'),
      );
      return result.values[0].asBoolean();
    } catch (e) {
      print('Error setSecondaryClick: $e');
      return false;
    }
  }

  /// الحصول على طريقة النقر الثانوي
  Future<String> getSecondaryClick() async {
    try {
      final result = await _object.callMethod(
        'org.venom.Input.Touchpad',
        'GetSecondaryClick',
        [],
        replySignature: DBusSignature('s'),
      );
      return result.values[0].asString();
    } catch (e) {
      print('Error getSecondaryClick: $e');
      return 'two-finger';
    }
  }

  /// تفعيل/تعطيل النقر باللمس
  Future<bool> setTapToClick(bool enabled) async {
    try {
      final result = await _object.callMethod(
        'org.venom.Input.Touchpad',
        'SetTapToClick',
        [DBusBoolean(enabled)],
        replySignature: DBusSignature('b'),
      );
      return result.values[0].asBoolean();
    } catch (e) {
      print('Error setTapToClick: $e');
      return false;
    }
  }

  /// الحصول على حالة النقر باللمس
  Future<bool> getTapToClick() async {
    try {
      final result = await _object.callMethod(
        'org.venom.Input.Touchpad',
        'GetTapToClick',
        [],
        replySignature: DBusSignature('b'),
      );
      return result.values[0].asBoolean();
    } catch (e) {
      print('Error getTapToClick: $e');
      return true;
    }
  }
}

/// خدمة التحكم بالكيبورد
class KeyboardService {
  final DBusClient _bus;
  late DBusRemoteObject _object;

  KeyboardService(this._bus) {
    _object = DBusRemoteObject(
      _bus,
      name: 'org.venom.Input',
      path: DBusObjectPath('/org/venom/Input'),
    );
  }

  /// تعيين تخطيطات الكيبورد
  Future<bool> setLayouts(String layouts) async {
    try {
      final result = await _object.callMethod('org.venom.Input', 'SetLayouts', [
        DBusString(layouts),
      ], replySignature: DBusSignature('b'));
      return result.values[0].asBoolean();
    } catch (e) {
      print('Error setLayouts: $e');
      return false;
    }
  }

  /// الحصول على التخطيطات الحالية
  Future<String> getLayouts() async {
    try {
      final result = await _object.callMethod(
        'org.venom.Input',
        'GetLayouts',
        [],
        replySignature: DBusSignature('s'),
      );
      return result.values[0].asString();
    } catch (e) {
      print('Error getLayouts: $e');
      return 'us';
    }
  }
}
