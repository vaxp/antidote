import 'package:dbus/dbus.dart';

/// خدمة الاتصال بـ Venom Power Daemon عبر D-Bus
class PowerService {
  static const String serviceName = 'org.venom.Power';
  static const String objectPath = '/org/venom/Power';
  static const String interfaceName = 'org.venom.Power';

  late DBusClient _client;
  late DBusRemoteObject _object;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  /// الاتصال بالعفريت
  Future<bool> connect() async {
    try {
      _client = DBusClient.session();
      _object = DBusRemoteObject(
        _client,
        name: serviceName,
        path: DBusObjectPath(objectPath),
      );
      _isConnected = true;
      return true;
    } catch (e) {
      print('Error connecting to Power daemon: $e');
      _isConnected = false;
      return false;
    }
  }

  /// قطع الاتصال
  Future<void> disconnect() async {
    if (_isConnected) {
      await _client.close();
      _isConnected = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ⚡ أوامر الطاقة
  // ═══════════════════════════════════════════════════════════════════════════

  Future<bool> shutdown() async {
    try {
      final result = await _object.callMethod(interfaceName, 'Shutdown', []);
      return result.values.first.asBoolean();
    } catch (e) {
      print('Shutdown error: $e');
      return false;
    }
  }

  Future<bool> reboot() async {
    try {
      final result = await _object.callMethod(interfaceName, 'Reboot', []);
      return result.values.first.asBoolean();
    } catch (e) {
      print('Reboot error: $e');
      return false;
    }
  }

  Future<bool> suspend() async {
    try {
      final result = await _object.callMethod(interfaceName, 'Suspend', []);
      return result.values.first.asBoolean();
    } catch (e) {
      print('Suspend error: $e');
      return false;
    }
  }

  Future<bool> hibernate() async {
    try {
      final result = await _object.callMethod(interfaceName, 'Hibernate', []);
      return result.values.first.asBoolean();
    } catch (e) {
      print('Hibernate error: $e');
      return false;
    }
  }

  Future<bool> logout() async {
    try {
      final result = await _object.callMethod(interfaceName, 'Logout', []);
      return result.values.first.asBoolean();
    } catch (e) {
      print('Logout error: $e');
      return false;
    }
  }

  Future<bool> lockScreen() async {
    try {
      final result = await _object.callMethod(interfaceName, 'LockScreen', []);
      return result.values.first.asBoolean();
    } catch (e) {
      print('LockScreen error: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 💡 سطوع الشاشة
  // ═══════════════════════════════════════════════════════════════════════════

  Future<int> getBrightness() async {
    try {
      final result = await _object.callMethod(
        interfaceName,
        'GetBrightness',
        [],
      );
      return result.values.first.asInt32();
    } catch (e) {
      print('GetBrightness error: $e');
      return -1;
    }
  }

  Future<bool> setBrightness(int level) async {
    try {
      final result = await _object.callMethod(interfaceName, 'SetBrightness', [
        DBusInt32(level),
      ]);
      return result.values.first.asBoolean();
    } catch (e) {
      print('SetBrightness error: $e');
      return false;
    }
  }

  Future<int> getMaxBrightness() async {
    try {
      final result = await _object.callMethod(
        interfaceName,
        'GetMaxBrightness',
        [],
      );
      return result.values.first.asInt32();
    } catch (e) {
      print('GetMaxBrightness error: $e');
      return -1;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ⌨️ إضاءة الكيبورد
  // ═══════════════════════════════════════════════════════════════════════════

  Future<bool> isKeyboardBacklightSupported() async {
    try {
      final result = await _object.callMethod(
        interfaceName,
        'IsKeyboardBacklightSupported',
        [],
      );
      return result.values.first.asBoolean();
    } catch (e) {
      print('IsKeyboardBacklightSupported error: $e');
      return false;
    }
  }

  Future<int> getKeyboardBrightness() async {
    try {
      final result = await _object.callMethod(
        interfaceName,
        'GetKeyboardBrightness',
        [],
      );
      return result.values.first.asInt32();
    } catch (e) {
      print('GetKeyboardBrightness error: $e');
      return -1;
    }
  }

  Future<bool> setKeyboardBrightness(int level) async {
    try {
      final result = await _object.callMethod(
        interfaceName,
        'SetKeyboardBrightness',
        [DBusInt32(level)],
      );
      return result.values.first.asBoolean();
    } catch (e) {
      print('SetKeyboardBrightness error: $e');
      return false;
    }
  }

  Future<int> getKeyboardMaxBrightness() async {
    try {
      final result = await _object.callMethod(
        interfaceName,
        'GetKeyboardMaxBrightness',
        [],
      );
      return result.values.first.asInt32();
    } catch (e) {
      print('GetKeyboardMaxBrightness error: $e');
      return -1;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔋 البطارية
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getBatteryInfo() async {
    try {
      final result = await _object.callMethod(
        interfaceName,
        'GetBatteryInfo',
        [],
      );
      return {
        'percentage': result.values[0].asDouble(),
        'charging': result.values[1].asBoolean(),
        'timeToEmpty': result.values[2].asInt64(),
      };
    } catch (e) {
      print('GetBatteryInfo error: $e');
      return {'percentage': 0.0, 'charging': false, 'timeToEmpty': 0};
    }
  }

  Future<bool> isOnBattery() async {
    try {
      final result = await _object.callMethod(
        interfaceName,
        'GetPowerSource',
        [],
      );
      return result.values.first.asBoolean();
    } catch (e) {
      print('GetPowerSource error: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 💻 حالة الأجهزة
  // ═══════════════════════════════════════════════════════════════════════════

  Future<bool> getLidState() async {
    try {
      final result = await _object.callMethod(interfaceName, 'GetLidState', []);
      return result.values.first.asBoolean();
    } catch (e) {
      print('GetLidState error: $e');
      return false;
    }
  }

  Future<Map<String, bool>> getIdleState() async {
    try {
      final result = await _object.callMethod(
        interfaceName,
        'GetIdleState',
        [],
      );
      return {
        'isIdle': result.values[0].asBoolean(),
        'screenDimmed': result.values[1].asBoolean(),
        'screenBlanked': result.values[2].asBoolean(),
      };
    } catch (e) {
      print('GetIdleState error: $e');
      return {'isIdle': false, 'screenDimmed': false, 'screenBlanked': false};
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ⏰ إعدادات الخمول
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Map<String, int>> getIdleTimeouts() async {
    try {
      final result = await _object.callMethod(
        interfaceName,
        'GetIdleTimeouts',
        [],
      );
      return {
        'dim': result.values[0].asUint32(),
        'blank': result.values[1].asUint32(),
        'suspend': result.values[2].asUint32(),
      };
    } catch (e) {
      print('GetIdleTimeouts error: $e');
      return {'dim': 0, 'blank': 0, 'suspend': 0};
    }
  }

  Future<void> setIdleTimeouts(int dim, int blank, int suspend) async {
    try {
      await _object.callMethod(interfaceName, 'SetIdleTimeouts', [
        DBusUint32(dim),
        DBusUint32(blank),
        DBusUint32(suspend),
      ]);
    } catch (e) {
      print('SetIdleTimeouts error: $e');
    }
  }

  Future<void> simulateActivity() async {
    try {
      await _object.callMethod(interfaceName, 'SimulateActivity', []);
    } catch (e) {
      print('SimulateActivity error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🚫 نظام المنع
  // ═══════════════════════════════════════════════════════════════════════════

  Future<int> inhibit(String what, String who, String why) async {
    try {
      final result = await _object.callMethod(interfaceName, 'Inhibit', [
        DBusString(what),
        DBusString(who),
        DBusString(why),
      ]);
      return result.values.first.asUint32();
    } catch (e) {
      print('Inhibit error: $e');
      return 0;
    }
  }

  Future<void> unInhibit(int cookie) async {
    try {
      await _object.callMethod(interfaceName, 'UnInhibit', [
        DBusUint32(cookie),
      ]);
    } catch (e) {
      print('UnInhibit error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ⚙️ الإعدادات
  // ═══════════════════════════════════════════════════════════════════════════

  Future<bool> saveConfig() async {
    try {
      final result = await _object.callMethod(interfaceName, 'SaveConfig', []);
      return result.values.first.asBoolean();
    } catch (e) {
      print('SaveConfig error: $e');
      return false;
    }
  }

  Future<bool> reloadConfig() async {
    try {
      final result = await _object.callMethod(
        interfaceName,
        'ReloadConfig',
        [],
      );
      return result.values.first.asBoolean();
    } catch (e) {
      print('ReloadConfig error: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ℹ️ معلومات العفريت
  // ═══════════════════════════════════════════════════════════════════════════

  Future<String> getVersion() async {
    try {
      final result = await _object.callMethod(interfaceName, 'GetVersion', []);
      return result.values.first.asString();
    } catch (e) {
      print('GetVersion error: $e');
      return 'Unknown';
    }
  }

  Future<List<String>> getCapabilities() async {
    try {
      final result = await _object.callMethod(
        interfaceName,
        'GetCapabilities',
        [],
      );
      final array = result.values.first as DBusArray;
      return array.children.map((v) => v.asString()).toList();
    } catch (e) {
      print('GetCapabilities error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📢 الاشتراك في الإشارات
  // ═══════════════════════════════════════════════════════════════════════════

  Stream<DBusSignal> _subscribeToSignal(String signalName) {
    return DBusSignalStream(
      _client,
      sender: serviceName,
      interface: interfaceName,
      name: signalName,
      path: DBusObjectPath(objectPath),
    );
  }

  Stream<Map<String, dynamic>> get batteryChangedStream {
    return _subscribeToSignal('BatteryChanged').map((signal) {
      return {
        'percentage': signal.values[0].asDouble(),
        'charging': signal.values[1].asBoolean(),
      };
    });
  }

  Stream<Map<String, int>> get idleTimeoutsChangedStream {
    return _subscribeToSignal('IdleTimeoutsChanged').map((signal) {
      return {
        'dim': signal.values[0].asUint32(),
        'blank': signal.values[1].asUint32(),
        'suspend': signal.values[2].asUint32(),
      };
    });
  }

  Stream<double> get batteryWarningStream {
    return _subscribeToSignal(
      'BatteryWarning',
    ).map((signal) => signal.values.first.asDouble());
  }

  Stream<bool> get lidStateStream {
    return _subscribeToSignal(
      'LidStateChanged',
    ).map((signal) => signal.values.first.asBoolean());
  }

  Stream<bool> get powerSourceStream {
    return _subscribeToSignal(
      'PowerSourceChanged',
    ).map((signal) => signal.values.first.asBoolean());
  }

  Stream<int> get brightnessStream {
    return _subscribeToSignal(
      'BrightnessChanged',
    ).map((signal) => signal.values.first.asInt32());
  }

  Stream<bool> get screenDimmedStream {
    return _subscribeToSignal(
      'ScreenDimmed',
    ).map((signal) => signal.values.first.asBoolean());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ⚡ بروفايلات الطاقة
  // ═══════════════════════════════════════════════════════════════════════════

  Future<bool> isProfilesAvailable() async {
    try {
      final result = await _object.callMethod(
        interfaceName,
        'IsProfilesAvailable',
        [],
      );
      return result.values.first.asBoolean();
    } catch (e) {
      print('IsProfilesAvailable error: $e');
      return false;
    }
  }

  Future<String> getActiveProfile() async {
    try {
      final result = await _object.callMethod(
        interfaceName,
        'GetActiveProfile',
        [],
      );
      return result.values.first.asString();
    } catch (e) {
      print('GetActiveProfile error: $e');
      return 'unknown';
    }
  }

  Future<bool> setActiveProfile(String profile) async {
    try {
      final result = await _object.callMethod(
        interfaceName,
        'SetActiveProfile',
        [DBusString(profile)],
      );
      return result.values.first.asBoolean();
    } catch (e) {
      print('SetActiveProfile error: $e');
      return false;
    }
  }

  Future<List<String>> getProfiles() async {
    try {
      final result = await _object.callMethod(interfaceName, 'GetProfiles', []);
      final array = result.values.first as DBusArray;
      return array.children.map((v) => v.asString()).toList();
    } catch (e) {
      print('GetProfiles error: $e');
      return [];
    }
  }

  Future<String> getPerformanceInhibited() async {
    try {
      final result = await _object.callMethod(
        interfaceName,
        'GetPerformanceInhibited',
        [],
      );
      return result.values.first.asString();
    } catch (e) {
      print('GetPerformanceInhibited error: $e');
      return '';
    }
  }

  Stream<String> get profileChangedStream {
    return _subscribeToSignal(
      'ProfileChanged',
    ).map((signal) => signal.values.first.asString());
  }
}
