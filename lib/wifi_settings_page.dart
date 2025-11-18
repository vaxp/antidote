import 'package:flutter/material.dart';
import 'package:antidote/wifi_manager_dialog.dart';
import 'package:dbus/dbus.dart';
import 'package:uuid/uuid.dart';
import 'package:antidote/glassmorphic_container.dart';

class WiFiSettingsPage extends StatelessWidget {
  const WiFiSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: const WiFiManagerContent(),
      ),
    );
  }
}

// Extract the content from WiFiManagerDialog
class WiFiManagerContent extends StatefulWidget {
  const WiFiManagerContent({super.key});

  @override
  State<WiFiManagerContent> createState() => _WiFiManagerContentState();
}

class _WiFiManagerContentState extends State<WiFiManagerContent> {
  late DBusClient _bus;
  List<WiFiNetwork> _networks = [];
  bool _isScanning = false;
  bool _isLoading = true;
  String? _connectingTo;
  String? _error;
  bool _wifiEnabled = true;

  @override
  void initState() {
    super.initState();
    _bus = DBusClient.system();
    _initNetworks();
  }

  @override
  void dispose() {
    _bus.close();
    super.dispose();
  }

  Future<void> _initNetworks() async {
    try {
      await _checkWifiStatus();
      await _fetchNetworks();
      // Only start scanning if Wi-Fi is enabled and available
      if (await _isWifiAvailable()) {
        await _startScanning();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to initialize: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkWifiStatus() async {
    try {
      final nm = DBusRemoteObject(
        _bus,
        name: 'org.freedesktop.NetworkManager',
        path: DBusObjectPath('/org/freedesktop/NetworkManager'),
      );

      final wifiEnabled = await nm.getProperty(
        'org.freedesktop.NetworkManager',
        'WirelessEnabled',
      );

      if (mounted) {
        setState(() {
          _wifiEnabled = (wifiEnabled as DBusBoolean).value;
        });
      }
    } catch (e) {
      debugPrint('Check WiFi status error: $e');
    }
  }

  Future<void> _toggleWifi(bool enabled) async {
    try {
      final nm = DBusRemoteObject(
        _bus,
        name: 'org.freedesktop.NetworkManager',
        path: DBusObjectPath('/org/freedesktop/NetworkManager'),
      );

      await nm.setProperty(
        'org.freedesktop.NetworkManager',
        'WirelessEnabled',
        DBusBoolean(enabled),
      );

      if (mounted) {
        setState(() {
          _wifiEnabled = enabled;
        });
      }

      // Refresh networks after toggling
      if (enabled) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _fetchNetworks();
        if (await _isWifiAvailable()) {
          await _startScanning();
        }
      } else {
        if (mounted) {
          setState(() {
            _networks = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to toggle Wi-Fi: $e';
        });
      }
    }
  }

  Future<bool> _isWifiAvailable() async {
    try {
      final nm = DBusRemoteObject(
        _bus,
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
          _bus,
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
          // State 100 means the device is available/connected
          // State 30 means the device is disconnected but available
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

  Future<void> _fetchNetworks() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final nm = DBusRemoteObject(
        _bus,
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
          _bus,
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

        final settings = DBusRemoteObject(
          _bus,
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
            _bus,
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
            _bus,
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

      if (mounted) {
        setState(() {
          _networks = networks;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to fetch networks: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startScanning() async {
    try {
      if (_isScanning) return;
      
      // Check if Wi-Fi is available before scanning
      if (!await _isWifiAvailable()) {
        if (mounted) {
          setState(() {
            _error = 'Wi-Fi is not available. Please enable Wi-Fi first.';
            _isLoading = false;
          });
        }
        return;
      }

      setState(() => _isScanning = true);

      final nm = DBusRemoteObject(
        _bus,
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
          _bus,
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
          
          // Only scan if device is available (state 100 or 30)
          if (stateValue == 100 || stateValue == 30) {
            try {
              await device.callMethod(
                'org.freedesktop.NetworkManager.Device.Wireless',
                'RequestScan',
                [DBusDict.stringVariant({})],
              );
            } catch (e) {
              // If scan fails, just continue - might already be scanning
              debugPrint('Scan request failed: $e');
            }
          }
        }
      }

      await Future.delayed(const Duration(seconds: 2));
      await _fetchNetworks();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to scan: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _connectToNetwork(WiFiNetwork network) async {
    if (_connectingTo != null) return;
    setState(() {
      _connectingTo = network.ssid;
      _error = null;
    });

    try {
      final nm = DBusRemoteObject(
        _bus,
        name: 'org.freedesktop.NetworkManager',
        path: DBusObjectPath('/org/freedesktop/NetworkManager'),
      );

      if (!network.isSaved && network.isSecure) {
        final password = await _showPasswordDialog();
        if (password == null) {
          setState(() => _connectingTo = null);
          return;
        }

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
          'ipv4': {
            'method': const DBusString('auto'),
          },
          'ipv6': {
            'method': const DBusString('auto'),
          },
        };

        final nmSettings = DBusRemoteObject(
          _bus,
          name: 'org.freedesktop.NetworkManager',
          path: DBusObjectPath('/org/freedesktop/NetworkManager/Settings'),
        );

        final connectionData = DBusDict(
          DBusSignature('s'),
          DBusSignature('a{sv}'),
          conn.map((key, value) => MapEntry(
            DBusString(key),
            DBusDict(
              DBusSignature('s'),
              DBusSignature('v'),
              value.map(
                (k, v) => MapEntry(DBusString(k), DBusVariant(v)),
              ),
            ),
          )),
        );

        await nmSettings.callMethod(
          'org.freedesktop.NetworkManager.Settings',
          'AddConnection',
          [connectionData],
          replySignature: DBusSignature('o'),
        );
      }

      final settings = DBusRemoteObject(
        _bus,
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
        final settings = DBusRemoteObject(
          _bus,
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

        await _fetchNetworks();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to connect: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _connectingTo = null);
      }
    }
  }

  Future<void> _forgetNetwork(WiFiNetwork network) async {
    try {
      final nm = DBusRemoteObject(
        _bus,
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
          _bus,
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
            break;
          }
        }
      }

      await _fetchNetworks();
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to forget network: $e');
      }
    }
  }

  Future<String?> _showPasswordDialog() {
    return showDialog<String>(
      context: context,
      builder: (context) {
        String? password;
        bool obscureText = true;

        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 18, 22, 32),
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Enter Password',
            style: TextStyle(color: Colors.white),
          ),
          content: StatefulBuilder(
            builder: (context, setState) => TextField(
              onChanged: (value) => password = value,
              obscureText: obscureText,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Network Password',
                hintStyle: const TextStyle(color: Colors.white54),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white54,
                  ),
                  onPressed: () => setState(() => obscureText = !obscureText),
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.tealAccent),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, password),
              child: const Text(
                'Connect',
                style: TextStyle(color: Colors.tealAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        const Text(
          'Wi-Fi',
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
              'Manage wireless networks',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            Row(
              children: [
                Text(
                  _wifiEnabled ? 'On' : 'Off',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                Switch(
                  value: _wifiEnabled,
                  onChanged: (value) => _toggleWifi(value),
                  activeColor: const Color.fromARGB(255, 100, 200, 255),
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
              'Available Networks',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (_isScanning)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Color.fromARGB(255, 100, 200, 255)),
                ),
              )
            else
              IconButton(
                onPressed: _wifiEnabled ? _startScanning : null,
                icon: const Icon(Icons.refresh_rounded),
                color: _wifiEnabled ? Colors.white54 : Colors.white.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(height: 24),
        // Networks list
        Expanded(
          child: _buildNetworksList(),
        ),
      ],
    );
  }

  Widget _buildNetworksList() {
    if (_error != null) {
      return Center(
        child: GlassmorphicContainer(
          width: double.infinity,
          borderRadius: 16,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.withOpacity(0.1),
              Colors.red.withOpacity(0.05),
            ],
          ),
          border: 1.2,
          blur: 40,
          borderGradient: const LinearGradient(colors: []),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.red.shade300,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Colors.red.shade300,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Colors.tealAccent),
        ),
      );
    }

    if (!_wifiEnabled) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Wi-Fi is turned off',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Turn on Wi-Fi to see available networks',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_networks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_find_rounded,
              size: 48,
              color: Colors.white.withOpacity(0.1),
            ),
            const SizedBox(height: 16),
            Text(
              'No networks found',
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
      itemCount: _networks.length,
      separatorBuilder: (_, __) => const Divider(
        color: Colors.white10,
        height: 1,
        indent: 0,
        endIndent: 0,
      ),
      itemBuilder: (context, index) {
        final network = _networks[index];
        final isConnecting = _connectingTo == network.ssid;

        return GlassmorphicContainer(
          width: double.infinity,
          height: 72,
          borderRadius: 16,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              network.isConnected
                  ? Colors.teal.withOpacity(0.15)
                  : Colors.white.withOpacity(0.05),
              network.isConnected
                  ? Colors.teal.withOpacity(0.08)
                  : Colors.white.withOpacity(0.03),
            ],
          ),
          border: 1.2,
          blur: 30,
          borderGradient: const LinearGradient(colors: []),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Icon(
                network.strength > 80
                    ? Icons.wifi_rounded
                    : network.strength > 60
                    ? Icons.network_wifi_3_bar_rounded
                    : network.strength > 40
                    ? Icons.network_wifi_2_bar_rounded
                    : Icons.network_wifi_1_bar_rounded,
                color: network.isConnected
                    ? Colors.tealAccent
                    : Colors.white54,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            network.ssid,
                            style: TextStyle(
                              color: network.isConnected
                                  ? Colors.white
                                  : Colors.white70,
                              fontWeight: network.isConnected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (network.isSecure)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.lock_rounded,
                              size: 14,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      network.isConnected
                          ? 'Connected'
                          : network.isSaved
                          ? 'Saved'
                          : '${network.strength}% signal',
                      style: TextStyle(
                        color: network.isConnected
                            ? Colors.tealAccent
                            : Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (isConnecting)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      Colors.tealAccent,
                    ),
                  ),
                )
              else if (network.isConnected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.tealAccent,
                  size: 24,
                )
              else if (network.isSaved)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: Colors.white38,
                  onPressed: () => _forgetNetwork(network),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                )
              else
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _connectToNetwork(network),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text(
                        'Connect',
                        style: TextStyle(
                          color: const Color.fromARGB(255, 100, 200, 255),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

