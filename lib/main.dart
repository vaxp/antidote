import 'package:flutter/material.dart';
import 'package:antidote/display_settings_page.dart';
import 'package:antidote/wifi_settings_page.dart';
import 'package:antidote/bluetooth_settings_page.dart';
import 'package:antidote/power_settings_page.dart';
import 'package:antidote/audio_settings_page.dart';
import 'package:antidote/mouse_settings_page.dart';
import 'package:antidote/keyboard_settings_page.dart';
import 'package:antidote/system_settings_page.dart';

void main() {
  runApp(const VenomLabApp());
}

class VenomLabApp extends StatelessWidget {
  const VenomLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SettingsHomePage(),
    );
  }
}

class SettingsHomePage extends StatefulWidget {
  const SettingsHomePage({super.key});

  @override
  State<SettingsHomePage> createState() => _SettingsHomePageState();
}

class _SettingsHomePageState extends State<SettingsHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    DisplaySettingsPage(),
    WiFiSettingsPage(),
    BluetoothSettingsPage(),
    AudioSettingsPage(),
    MouseSettingsPage(),
    KeyboardSettingsPage(),
    SystemSettingsPage(),
    PowerSettingsPage(),
  ];

  final List<NavigationItem> _navItems = const [
    NavigationItem(
      icon: Icons.monitor_rounded,
      label: 'Display',
    ),
    NavigationItem(
      icon: Icons.wifi_rounded,
      label: 'Wi-Fi',
    ),
    NavigationItem(
      icon: Icons.bluetooth_rounded,
      label: 'Bluetooth',
    ),
    NavigationItem(
      icon: Icons.volume_up_rounded,
      label: 'Sound',
    ),
    NavigationItem(
      icon: Icons.mouse_rounded,
      label: 'Mouse',
    ),
    NavigationItem(
      icon: Icons.keyboard_rounded,
      label: 'Keyboard',
    ),
    NavigationItem(
      icon: Icons.settings_rounded,
      label: 'System',
    ),
    NavigationItem(
      icon: Icons.power_settings_new_rounded,
      label: 'Power',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(220, 28, 32, 44),
      body: Row(
        children: [
          // Sidebar Navigation
          Container(
            width: 200,
            padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color.fromARGB(220, 28, 32, 44),
                Color.fromARGB(180, 18, 20, 30),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              border: Border(
                right: BorderSide(color: Colors.white.withOpacity(0.06)),
              ),
          ),
          child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Settings',
                        style: TextStyle(
                      fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _navItems.length,
                    itemBuilder: (context, index) {
                      final item = _navItems[index];
                      final isSelected = _selectedIndex == index;
                      return _buildNavItem(item, index, isSelected);
                    },
                  ),
                        ),
                      ],
                    ),
                  ),
              // Content Area
              Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(NavigationItem item, int index, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.tealAccent.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: Colors.tealAccent.withOpacity(0.3),
                  width: 1,
                )
              : null,
        ),
        child: Row(
              children: [
                Icon(
              item.icon,
              color: isSelected ? Colors.tealAccent : Colors.white70,
              size: 20,
              ),
              const SizedBox(width: 12),
            Text(
              item.label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;

  const NavigationItem({
    required this.icon,
    required this.label,
  });
}
