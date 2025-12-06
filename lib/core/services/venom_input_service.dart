import 'package:dbus/dbus.dart';
import 'package:antidote/core/services/dbus_service.dart';

class MouseService {
  late DBusRemoteObject _object;

  MouseService() {
    _object = DBusRemoteObject(
      DBusService().client,
      name: 'org.venom.Input',
      path: DBusObjectPath('/org/venom/Input/Mouse'),
    );
  }

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
      return false;
    }
  }

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
      return 'left';
    }
  }

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
      return false;
    }
  }

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
      return 0.0;
    }
  }

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
      return false;
    }
  }

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
      return true;
    }
  }

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
      return false;
    }
  }

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
      return false;
    }
  }
}

class TouchpadService {
  late DBusRemoteObject _object;

  TouchpadService() {
    _object = DBusRemoteObject(
      DBusService().client,
      name: 'org.venom.Input',
      path: DBusObjectPath('/org/venom/Input/Touchpad'),
    );
  }

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
      return false;
    }
  }

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
      return true;
    }
  }

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
      return false;
    }
  }

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
      return true;
    }
  }

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
      return false;
    }
  }

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
      return 0.0;
    }
  }

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
      return false;
    }
  }

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
      return 'two-finger';
    }
  }

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
      return false;
    }
  }

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
      return true;
    }
  }
}

class KeyboardService {
  late DBusRemoteObject _object;

  KeyboardService() {
    _object = DBusRemoteObject(
      DBusService().client,
      name: 'org.venom.Input',
      path: DBusObjectPath('/org/venom/Input'),
    );
  }

  Future<bool> setLayouts(String layouts) async {
    try {
      final result = await _object.callMethod('org.venom.Input', 'SetLayouts', [
        DBusString(layouts),
      ], replySignature: DBusSignature('b'));
      return result.values[0].asBoolean();
    } catch (e) {
      return false;
    }
  }

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
      return 'us';
    }
  }
}
