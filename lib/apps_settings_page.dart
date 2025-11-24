import 'package:flutter/material.dart';
import 'package:antidote/glassmorphic_container.dart';
import 'package:venom_config/venom_config.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class AppsSettingsPage extends StatefulWidget {
  const AppsSettingsPage({super.key});

  @override
  State<AppsSettingsPage> createState() => _AppsSettingsPageState();
}

class _AppsSettingsPageState extends State<AppsSettingsPage> {
  // 20 Preset Colors
  final List<Color> _presetColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
  ];

  Color _currentColor = Colors.blue;
  double _opacity = 1.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Applications Control',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),

            // Advanced Color Control
            _buildSectionHeader('System Theme Color'),
            const SizedBox(height: 16),
            GlassmorphicContainer(
              width: double.infinity,
              height: 400, // Increased height for more controls
              borderRadius: 16,
              blur: 10,
              border: 1,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  // Colors.white.withOpacity(0.1),
                  // Colors.white.withOpacity(0.05),
                ],
              ),
              borderGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  // Colors.white.withOpacity(0.5),
                  // Colors.white.withOpacity(0.1),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Preset Colors Grid
                    const Text(
                      'Preset Colors',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _presetColors
                          .map((color) => _buildColorOption(color))
                          .toList(),
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 16),

                    // 2. Custom Color Picker Button
                    Row(
                      children: [
                        const Text(
                          'Custom Color:',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.color_lens),
                          label: const Text("Pick Custom Color"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentColor,
                            foregroundColor:
                                _currentColor.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                          ),
                          onPressed: () => _showColorPicker(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 3. Opacity Slider
                    const Text(
                      'Opacity / Transparency',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _opacity,
                            min: 0.0,
                            max: 1.0,
                            divisions: 100,
                            label: '${(_opacity * 100).round()}%',
                            onChanged: (value) {
                              setState(() {
                                _opacity = value;
                                _updateConfig(
                                  _currentColor.withOpacity(_opacity),
                                );
                              });
                            },
                          ),
                        ),
                        Text(
                          '${(_opacity * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Text Color Section
            _buildSectionHeader('System Text Color'),
            const SizedBox(height: 16),
            GlassmorphicContainer(
              width: double.infinity,
              height: 120,
              borderRadius: 16,
              blur: 10,
              border: 1,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  // Colors.white.withOpacity(0.1),
                  // Colors.white.withOpacity(0.05),
                ],
              ),
              borderGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  // Colors.white.withOpacity(0.5),
                  // Colors.white.withOpacity(0.1),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Text Color Presets',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildSimpleColorButton(
                          'White',
                          '#FFFFFF',
                          Colors.white,
                          'system.text_color',
                        ),
                        const SizedBox(width: 16),
                        _buildSimpleColorButton(
                          'Black',
                          '#000000',
                          Colors.black,
                          'system.text_color',
                        ),
                        const SizedBox(width: 16),
                        _buildSimpleColorButton(
                          'Blue',
                          '#448AFF',
                          Colors.blueAccent,
                          'system.text_color',
                        ),
                        const SizedBox(width: 16),
                        _buildSimpleColorButton(
                          'Red',
                          '#FF5252',
                          Colors.redAccent,
                          'system.text_color',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _buildColorOption(Color color) {
    return InkWell(
      onTap: () {
        setState(() {
          _currentColor = color;
          _updateConfig(color.withOpacity(_opacity));
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _currentColor.value == color.value
                ? Colors.white
                : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _currentColor,
              onColorChanged: (color) {
                setState(() {
                  _currentColor = color;
                  // Don't update config immediately while dragging, wait for selection
                });
              },
              enableAlpha: false, // We handle alpha separately with slider
              displayThumbColor: true,
              paletteType: PaletteType.hsvWithHue,
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Got it'),
              onPressed: () {
                _updateConfig(_currentColor.withOpacity(_opacity));
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateConfig(Color color) async {
    // Convert Color to Hex String (#AARRGGBB)
    // We use value.toRadixString(16) and padLeft to ensure full 8 chars including alpha
    String hex =
        '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';

    // Save to Venom Config
    await VenomConfig().set('system.background_color', hex);
    print("Saved Color: $hex");
  }

  Widget _buildSimpleColorButton(
    String label,
    String hex,
    Color color,
    String key,
  ) {
    return InkWell(
      onTap: () => VenomConfig().set(key, hex),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
