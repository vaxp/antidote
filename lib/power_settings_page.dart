import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dbus/dbus.dart';

class PowerSettingsPage extends StatefulWidget {
  const PowerSettingsPage({super.key});

  @override
  State<PowerSettingsPage> createState() => _PowerSettingsPageState();
}

class _PowerSettingsPageState extends State<PowerSettingsPage> {
  late DBusClient _sysbus;
  Timer? _updateTimer;

  double _batteryLevel = 0.0;
  bool _isCharging = false;
  String _activePowerProfile = 'balanced';

  @override
  void initState() {
    super.initState();
    _sysbus = DBusClient.system();
    _initPowerSettings();
    _updateTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _refreshPowerInfo(),
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _sysbus.close();
    super.dispose();
  }

  Future<void> _initPowerSettings() async {
    await _refreshPowerInfo();
  }

  Future<void> _refreshPowerInfo() async {
    await Future.wait([
      _getBatteryInfo(),
      _getPowerProfile(),
    ]);
  }

  Future<void> _getBatteryInfo() async {
    try {
      final object = DBusRemoteObject(
        _sysbus,
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
      if (mounted) {
        setState(() {
          _batteryLevel = percent.value;
          _isCharging = state.value == 1;
        });
      }
    } catch (_) {}
  }

  Future<void> _getPowerProfile() async {
    try {
      final ppd = DBusRemoteObject(
        _sysbus,
        name: 'org.freedesktop.UPower.PowerProfiles',
        path: DBusObjectPath('/org/freedesktop/UPower/PowerProfiles'),
      );
      final active =
          (await ppd.getProperty(
                'org.freedesktop.UPower.PowerProfiles',
                'ActiveProfile',
              ))
              as DBusString;
      if (mounted) setState(() => _activePowerProfile = active.value);
    } catch (_) {}
  }

  Future<void> _setPowerProfile(String profile) async {
    try {
      final ppd = DBusRemoteObject(
        _sysbus,
        name: 'org.freedesktop.UPower.PowerProfiles',
        path: DBusObjectPath('/org/freedesktop/UPower/PowerProfiles'),
      );
      await ppd.setProperty(
        'org.freedesktop.UPower.PowerProfiles',
        'ActiveProfile',
        DBusString(profile),
      );
      await _getPowerProfile();
    } catch (_) {}
  }

  void _powerAction(String action) {
    switch (action) {
      case 'shutdown':
        Process.run('systemctl', ['poweroff']);
        break;
      case 'reboot':
        Process.run('systemctl', ['reboot']);
        break;
      case 'suspend':
        Process.run('systemctl', ['suspend']);
        break;
      case 'logout':
        final user = Platform.environment['USER'];
        if (user != null) Process.run('loginctl', ['terminate-user', user]);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(0, 0, 0, 0),
      body: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color.fromARGB(220, 28, 32, 44),
                Color.fromARGB(180, 18, 20, 30),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Power',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                // Battery
                _buildBatteryTile(),
                const SizedBox(height: 32),
                // Power Profiles
                const Text(
                  'Performance',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.fromARGB(12, 255, 255, 255),
                        Color.fromARGB(10, 255, 255, 255),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildProfileBtn(
                        'Saver',
                        Icons.eco_rounded,
                        'power-saver',
                        Colors.greenAccent,
                      ),
                      _buildProfileBtn(
                        'Balanced',
                        Icons.balance_rounded,
                        'balanced',
                        Colors.blueAccent,
                      ),
                      _buildProfileBtn(
                        'Boost',
                        Icons.speed_rounded,
                        'performance',
                        Colors.redAccent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 24),
                // Power Actions
                const Text(
                  'System Actions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPowerButton(
                      Icons.power_settings_new_rounded,
                      Colors.redAccent,
                      'Shutdown',
                      () => _powerAction('shutdown'),
                    ),
                    _buildPowerButton(
                      Icons.restart_alt_rounded,
                      Colors.orangeAccent,
                      'Reboot',
                      () => _powerAction('reboot'),
                    ),
                    _buildPowerButton(
                      Icons.bedtime_rounded,
                      Colors.blueAccent,
                      'Suspend',
                      () => _powerAction('suspend'),
                    ),
                    _buildPowerButton(
                      Icons.logout_rounded,
                      Colors.grey,
                      'Logout',
                      () => _powerAction('logout'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBatteryTile() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.02)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 8,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _isCharging
                ? Icons.battery_charging_full_rounded
                : Icons.battery_std_rounded,
            color: _isCharging ? Colors.greenAccent : Colors.white70,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Battery',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _batteryLevel / 100,
                    minHeight: 6,
                    backgroundColor: Colors.white10,
                    color: _isCharging
                        ? Colors.greenAccent
                        : (_batteryLevel <= 20
                              ? Colors.redAccent
                              : Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${_batteryLevel.toInt()}%',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileBtn(
    String label,
    IconData icon,
    String profileID,
    Color color,
  ) {
    final isActive = _activePowerProfile == profileID;
    return Expanded(
      child: InkWell(
        onTap: () => _setPowerProfile(profileID),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.14) : Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? color.withOpacity(0.35) : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isActive ? 0.18 : 0.06),
                blurRadius: isActive ? 14 : 4,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(-0.04)
                  ..rotateY(0.03),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isActive
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [color.withOpacity(0.28), color.withOpacity(0.06)],
                          )
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.fromARGB(36, 255, 255, 255),
                              Color.fromARGB(8, 255, 255, 255),
                            ],
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isActive ? 0.22 : 0.08),
                        blurRadius: isActive ? 14 : 6,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 18, color: isActive ? Colors.white : Colors.white54),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isActive ? Colors.white : Colors.white54,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPowerButton(IconData icon, Color color, String label, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 26),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

