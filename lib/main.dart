import 'package:flutter/material.dart';
import 'package:antidote/display_settings_page.dart';
import 'package:antidote/wifi_settings_page.dart';
import 'package:antidote/bluetooth_settings_page.dart';
import 'package:antidote/power_settings_page.dart';
import 'package:antidote/audio_settings_page.dart';
import 'package:antidote/mouse_settings_page.dart';
import 'package:antidote/keyboard_settings_page.dart';
import 'package:antidote/system_settings_page.dart';
import 'package:antidote/glassmorphic_container.dart';

void main() {
  runApp(const VenomLabApp());
}

class VenomLabApp extends StatelessWidget {
  const VenomLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
        brightness: Brightness.dark,
        canvasColor: Colors.transparent,
        cardColor: Colors.transparent,
        dialogBackgroundColor: Colors.transparent,
      ),
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
      body: Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(122, 0, 0, 0),
        ),
        child: Row(
          children: [
            // Sidebar Navigation
            GlassmorphicContainer(
              width: 240,
              height: double.infinity,
              borderRadius: 0,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color.fromARGB(0, 0, 00, 00),
                  const Color.fromARGB(0, 00, 00, 00),
                ],
                stops: const [0.0, 0.0],
              ),
              border: 0.8,
              blur: 40,
              borderGradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 8, top: 8, bottom: 8),
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
      ),
    );
  }

  Widget _buildNavItem(NavigationItem item, int index, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color.fromARGB(0, 0, 0, 0),
        child: InkWell(
          onTap: () => setState(() => _selectedIndex = index),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color.fromARGB(255, 64, 200, 255).withOpacity(0.35),
                        const Color.fromARGB(255, 100, 150, 255).withOpacity(0.25),
                        const Color.fromARGB(255, 80, 120, 220).withOpacity(0.15),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    )
                  : null,
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(
                      color: const Color.fromARGB(255, 64, 200, 255).withOpacity(0.6),
                      width: 1.5,
                    )
                  : Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: isSelected 
                      ? const Color.fromARGB(255, 120, 210, 255)
                      : Colors.white.withOpacity(0.7),
                  size: 22,
                ),
                const SizedBox(width: 14),
                Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected 
                        ? Colors.white 
                        : Colors.white.withOpacity(0.8),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
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
