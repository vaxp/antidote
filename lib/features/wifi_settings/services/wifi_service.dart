import 'dart:async';
import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../bloc/wifi_settings_event.dart';

/// Service class that handles all DBus calls for WiFi settings via NetworkManager
class WiFiService {
  DBusClient? _bus;

  DBusClient get bus {
    _bus ??= DBusClient.system();
    return _bus!;
  }

  /// Check if WiFi is enabled
  Future<bool> isWiFiEnabled() async {
    try {
      final nm = DBusRemoteObject(
        bus,
        name: 'org.freedesktop.NetworkManager',
        path: DBusObjectPath('/org/freedesktop/NetworkManager'),
      );

      final wifiEnabled = await nm.getProperty(
        'org.freedesktop.NetworkManager',
        'WirelessEnabled',
      );

      return (wifiEnabled as DBusBoolean).value;
    } catch (e) {
      debugPrint('Check WiFi status error: $e');
      return false;
    }
  }

  /// Toggle WiFi on/off
  Future<bool> toggleWiFi(bool enabled) async {
    try {
      final nm = DBusRemoteObject(
        bus,
        name: 'org.freedesktop.NetworkManager',
        path: DBusObjectPath('/org/freedesktop/NetworkManager'),
      );

      await nm.setProperty(
        'org.freedesktop.NetworkManager',
        'WirelessEnabled',
        DBusBoolean(enabled),
      );

      return enabled;
    } catch (e) {
      debugPrint('Toggle WiFi error: $e');
      return !enabled;
    }
  }

  /// Check if WiFi is available
  Future<bool> isWiFiAvailable() async {
    try {
      final nm = DBusRemoteObject(
        bus,
        name: 'org.freedesktop.NetworkManager',
        path: DBusObjectPath('/org/freedesktop/NetworkManager'),
      );

      final wifiEnabled = await nm.getProperty(
        'org.freedesktop.NetworkManager',
        'WirelessEnabled',
      );

      if (!(wifiEnabled as DBusBoolean).value) {
        return false;
      }

      final devices = await nm.callMethod(
        'org.freedesktop.NetworkManager',
        'GetDevices',
        [],
        replySignature: DBusSignature('ao'),
      );

      for (final devicePath in (devices.values[0] as DBusArray).children) {
        final device = DBusRemoteObject(
          bus,
          name: 'org.freedesktop.NetworkManager',
          path: DBusObjectPath((devicePath as DBusObjectPath).value),
        );

        final deviceType = await device.getProperty(
          'org.freedesktop.NetworkManager.Device',
          'DeviceType',
        );

        if ((deviceType as DBusUint32).value == 2) {
          final state = await device.getProperty(
            'org.freedesktop.NetworkManager.Device',
            'State',
          );
          final stateValue = (state as DBusUint32).value;
          if (stateValue == 100 || stateValue == 30) {
            return true;
          }
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Fetch all available networks
  Future<List<WiFiNetwork>> fetchNetworks() async {
    try {
      final nm = DBusRemoteObject(
        bus,
        name: 'org.freedesktop.NetworkManager',
        path: DBusObjectPath('/org/freedesktop/NetworkManager'),
      );

      final devices = await nm.callMethod(
        'org.freedesktop.NetworkManager',
        'GetDevices',
        [],
        replySignature: DBusSignature('ao'),
      );

      final List<WiFiNetwork> networks = [];
      final devicePaths = (devices.values[0] as DBusArray).children;

      for (final devicePath in devicePaths) {
        final device = DBusRemoteObject(
          bus,
          name: 'org.freedesktop.NetworkManager',
          path: DBusObjectPath((devicePath as DBusObjectPath).value),
        );

        final deviceType = await device.getProperty(
          'org.freedesktop.NetworkManager.Device',
          'DeviceType',
        );

        if ((deviceType as DBusUint32).value != 2) continue;

        final aps = await device.callMethod(
          'org.freedesktop.NetworkManager.Device.Wireless',
          'GetAccessPoints',
          [],
          replySignature: DBusSignature('ao'),
        );

        final activeAp = await device.getProperty(
          'org.freedesktop.NetworkManager.Device.Wireless',
          'ActiveAccessPoint',
        );
        final activeApPath = (activeAp as DBusObjectPath).value;

        // Get saved connections
        final settings = DBusRemoteObject(
          bus,
          name: 'org.freedesktop.NetworkManager',
          path: DBusObjectPath('/org/freedesktop/NetworkManager/Settings'),
        );

        final conns = await settings.callMethod(
          'org.freedesktop.NetworkManager.Settings',
          'ListConnections',
          [],
          replySignature: DBusSignature('ao'),
        );
        final savedConns = <String>{};

        for (final conn in (conns.values[0] as DBusArray).children) {
          final connObj = DBusRemoteObject(
            bus,
            name: 'org.freedesktop.NetworkManager',
            path: DBusObjectPath((conn as DBusObjectPath).value),
          );

          final settingsMap = await connObj.callMethod(
            'org.freedesktop.NetworkManager.Settings.Connection',
            'GetSettings',
            [],
            replySignature: DBusSignature('a{sa{sv}}'),
          );

          final wirelessSettings =
              (settingsMap.values[0] as DBusDict).children['802-11-wireless'];
          if (wirelessSettings != null) {
            final ssid =
                ((wirelessSettings as DBusDict).children['ssid'] as DBusArray)
                    .children;
            final ssidStr = String.fromCharCodes(
              ssid.map((e) => (e as DBusByte).value),
            );
            savedConns.add(ssidStr);
          }
        }

        for (final ap in (aps.values[0] as DBusArray).children) {
          final apPath = (ap as DBusObjectPath).value;
          final apObj = DBusRemoteObject(
            bus,
            name: 'org.freedesktop.NetworkManager',
            path: DBusObjectPath(apPath),
          );

          final ssidBytes = await apObj.getProperty(
            'org.freedesktop.NetworkManager.AccessPoint',
            'Ssid',
          );
          final strength = await apObj.getProperty(
            'org.freedesktop.NetworkManager.AccessPoint',
            'Strength',
          );
          final flags = await apObj.getProperty(
            'org.freedesktop.NetworkManager.AccessPoint',
            'Flags',
          );
          final wpaFlags = await apObj.getProperty(
            'org.freedesktop.NetworkManager.AccessPoint',
            'WpaFlags',
          );
          final rsnFlags = await apObj.getProperty(
            'org.freedesktop.NetworkManager.AccessPoint',
            'RsnFlags',
          );

          final ssid = String.fromCharCodes(
            (ssidBytes as DBusArray).children.map((e) => (e as DBusByte).value),
          );

          if (ssid.isEmpty) continue;

          final isSecure =
              (flags as DBusUint32).value > 0 ||
              (wpaFlags as DBusUint32).value > 0 ||
              (rsnFlags as DBusUint32).value > 0;

          networks.add(
            WiFiNetwork(
              ssid: ssid,
              strength: (strength as DBusByte).value,
              isSecure: isSecure,
              isConnected: apPath == activeApPath,
              isSaved: savedConns.contains(ssid),
            ),
          );
        }
      }

      networks.sort((a, b) {
        if (a.isConnected != b.isConnected) {
          return a.isConnected ? -1 : 1;
        }
        if (a.isSaved != b.isSaved) {
          return a.isSaved ? -1 : 1;
        }
        return b.strength.compareTo(a.strength);
      });

      return networks;
    } catch (e) {
      debugPrint('Fetch networks error: $e');
      return [];
    }
  }

  /// Request WiFi scan
  Future<bool> startScan() async {
    try {
      if (!await isWiFiAvailable()) {
        return false;
      }

      final nm = DBusRemoteObject(
        bus,
        name: 'org.freedesktop.NetworkManager',
        path: DBusObjectPath('/org/freedesktop/NetworkManager'),
      );

      final devices = await nm.callMethod(
        'org.freedesktop.NetworkManager',
        'GetDevices',
        [],
        replySignature: DBusSignature('ao'),
      );

      for (final devicePath in (devices.values[0] as DBusArray).children) {
        final device = DBusRemoteObject(
          bus,
          name: 'org.freedesktop.NetworkManager',
          path: DBusObjectPath((devicePath as DBusObjectPath).value),
        );

        final deviceType = await device.getProperty(
          'org.freedesktop.NetworkManager.Device',
          'DeviceType',
        );

        if ((deviceType as DBusUint32).value == 2) {
          final state = await device.getProperty(
            'org.freedesktop.NetworkManager.Device',
            'State',
          );
          final stateValue = (state as DBusUint32).value;

          if (stateValue == 100 || stateValue == 30) {
            try {
              await device.callMethod(
                'org.freedesktop.NetworkManager.Device.Wireless',
                'RequestScan',
                [DBusDict.stringVariant({})],
              );
            } catch (e) {
              debugPrint('Scan request failed: $e');
            }
          }
        }
      }

      await Future.delayed(const Duration(seconds: 2));
      return true;
    } catch (e) {
      debugPrint('Start scan error: $e');
      return false;
    }
  }

  /// Connect to a network
  Future<bool> connectToNetwork(WiFiNetwork network, String? password) async {
    try {
      final nm = DBusRemoteObject(
        bus,
        name: 'org.freedesktop.NetworkManager',
        path: DBusObjectPath('/org/freedesktop/NetworkManager'),
      );

      if (!network.isSaved && network.isSecure) {
        if (password == null) return false;

        final conn = {
          'connection': {
            'type': const DBusString('802-11-wireless'),
            'id': DBusString(network.ssid),
            'uuid': DBusString(const Uuid().v4()),
            'autoconnect': const DBusBoolean(true),
          },
          '802-11-wireless': {
            'ssid': DBusArray.byte(network.ssid.codeUnits),
            'mode': const DBusString('infrastructure'),
            'security': const DBusString('802-11-wireless-security'),
          },
          '802-11-wireless-security': {
            'key-mgmt': const DBusString('wpa-psk'),
            'auth-alg': const DBusString('open'),
            'psk': DBusString(password),
          },
          'ipv4': {'method': const DBusString('auto')},
          'ipv6': {'method': const DBusString('auto')},
        };

        final nmSettings = DBusRemoteObject(
          bus,
          name: 'org.freedesktop.NetworkManager',
          path: DBusObjectPath('/org/freedesktop/NetworkManager/Settings'),
        );

        final connectionData = DBusDict(
          DBusSignature('s'),
          DBusSignature('a{sv}'),
          conn.map(
            (key, value) => MapEntry(
              DBusString(key),
              DBusDict(
                DBusSignature('s'),
                DBusSignature('v'),
                value.map((k, v) => MapEntry(DBusString(k), DBusVariant(v))),
              ),
            ),
          ),
        );

        await nmSettings.callMethod(
          'org.freedesktop.NetworkManager.Settings',
          'AddConnection',
          [connectionData],
          replySignature: DBusSignature('o'),
        );
      }

      final settings = DBusRemoteObject(
        bus,
        name: 'org.freedesktop.NetworkManager',
        path: DBusObjectPath('/org/freedesktop/NetworkManager/Settings'),
      );

      final conns = await settings.callMethod(
        'org.freedesktop.NetworkManager.Settings',
        'ListConnections',
        [],
        replySignature: DBusSignature('ao'),
      );

      String? connPath;
      for (final conn in (conns.values[0] as DBusArray).children) {
        final connSettings = DBusRemoteObject(
          bus,
          name: 'org.freedesktop.NetworkManager',
          path: DBusObjectPath((conn as DBusObjectPath).value),
        );

        final settingsMap = await connSettings.callMethod(
          'org.freedesktop.NetworkManager.Settings.Connection',
          'GetSettings',
          [],
          replySignature: DBusSignature('a{sa{sv}}'),
        );

        final wirelessSettings =
            (settingsMap.values[0] as DBusDict).children['802-11-wireless'];
        if (wirelessSettings != null) {
          final ssid =
              ((wirelessSettings as DBusDict).children['ssid'] as DBusArray)
                  .children;
          final ssidStr = String.fromCharCodes(
            ssid.map((e) => (e as DBusByte).value),
          );
          if (ssidStr == network.ssid) {
            connPath = conn.value;
            break;
          }
        }
      }

      if (connPath != null) {
        await nm.callMethod(
          'org.freedesktop.NetworkManager',
          'ActivateConnection',
          [DBusObjectPath(connPath), DBusObjectPath('/'), DBusObjectPath('/')],
          replySignature: DBusSignature('o'),
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Connect error: $e');
      return false;
    }
  }

  /// Forget a saved network
  Future<bool> forgetNetwork(WiFiNetwork network) async {
    try {
      final nm = DBusRemoteObject(
        bus,
        name: 'org.freedesktop.NetworkManager',
        path: DBusObjectPath('/org/freedesktop/NetworkManager'),
      );

      final conns = await nm.callMethod(
        'org.freedesktop.NetworkManager',
        'GetConnections',
        [],
        replySignature: DBusSignature('ao'),
      );

      for (final conn in (conns.values[0] as DBusArray).children) {
        final settings = DBusRemoteObject(
          bus,
          name: 'org.freedesktop.NetworkManager',
          path: DBusObjectPath((conn as DBusObjectPath).value),
        );

        final settingsMap = await settings.callMethod(
          'org.freedesktop.NetworkManager.Settings.Connection',
          'GetSettings',
          [],
          replySignature: DBusSignature('a{sa{sv}}'),
        );

        final wirelessSettings =
            (settingsMap.values[0] as DBusDict).children['802-11-wireless'];
        if (wirelessSettings != null) {
          final ssid =
              ((wirelessSettings as DBusDict).children['ssid'] as DBusArray)
                  .children;
          final ssidStr = String.fromCharCodes(
            ssid.map((e) => (e as DBusByte).value),
          );
          if (ssidStr == network.ssid) {
            await settings.callMethod(
              'org.freedesktop.NetworkManager.Settings.Connection',
              'Delete',
              [],
            );
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      debugPrint('Forget network error: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _bus?.close();
    _bus = null;
  }
}
