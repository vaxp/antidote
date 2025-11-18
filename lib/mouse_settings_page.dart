import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dbus/dbus.dart';

class MouseSettingsPage extends StatefulWidget {
  const MouseSettingsPage({super.key});

  @override
  State<MouseSettingsPage> createState() => _MouseSettingsPageState();
}

class _MouseSettingsPageState extends State<MouseSettingsPage> {
  late DBusClient _sysbus;
  Timer? _updateTimer;
  int _selectedTab = 0; // 0 = Mouse, 1 = Touchpad

  // Mouse settings
  String _primaryButton = 'left'; // 'left' or 'right'
  double _mousePointerSpeed = 0.5;
  bool _mouseAcceleration = true;
  String _scrollDirection = 'traditional'; // 'traditional' or 'natural'

  // Touchpad settings
  bool _touchpadEnabled = true;
  bool _disableTouchpadWhileTyping = true;
  double _touchpadPointerSpeed = 0.5;
  String _secondaryClick = 'two-finger'; // 'two-finger' or 'corner'
  bool _tapToClick = true;

  @override
  void initState() {
    super.initState();
    _sysbus = DBusClient.system();
    _initMouseSettings();
    _updateTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _refreshSettings(),
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _sysbus.close();
    super.dispose();
  }

  Future<void> _initMouseSettings() async {
    await _refreshSettings();
  }

  Future<void> _refreshSettings() async {
    if (!mounted) return;
    try {
      await Future.wait([
        _getMouseSettings(),
        _getTouchpadSettings(),
      ]);
    } catch (e) {
      debugPrint('Settings refresh error: $e');
    }
  }

  Future<void> _getMouseSettings() async {
    try {
      // Get primary button
      final leftHandedResult = await Process.run('gsettings', [
        'get',
        'org.gnome.desktop.peripherals.mouse',
        'left-handed',
      ]);
      if (leftHandedResult.exitCode == 0) {
        final value = leftHandedResult.stdout.toString().trim();
        if (mounted) {
          setState(() => _primaryButton = value == 'true' ? 'right' : 'left');
        }
      }

      // Get pointer speed
      final speedResult = await Process.run('gsettings', [
        'get',
        'org.gnome.desktop.peripherals.mouse',
        'speed',
      ]);
      if (speedResult.exitCode == 0) {
        final value = double.tryParse(speedResult.stdout.toString().trim()) ?? 0.0;
        if (mounted) {
          setState(() => _mousePointerSpeed = (value + 1.0) / 2.0); // Convert -1.0 to 1.0 to 0.0 to 1.0
        }
      }

      // Get acceleration
      final accelResult = await Process.run('gsettings', [
        'get',
        'org.gnome.desktop.peripherals.mouse',
        'accel-profile',
      ]);
      if (accelResult.exitCode == 0) {
        final value = accelResult.stdout.toString().trim();
        if (mounted) {
          setState(() => _mouseAcceleration = value != "'flat'");
        }
      }

      // Get scroll direction (natural scrolling)
      final naturalResult = await Process.run('gsettings', [
        'get',
        'org.gnome.desktop.peripherals.mouse',
        'natural-scroll',
      ]);
      if (naturalResult.exitCode == 0) {
        final value = naturalResult.stdout.toString().trim();
        if (mounted) {
          setState(() => _scrollDirection = value == 'true' ? 'natural' : 'traditional');
        }
      }
    } catch (e) {
      debugPrint('Get mouse settings error: $e');
    }
  }

  Future<void> _getTouchpadSettings() async {
    try {
      // Get touchpad enabled
      final enabledResult = await Process.run('gsettings', [
        'get',
        'org.gnome.desktop.peripherals.touchpad',
        'send-events',
      ]);
      if (enabledResult.exitCode == 0) {
        final value = enabledResult.stdout.toString().trim();
        if (mounted) {
          setState(() => _touchpadEnabled = value != "'disabled'");
        }
      }

      // Get disable while typing
      final typingResult = await Process.run('gsettings', [
        'get',
        'org.gnome.desktop.peripherals.touchpad',
        'disable-while-typing',
      ]);
      if (typingResult.exitCode == 0) {
        final value = typingResult.stdout.toString().trim();
        if (mounted) {
          setState(() => _disableTouchpadWhileTyping = value == 'true');
        }
      }

      // Get pointer speed
      final speedResult = await Process.run('gsettings', [
        'get',
        'org.gnome.desktop.peripherals.touchpad',
        'speed',
      ]);
      if (speedResult.exitCode == 0) {
        final value = double.tryParse(speedResult.stdout.toString().trim()) ?? 0.0;
        if (mounted) {
          setState(() => _touchpadPointerSpeed = (value + 1.0) / 2.0);
        }
      }

      // Get secondary click method
      final clickMethodResult = await Process.run('gsettings', [
        'get',
        'org.gnome.desktop.peripherals.touchpad',
        'click-method',
      ]);
      if (clickMethodResult.exitCode == 0) {
        final value = clickMethodResult.stdout.toString().trim();
        if (mounted) {
          setState(() {
            _secondaryClick = value == "'fingers'" ? 'two-finger' : 'corner';
          });
        }
      }

      // Get tap to click
      final tapResult = await Process.run('gsettings', [
        'get',
        'org.gnome.desktop.peripherals.touchpad',
        'tap-to-click',
      ]);
      if (tapResult.exitCode == 0) {
        final value = tapResult.stdout.toString().trim();
        if (mounted) {
          setState(() => _tapToClick = value == 'true');
        }
      }
    } catch (e) {
      debugPrint('Get touchpad settings error: $e');
    }
  }

  Future<void> _setPrimaryButton(String button) async {
    try {
      await Process.run('gsettings', [
        'set',
        'org.gnome.desktop.peripherals.mouse',
        'left-handed',
        button == 'right' ? 'true' : 'false',
      ]);
      setState(() => _primaryButton = button);
    } catch (e) {
      debugPrint('Set primary button error: $e');
    }
  }

  Future<void> _setMousePointerSpeed(double value) async {
    setState(() => _mousePointerSpeed = value);
    try {
      // Convert 0.0-1.0 to -1.0 to 1.0
      final speed = (value * 2.0) - 1.0;
      await Process.run('gsettings', [
        'set',
        'org.gnome.desktop.peripherals.mouse',
        'speed',
        speed.toStringAsFixed(2),
      ]);
    } catch (e) {
      debugPrint('Set mouse pointer speed error: $e');
    }
  }

  Future<void> _setMouseAcceleration(bool enabled) async {
    try {
      await Process.run('gsettings', [
        'set',
        'org.gnome.desktop.peripherals.mouse',
        'accel-profile',
        enabled ? "'adaptive'" : "'flat'",
      ]);
      setState(() => _mouseAcceleration = enabled);
    } catch (e) {
      debugPrint('Set mouse acceleration error: $e');
    }
  }

  Future<void> _setScrollDirection(String direction) async {
    try {
      await Process.run('gsettings', [
        'set',
        'org.gnome.desktop.peripherals.mouse',
        'natural-scroll',
        direction == 'natural' ? 'true' : 'false',
      ]);
      setState(() => _scrollDirection = direction);
    } catch (e) {
      debugPrint('Set scroll direction error: $e');
    }
  }

  Future<void> _setTouchpadEnabled(bool enabled) async {
    try {
      await Process.run('gsettings', [
        'set',
        'org.gnome.desktop.peripherals.touchpad',
        'send-events',
        enabled ? "'enabled'" : "'disabled'",
      ]);
      setState(() => _touchpadEnabled = enabled);
    } catch (e) {
      debugPrint('Set touchpad enabled error: $e');
    }
  }

  Future<void> _setDisableTouchpadWhileTyping(bool enabled) async {
    try {
      await Process.run('gsettings', [
        'set',
        'org.gnome.desktop.peripherals.touchpad',
        'disable-while-typing',
        enabled.toString(),
      ]);
      setState(() => _disableTouchpadWhileTyping = enabled);
    } catch (e) {
      debugPrint('Set disable touchpad while typing error: $e');
    }
  }

  Future<void> _setTouchpadPointerSpeed(double value) async {
    setState(() => _touchpadPointerSpeed = value);
    try {
      // Convert 0.0-1.0 to -1.0 to 1.0
      final speed = (value * 2.0) - 1.0;
      await Process.run('gsettings', [
        'set',
        'org.gnome.desktop.peripherals.touchpad',
        'speed',
        speed.toStringAsFixed(2),
      ]);
    } catch (e) {
      debugPrint('Set touchpad pointer speed error: $e');
    }
  }

  Future<void> _setSecondaryClick(String method) async {
    try {
      await Process.run('gsettings', [
        'set',
        'org.gnome.desktop.peripherals.touchpad',
        'click-method',
        method == 'two-finger' ? "'fingers'" : "'areas'",
      ]);
      setState(() => _secondaryClick = method);
    } catch (e) {
      debugPrint('Set secondary click error: $e');
    }
  }

  Future<void> _setTapToClick(bool enabled) async {
    try {
      await Process.run('gsettings', [
        'set',
        'org.gnome.desktop.peripherals.touchpad',
        'tap-to-click',
        enabled.toString(),
      ]);
      setState(() => _tapToClick = enabled);
    } catch (e) {
      debugPrint('Set tap to click error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mouse & Touchpad',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure input device settings',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 48),
            _buildTabs(),
            const SizedBox(height: 24),
            _selectedTab == 0 ? _buildMouseTab() : _buildTouchpadTab(),
            const SizedBox(height: 32),
            _buildTestButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        _buildTab('Mouse', 0),
        const SizedBox(width: 8),
        _buildTab('Touchpad', 1),
      ],
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blueAccent.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: Colors.blueAccent, width: 2)
              : Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildMouseTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // General Section
        _buildSection(
          'General',
          children: [
            _buildPrimaryButtonSetting(),
          ],
        ),
        const SizedBox(height: 24),
        // Mouse Section
        _buildSection(
          'Mouse',
          children: [
            _buildPointerSpeedSlider(
              'Pointer Speed',
              _mousePointerSpeed,
              _setMousePointerSpeed,
            ),
            const SizedBox(height: 24),
            _buildAccelerationToggle(),
          ],
        ),
        const SizedBox(height: 24),
        // Scroll Direction Section
        _buildSection(
          'Scroll Direction',
          children: [
            _buildScrollDirectionOptions(),
          ],
        ),
      ],
    );
  }

  Widget _buildTouchpadTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Touchpad Overview (placeholder for icon)
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Icon(
              Icons.touch_app_rounded,
              size: 64,
              color: Colors.blueAccent.withOpacity(0.5),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // General Touchpad Settings
        _buildSection(
          'Touchpad',
          children: [
            _buildToggleSetting(
              'Touchpad',
              _touchpadEnabled,
              null,
              _setTouchpadEnabled,
            ),
            const SizedBox(height: 16),
            _buildToggleSetting(
              'Disable Touchpad While Typing',
              _disableTouchpadWhileTyping,
              null,
              _setDisableTouchpadWhileTyping,
            ),
            const SizedBox(height: 24),
            _buildPointerSpeedSlider(
              'Pointer Speed',
              _touchpadPointerSpeed,
              _setTouchpadPointerSpeed,
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Clicking Section
        _buildSection(
          'Clicking',
          children: [
            _buildSecondaryClickOptions(),
          ],
        ),
        const SizedBox(height: 24),
        // Tap to Click Section
        _buildSection(
          'Tap to Click',
          children: [
            _buildTapToClickSetting(),
          ],
        ),
      ],
    );
  }

  Widget _buildSection(String title, {required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPrimaryButtonSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Primary Button',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSegmentedButton(
                'Left',
                _primaryButton == 'left',
                () => _setPrimaryButton('left'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSegmentedButton(
                'Right',
                _primaryButton == 'right',
                () => _setPrimaryButton('right'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Order of physical buttons on mice and touchpads',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedButton(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blueAccent.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPointerSpeedSlider(
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text(
              'Slow',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  activeTrackColor: Colors.blueAccent,
                  inactiveTrackColor: Colors.white.withOpacity(0.2),
                  thumbColor: Colors.white,
                  overlayShape: SliderComponentShape.noOverlay,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                ),
                child: Slider(
                  value: value.clamp(0.0, 1.0),
                  min: 0,
                  max: 1,
                  onChanged: onChanged,
                ),
              ),
            ),
            const Text(
              'Fast',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccelerationToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: Colors.white.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mouse Acceleration',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: _mouseAcceleration,
          onChanged: _setMouseAcceleration,
          activeColor: Colors.blueAccent,
        ),
      ],
    );
  }

  Widget _buildScrollDirectionOptions() {
    return Column(
      children: [
        _buildRadioOption(
          'Traditional',
          'Scrolling moves the view',
          _scrollDirection == 'traditional',
          Icons.arrow_upward_rounded,
          () => _setScrollDirection('traditional'),
        ),
        const SizedBox(height: 16),
        _buildRadioOption(
          'Natural',
          'Scrolling moves the content',
          _scrollDirection == 'natural',
          Icons.arrow_downward_rounded,
          () => _setScrollDirection('natural'),
        ),
      ],
    );
  }

  Widget _buildRadioOption(
    String title,
    String description,
    bool isSelected,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blueAccent.withOpacity(0.1)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.blueAccent
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.blueAccent, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Radio(
              value: isSelected,
              groupValue: true,
              onChanged: (_) => onTap(),
              activeColor: Colors.blueAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryClickOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Secondary Click',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildRadioOption(
          'Two Finger Push',
          'Push anywhere with 2 fingers',
          _secondaryClick == 'two-finger',
          Icons.touch_app_rounded,
          () => _setSecondaryClick('two-finger'),
        ),
        const SizedBox(height: 16),
        _buildRadioOption(
          'Corner Push',
          'Push with a single finger in the corner',
          _secondaryClick == 'corner',
          Icons.touch_app_rounded,
          () => _setSecondaryClick('corner'),
        ),
      ],
    );
  }

  Widget _buildTapToClickSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tap to Click',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Quickly touch the touchpad to click',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _tapToClick,
              onChanged: _setTapToClick,
              activeColor: Colors.blueAccent,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.touch_app_rounded,
            color: Colors.blueAccent,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleSetting(
    String label,
    bool value,
    String? description,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.blueAccent,
        ),
      ],
    );
  }

  Widget _buildTestButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Test your settings by using your mouse/touchpad'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text('Test Settings'),
      ),
    );
  }
}

