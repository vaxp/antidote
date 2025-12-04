import 'package:antidote/core/appbar.dart';
import 'package:antidote/venom_effects.dart';
import 'package:antidote/core/venom_layout.dart';
import 'package:flutter/material.dart';
import 'package:antidote/display_settings_page.dart';
import 'package:antidote/wifi_settings_page.dart';
import 'package:antidote/bluetooth_settings_page.dart';
import 'package:antidote/power_settings_page.dart';
import 'package:antidote/audio_settings_page.dart';
import 'package:antidote/mouse_settings_page.dart';
import 'package:antidote/keyboard_settings_page.dart';
import 'package:antidote/apps_settings_page.dart'; 
import 'package:antidote/system_settings_page.dart';
import 'package:antidote/glassmorphic_container.dart';
import 'package:window_manager/window_manager.dart';
import 'package:venom_config/venom_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await VenomConfig().init();

  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1000, 700),
    center: true,
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

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
    WiFiSettingsPage(),
    BluetoothSettingsPage(),
    CompositorSettingsPage(),
    AppsSettingsPage(),
    DisplaySettingsPage(),
    AudioSettingsPage(),
    MouseSettingsPage(),
    KeyboardSettingsPage(),
    SystemSettingsPage(),
    PowerSettingsPage(),
  ];

  final List<NavigationItem> _navItems = const [
    NavigationItem(icon: Icons.wifi_rounded, label: 'Wi-Fi'),
    NavigationItem(icon: Icons.bluetooth_rounded, label: 'Bluetooth'),
    NavigationItem(icon: Icons.theater_comedy_sharp, label: 'Venom Effects'),
    NavigationItem(icon: Icons.apps_rounded, label: 'Venom Theme'),
    NavigationItem(icon: Icons.monitor_rounded, label: 'Display'),
    NavigationItem(icon: Icons.volume_up_rounded, label: 'Sound'),
    NavigationItem(icon: Icons.mouse_rounded, label: 'Mouse'),
    NavigationItem(icon: Icons.keyboard_rounded, label: 'Keyboard'),
    NavigationItem(icon: Icons.settings_rounded, label: 'System'),
    NavigationItem(icon: Icons.power_settings_new_rounded, label: 'Power'),
  ];

  @override
  Widget build(BuildContext context) {
    return VenomScaffold(
      appBar: Appbar(),
      backgroundColor: const Color.fromARGB(0, 0, 0, 0),
      body: Container(
        decoration: const BoxDecoration(color: Color.fromARGB(100, 0, 0, 0)),
        child: Row(
          children: [
            GlassmorphicContainer(
              width: 240,
              height: double.infinity,
              borderRadius: 0,
              border: 0,
              blur: 0,
              borderGradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [],
              ),
              padding: const EdgeInsets.all(10),
              alignment: Alignment.topCenter,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color.fromARGB(0, 0, 0, 0),
                  const Color.fromARGB(0, 0, 0, 0),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
            Expanded(child: _pages[_selectedIndex]),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(NavigationItem item, int index, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedIndex = index),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color.fromARGB(
                          255,
                          64,
                          200,
                          255,
                        ).withOpacity(0.35),
                        const Color.fromARGB(
                          255,
                          100,
                          150,
                          255,
                        ).withOpacity(0.25),
                        const Color.fromARGB(
                          255,
                          80,
                          120,
                          220,
                        ).withOpacity(0.15),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    )
                  : null,
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(
                      color: const Color.fromARGB(
                        255,
                        64,
                        200,
                        255,
                      ).withOpacity(0.6),
                      width: 1.5,
                    )
                  : Border.all(color: Colors.white.withOpacity(0.1), width: 1),
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

  const NavigationItem({required this.icon, required this.label});
}
