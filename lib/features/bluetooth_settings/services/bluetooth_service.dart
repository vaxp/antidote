import 'dart:async';
import 'dart:io';
import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';
import '../bloc/bluetooth_settings_event.dart';


class BluetoothService {
  DBusClient? _sysbus;
  final List<StreamSubscription> _subscriptions = [];
  Function(List<BluetoothDevice>)? onDevicesChanged;

  DBusClient get sysbus {
    _sysbus ??= DBusClient.system();
    return _sysbus!;
  }

  
  Future<String?> findAdapter() async {
    try {
      final root = DBusRemoteObject(
        sysbus,
        name: 'org.bluez',
        path: DBusObjectPath.root,
      );
      final resp = await root.callMethod(
        'org.freedesktop.DBus.ObjectManager',
        'GetManagedObjects',
        [],
      );
      final returned = resp.returnValues.first as DBusDict;

      for (final entry in returned.children.entries) {
        final path = entry.key as DBusObjectPath;
        final interfaces = entry.value as DBusDict;
        if (interfaces.children.containsKey(DBusString('org.bluez.Adapter1'))) {
          return path.value;
        }
      }
    } catch (e) {
      debugPrint("Find Adapter Error: $e");
    }
    return null;
  }

  
  Future<bool> isBluetoothEnabled() async {
    try {
      final adapter = DBusRemoteObject(
        sysbus,
        name: 'org.bluez',
        path: DBusObjectPath('/org/bluez/hci0'),
      );
      final powered =
          (await adapter.getProperty('org.bluez.Adapter1', 'Powered'))
              as DBusBoolean;
      return powered.value;
    } catch (_) {
      return false;
    }
  }

  
  Future<bool> toggleBluetooth(bool enabled) async {
    try {
      await Process.run('rfkill', [enabled ? 'unblock' : 'block', 'bluetooth']);
      await Future.delayed(const Duration(milliseconds: 500));
      return await isBluetoothEnabled();
    } catch (e) {
      debugPrint("Toggle Bluetooth Error: $e");
      return false;
    }
  }

  
  Future<bool> startScan(String adapterPath) async {
    try {
      final adapter = DBusRemoteObject(
        sysbus,
        name: 'org.bluez',
        path: DBusObjectPath(adapterPath),
      );
      await adapter.callMethod('org.bluez.Adapter1', 'StartDiscovery', []);
      return true;
    } catch (e) {
      if (!e.toString().contains('InProgress')) {
        debugPrint("Start Scan Error: $e");
        return false;
      }
      return true; 
    }
  }

  
  Future<void> stopScan(String adapterPath) async {
    try {
      final adapter = DBusRemoteObject(
        sysbus,
        name: 'org.bluez',
        path: DBusObjectPath(adapterPath),
      );
      await adapter.callMethod('org.bluez.Adapter1', 'StopDiscovery', []);
    } catch (_) {}
  }

  
  Future<List<BluetoothDevice>> fetchDevices() async {
    try {
      final root = DBusRemoteObject(
        sysbus,
        name: 'org.bluez',
        path: DBusObjectPath.root,
      );
      final resp = await root.callMethod(
        'org.freedesktop.DBus.ObjectManager',
        'GetManagedObjects',
        [],
      );
      final returned = resp.returnValues.first as DBusDict;

      final List<BluetoothDevice> devices = [];

      DBusValue? unwrap(DBusValue? v) {
        if (v == null) return null;
        if (v is DBusVariant) return v.value;
        return v;
      }

      for (final entry in returned.children.entries) {
        final key = entry.key;
        final value = entry.value;

        if (key is! DBusObjectPath || value is! DBusDict) continue;
        final pathStr = key.value;
        final interfaces = value;

        final deviceIface =
            interfaces.children[DBusString('org.bluez.Device1')];
        if (deviceIface == null || deviceIface is! DBusDict) continue;

        final props = deviceIface.children;

        String name = 'Unknown Device';
        final aliasV = unwrap(props[DBusString('Alias')]);
        final nameV = unwrap(props[DBusString('Name')]);
        if (aliasV is DBusString) {
          name = aliasV.value;
        } else if (nameV is DBusString) {
          name = nameV.value;
        }

        String address = '??:??:??:??:??:??';
        final addrV = unwrap(props[DBusString('Address')]);
        if (addrV is DBusString) address = addrV.value;

        bool connected = false;
        final connV = unwrap(props[DBusString('Connected')]);
        if (connV is DBusBoolean) connected = connV.value;

        bool paired = false;
        final pairV = unwrap(props[DBusString('Paired')]);
        if (pairV is DBusBoolean) paired = pairV.value;

        int rssi = -100;
        final rssiV = unwrap(props[DBusString('RSSI')]);
        if (rssiV is DBusInt16) rssi = rssiV.value;

        devices.add(
          BluetoothDevice(
            path: pathStr,
            name: name,
            address: address,
            connected: connected,
            paired: paired,
            rssi: rssi,
          ),
        );
      }

      
      devices.sort((a, b) {
        if (a.connected != b.connected) return a.connected ? -1 : 1;
        if (a.paired != b.paired) return a.paired ? -1 : 1;
        return b.rssi.compareTo(a.rssi);
      });

      return devices;
    } catch (e) {
      debugPrint('Fetch Devices Error: $e');
      return [];
    }
  }

  
  Future<bool> connectDevice(String path) async {
    try {
      final device = DBusRemoteObject(
        sysbus,
        name: 'org.bluez',
        path: DBusObjectPath(path),
      );
      await device.callMethod('org.bluez.Device1', 'Connect', []);
      return true;
    } catch (e) {
      debugPrint("Connect Device Error: $e");
      return false;
    }
  }

  
  Future<bool> disconnectDevice(String path) async {
    try {
      final device = DBusRemoteObject(
        sysbus,
        name: 'org.bluez',
        path: DBusObjectPath(path),
      );
      await device.callMethod('org.bluez.Device1', 'Disconnect', []);
      return true;
    } catch (_) {
      return false;
    }
  }

  
  void listenToSignals() {
    _subscriptions.add(
      DBusSignalStream(
        sysbus,
        interface: 'org.freedesktop.DBus.Properties',
        name: 'PropertiesChanged',
      ).listen((signal) async {
        if (signal.path.value.contains('bluez')) {
          onDevicesChanged?.call(await fetchDevices());
        }
      }),
    );
    _subscriptions.add(
      DBusSignalStream(
        sysbus,
        interface: 'org.freedesktop.DBus.ObjectManager',
        name: 'InterfacesAdded',
      ).listen((_) async {
        onDevicesChanged?.call(await fetchDevices());
      }),
    );
    _subscriptions.add(
      DBusSignalStream(
        sysbus,
        interface: 'org.freedesktop.DBus.ObjectManager',
        name: 'InterfacesRemoved',
      ).listen((_) async {
        onDevicesChanged?.call(await fetchDevices());
      }),
    );
  }

  
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();
    _sysbus?.close();
    _sysbus = null;
  }
}
