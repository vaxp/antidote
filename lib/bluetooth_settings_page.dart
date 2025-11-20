import 'dart:async';
import 'dart:io';
import 'package:dbus/dbus.dart';
import 'package:flutter/material.dart';
import 'package:antidote/glassmorphic_container.dart';

class BluetoothSettingsPage extends StatelessWidget {
  const BluetoothSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: const BluetoothManagerContent(),
      ),
    );
  }
}

class BluetoothManagerContent extends StatefulWidget {
  const BluetoothManagerContent({super.key});

  @override
  State<BluetoothManagerContent> createState() => _BluetoothManagerContentState();
}

class _BluetoothManagerContentState extends State<BluetoothManagerContent> {
  late DBusClient _sysbus;
  bool _isScanning = false;
  bool _isInitializing = true;
  String? _adapterPath;
  List<Map<String, dynamic>> _devices = [];
  Timer? _scanTimer;
  final List<StreamSubscription> _bluezSubscriptions = [];
  bool _bluetoothEnabled = false;

  @override
  void initState() {
    super.initState();
    _sysbus = DBusClient.system();
    _initBluetooth();
  }

  @override
  void dispose() {
    _stopScan();
    for (final s in _bluezSubscriptions) {
      s.cancel();
    }
    _sysbus.close();
    super.dispose();
  }

  Future<void> _initBluetooth() async {
    if (!mounted) return;
    setState(() => _isInitializing = true);
    try {
      await _findAdapter();
      if (_adapterPath != null) {
        await _checkBluetoothStatus();
        await _ensureAdapterPowered();
        _listenBluezSignals();
        // Only start scanning if Bluetooth is enabled
        if (_bluetoothEnabled) {
          await _startScan();
        }
      }
    } catch (e) {
      debugPrint("Bluetooth Init Error: $e");
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Future<void> _findAdapter() async {
    try {
      final root = DBusRemoteObject(
        _sysbus,
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
          _adapterPath = path.value;
          return;
        }
      }
    } catch (e) {
      debugPrint("Find Adapter Error: $e");
    }
  }

  Future<void> _checkBluetoothStatus() async {
    try {
      // Use hardcoded path like olid.dart - more reliable
      final adapter = DBusRemoteObject(
        _sysbus,
        name: 'org.bluez',
        path: DBusObjectPath('/org/bluez/hci0'),
      );
      final powered =
          (await adapter.getProperty('org.bluez.Adapter1', 'Powered'))
              as DBusBoolean;
      if (mounted) {
        setState(() => _bluetoothEnabled = powered.value);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _bluetoothEnabled = false);
      }
    }
  }

  Future<void> _ensureAdapterPowered() async {
    if (_adapterPath == null) return;
    try {
      final adapter = DBusRemoteObject(
        _sysbus,
        name: 'org.bluez',
        path: DBusObjectPath(_adapterPath!),
      );
      var poweredVal = await adapter.getProperty(
        'org.bluez.Adapter1',
        'Powered',
      );

      bool isPowered = false;
      if (poweredVal is DBusVariant) {
        isPowered = (poweredVal.value as DBusBoolean).value;
      } else if (poweredVal is DBusBoolean) {
        isPowered = poweredVal.value;
      }

      if (mounted) {
        setState(() => _bluetoothEnabled = isPowered);
      }

      // Only try to power on if it's off - but don't fail if it errors
      if (!isPowered) {
        try {
          await adapter.setProperty(
            'org.bluez.Adapter1',
            'Powered',
            DBusBoolean(true),
          );
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            setState(() => _bluetoothEnabled = true);
          }
        } catch (e) {
          // Silently fail - user can toggle manually
          debugPrint("Power On Error (non-critical): $e");
        }
      }
    } catch (e) {
      debugPrint("Power On Error: $e");
    }
  }

  Future<void> _toggleBluetooth(bool enabled) async {
    try {
      // Use rfkill command like olid.dart - more reliable than DBus directly
      await Process.run('rfkill', [enabled ? 'unblock' : 'block', 'bluetooth']);
      await _checkBluetoothStatus();
      
      // Refresh devices after toggling
      if (_bluetoothEnabled) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _fetchDevices();
        await _startScan();
      } else {
        await _stopScan();
        if (mounted) {
          setState(() => _devices = []);
        }
      }
    } catch (_) {
      // Silently fail and re-check status
      await _checkBluetoothStatus();
    }
  }

  Future<void> _startScan() async {
    if (!mounted) return;
    if (_adapterPath == null || _isScanning) return;

    if (mounted) setState(() => _isScanning = true);
    try {
      final adapter = DBusRemoteObject(
        _sysbus,
        name: 'org.bluez',
        path: DBusObjectPath(_adapterPath!),
      );
      await adapter.callMethod('org.bluez.Adapter1', 'StartDiscovery', []);

      _fetchDevices();
      _scanTimer?.cancel();
      _scanTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => _fetchDevices(),
      );
    } catch (e) {
      if (!e.toString().contains('InProgress')) {
        debugPrint("Start Scan Error: $e");
        if (mounted) setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _stopScan() async {
    _scanTimer?.cancel();
    if (_adapterPath != null) {
      try {
        final adapter = DBusRemoteObject(
          _sysbus,
          name: 'org.bluez',
          path: DBusObjectPath(_adapterPath!),
        );
        await adapter.callMethod('org.bluez.Adapter1', 'StopDiscovery', []);
      } catch (_) {}
    }
    if (mounted) setState(() => _isScanning = false);
  }

  Future<void> _fetchDevices() async {
    if (!mounted) return;
    try {
      final root = DBusRemoteObject(
        _sysbus,
        name: 'org.bluez',
        path: DBusObjectPath.root,
      );
      final resp = await root.callMethod(
        'org.freedesktop.DBus.ObjectManager',
        'GetManagedObjects',
        [],
      );
      final returned = resp.returnValues.first as DBusDict;

      final List<Map<String, dynamic>> newDevices = [];

      DBusValue? _unwrap(DBusValue? v) {
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
        final aliasV = _unwrap(props[DBusString('Alias')]);
        final nameV = _unwrap(props[DBusString('Name')]);
        if (aliasV is DBusString) {
          name = aliasV.value;
        } else if (nameV is DBusString) {
          name = nameV.value;
        }

        String address = '??:??:??:??:??:??';
        final addrV = _unwrap(props[DBusString('Address')]);
        if (addrV is DBusString) address = addrV.value;

        bool connected = false;
        final connV = _unwrap(props[DBusString('Connected')]);
        if (connV is DBusBoolean) connected = connV.value;

        bool paired = false;
        final pairV = _unwrap(props[DBusString('Paired')]);
        if (pairV is DBusBoolean) paired = pairV.value;

        int rssi = -100;
        final rssiV = _unwrap(props[DBusString('RSSI')]);
        if (rssiV is DBusInt16) rssi = rssiV.value;

        newDevices.add({
          'path': pathStr,
          'name': name,
          'address': address,
          'connected': connected,
          'paired': paired,
          'rssi': rssi,
        });
      }

      newDevices.sort((a, b) {
        if (a['connected'] != b['connected']) return a['connected'] ? -1 : 1;
        if (a['paired'] != b['paired']) return a['paired'] ? -1 : 1;
        return (b['rssi'] as int).compareTo(a['rssi'] as int);
      });

      if (mounted) setState(() => _devices = newDevices);
    } catch (e, st) {
      debugPrint('Fetch Devices Error: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  void _listenBluezSignals() {
    _bluezSubscriptions.add(
      DBusSignalStream(
        _sysbus,
        interface: 'org.freedesktop.DBus.Properties',
        name: 'PropertiesChanged',
      ).listen((signal) {
        if (signal.path.value.contains('bluez')) _fetchDevices();
      }),
    );
    _bluezSubscriptions.add(
      DBusSignalStream(
        _sysbus,
        interface: 'org.freedesktop.DBus.ObjectManager',
        name: 'InterfacesAdded',
      ).listen((_) => _fetchDevices()),
    );
    _bluezSubscriptions.add(
      DBusSignalStream(
        _sysbus,
        interface: 'org.freedesktop.DBus.ObjectManager',
        name: 'InterfacesRemoved',
      ).listen((_) => _fetchDevices()),
    );
  }

  Future<void> _connectDevice(String path) async {
    try {
      if (_isScanning) await _stopScan();
      final device = DBusRemoteObject(
        _sysbus,
        name: 'org.bluez',
        path: DBusObjectPath(path),
      );
      await device.callMethod('org.bluez.Device1', 'Connect', []);
      _startScan();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed: ${e.toString().split(']').last.trim()}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      _startScan();
    }
  }

  Future<void> _disconnectDevice(String path) async {
    try {
      final device = DBusRemoteObject(
        _sysbus,
        name: 'org.bluez',
        path: DBusObjectPath(path),
      );
      await device.callMethod('org.bluez.Device1', 'Disconnect', []);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        const Text(
          'Bluetooth',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        // Toggle and Status
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Manage paired and nearby devices',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            Row(
              children: [
                Text(
                  _bluetoothEnabled ? 'On' : 'Off',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                Switch(
                  value: _bluetoothEnabled,
                  onChanged: (_adapterPath == null || _isInitializing)
                      ? null
                      : (value) => _toggleBluetooth(value),
                  activeColor: Colors.blueAccent,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 48),
        // Title and scan button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Nearby Devices',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (_adapterPath == null && !_isInitializing)
              const Tooltip(
                message: "No Adapter",
                child: Icon(Icons.error_outline, color: Colors.redAccent),
              ),
            if (_isScanning)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.blueAccent),
                ),
              )
            else
              IconButton(
                onPressed: (_isInitializing || _adapterPath == null || !_bluetoothEnabled)
                    ? null
                    : (_isScanning ? _stopScan : _startScan),
                icon: const Icon(Icons.refresh_rounded),
                color: _bluetoothEnabled ? Colors.white70 : Colors.white.withOpacity(0.3),
                tooltip: _isScanning ? "Stop Scanning" : "Start Scanning",
              ),
          ],
        ),
        const SizedBox(height: 24),
        // Devices list
        Expanded(
          child: _buildDevicesList(),
        ),
      ],
    );
  }

  Widget _buildDevicesList() {
    if (_isInitializing) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.blueAccent,
        ),
      );
    }

    if (!_bluetoothEnabled) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth_disabled_rounded,
              size: 48,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Bluetooth is turned off',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Turn on Bluetooth to see available devices',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth_searching_rounded,
              size: 48,
              color: Colors.white.withOpacity(0.1),
            ),
            const SizedBox(height: 16),
            Text(
              'No devices found',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _devices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final dev = _devices[index];
        final isConnected = dev['connected'] as bool;
        final isPaired = dev['paired'] as bool;

        return GestureDetector(
          onTap: (isConnected)
              ? () => _disconnectDevice(dev['path'])
              : () => _connectDevice(dev['path']),
          child: GlassmorphicContainer(
            width: double.infinity,
            height: 100,
            borderRadius: 16,
            linearGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isConnected
                  ? [
                Colors.blue.withOpacity(0.2),
                Colors.blue.withOpacity(0.1),
              ]
                  : [
                Colors.white.withOpacity(0.05),
                Colors.white.withOpacity(0.02),
              ],
            ),
            border: 1.2,
            blur: 30,
            borderGradient: const LinearGradient(colors: []),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isConnected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth,
                  color: isConnected
                      ? Colors.blue
                      : (isPaired ? Colors.white : Colors.white54),
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dev['name'],
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: isConnected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dev['address'],
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                      if (dev['rssi'] > -100)
                        Text(
                          "${dev['rssi']} dBm",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isConnected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.4),
                            width: 0.8,
                          ),
                        ),
                        child: const Text(
                          'Disconnect',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          isPaired ? 'Connect' : 'Pair',
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

