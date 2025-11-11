import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

class AudioDevice {
  final String name;
  final String description;
  final bool isInput;
  final bool isDefault;

  AudioDevice({
    required this.name,
    required this.description,
    required this.isInput,
    this.isDefault = false,
  });

  @override
  String toString() => description;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AudioDevice &&
        other.name == name &&
        other.isInput == isInput;
  }

  @override
  int get hashCode => name.hashCode ^ isInput.hashCode;
}

class AudioSettingsPage extends StatefulWidget {
  const AudioSettingsPage({super.key});

  @override
  State<AudioSettingsPage> createState() => _AudioSettingsPageState();
}

class _AudioSettingsPageState extends State<AudioSettingsPage> {
  Timer? _updateTimer;

  // Output settings
  List<AudioDevice> _outputDevices = [];
  AudioDevice? _selectedOutputDevice;
  double _outputVolume = 75.0;
  double _balance = 50.0;
  bool _overamplification = false;

  // Input settings
  List<AudioDevice> _inputDevices = [];
  AudioDevice? _selectedInputDevice;
  double _inputVolume = 75.0;

  @override
  void initState() {
    super.initState();
    _initAudioSettings();
    _updateTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _refreshAudioInfo(),
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> _initAudioSettings() async {
    await _refreshAudioInfo();
  }

  Future<void> _refreshAudioInfo() async {
    if (!mounted) return;
    try {
      await Future.wait([
        _getOutputDevices(),
        _getInputDevices(),
        _getOutputVolume(),
        _getInputVolume(),
        _getBalance(),
      ]);
    } catch (e) {
      debugPrint('Audio refresh error: $e');
    }
  }

  Future<void> _getOutputDevices() async {
    try {
      final result = await Process.run('pactl', ['list', 'short', 'sinks']);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        final List<AudioDevice> devices = [];
        String? defaultSink;

        // Get default sink
        final defaultResult = await Process.run('pactl', ['get-default-sink']);
        if (defaultResult.exitCode == 0) {
          defaultSink = defaultResult.stdout.toString().trim();
        }

        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          final parts = line.split('\t');
          if (parts.length >= 2) {
            final sinkIndex = parts[0];
            final sinkName = parts[1];
            String description = sinkName;

            // Get description
            try {
              final infoResult = await Process.run(
                'pactl',
                ['list', 'sinks', 'short'],
              );
              if (infoResult.exitCode == 0) {
                final infoLines = infoResult.stdout.toString().split('\n');
                for (final infoLine in infoLines) {
                  if (infoLine.contains(sinkName)) {
                    final infoParts = infoLine.split('\t');
                    if (infoParts.length >= 2) {
                      description = infoParts[1];
                    }
                  }
                }
              }
            } catch (_) {}

            // Get better description using pactl info
            try {
              final sinkInfo = await Process.run(
                'pactl',
                ['list', 'sinks'],
              );
              if (sinkInfo.exitCode == 0) {
                final sinkInfoLines = sinkInfo.stdout.toString().split('\n');
                bool inSink = false;
                for (final infoLine in sinkInfoLines) {
                  if (infoLine.contains('Sink #$sinkIndex') ||
                      infoLine.contains('Name: $sinkName')) {
                    inSink = true;
                    continue;
                  }
                  if (inSink && infoLine.contains('Description:')) {
                    description = infoLine.split('Description:')[1].trim();
                    break;
                  }
                  if (inSink && infoLine.startsWith('Sink #')) {
                    break;
                  }
                }
              }
            } catch (_) {}

            final isDefault = sinkName == defaultSink;
            
            // Check if device already exists to avoid duplicates
            if (!devices.any((d) => d.name == sinkName)) {
              devices.add(AudioDevice(
                name: sinkName,
                description: description,
                isInput: false,
                isDefault: isDefault,
              ));

              if (isDefault && _selectedOutputDevice == null) {
                setState(() => _selectedOutputDevice = devices.last);
              }
            }
          }
        }

        if (mounted) {
          setState(() {
            _outputDevices = devices;
            // Update selected device to match one from the list if available
            if (_selectedOutputDevice != null) {
              final matching = devices.firstWhere(
                (d) => d.name == _selectedOutputDevice!.name,
                orElse: () => _selectedOutputDevice!,
              );
              _selectedOutputDevice = matching;
            } else if (devices.isNotEmpty) {
              _selectedOutputDevice = devices.firstWhere(
                (d) => d.isDefault,
                orElse: () => devices.first,
              );
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Get output devices error: $e');
    }
  }

  Future<void> _getInputDevices() async {
    try {
      final result = await Process.run('pactl', ['list', 'short', 'sources']);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        final List<AudioDevice> devices = [];
        String? defaultSource;

        // Get default source (excluding monitors)
        final defaultResult = await Process.run('pactl', ['get-default-source']);
        if (defaultResult.exitCode == 0) {
          defaultSource = defaultResult.stdout.toString().trim();
        }

        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          final parts = line.split('\t');
          if (parts.length >= 2) {
            final sourceIndex = parts[0];
            final sourceName = parts[1];
            
            // Skip monitor sources
            if (sourceName.contains('.monitor')) continue;

            String description = sourceName;

            // Get better description
            try {
              final sourceInfo = await Process.run(
                'pactl',
                ['list', 'sources'],
              );
              if (sourceInfo.exitCode == 0) {
                final sourceInfoLines = sourceInfo.stdout.toString().split('\n');
                bool inSource = false;
                for (final infoLine in sourceInfoLines) {
                  if (infoLine.contains('Source #$sourceIndex') ||
                      infoLine.contains('Name: $sourceName')) {
                    inSource = true;
                    continue;
                  }
                  if (inSource && infoLine.contains('Description:')) {
                    description = infoLine.split('Description:')[1].trim();
                    break;
                  }
                  if (inSource && infoLine.startsWith('Source #')) {
                    break;
                  }
                }
              }
            } catch (_) {}

            final isDefault = sourceName == defaultSource;
            
            // Check if device already exists to avoid duplicates
            if (!devices.any((d) => d.name == sourceName)) {
              devices.add(AudioDevice(
                name: sourceName,
                description: description,
                isInput: true,
                isDefault: isDefault,
              ));

              if (isDefault && _selectedInputDevice == null) {
                setState(() => _selectedInputDevice = devices.last);
              }
            }
          }
        }

        if (mounted) {
          setState(() {
            _inputDevices = devices;
            // Update selected device to match one from the list if available
            if (_selectedInputDevice != null) {
              final matching = devices.firstWhere(
                (d) => d.name == _selectedInputDevice!.name,
                orElse: () => _selectedInputDevice!,
              );
              _selectedInputDevice = matching;
            } else if (devices.isNotEmpty) {
              _selectedInputDevice = devices.firstWhere(
                (d) => d.isDefault,
                orElse: () => devices.first,
              );
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Get input devices error: $e');
    }
  }

  Future<void> _getOutputVolume() async {
    try {
      final result = await Process.run('pactl', [
        'get-sink-volume',
        '@DEFAULT_SINK@',
      ]);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final match = RegExp(r'(\d+)%').firstMatch(output);
        if (match != null) {
          final volume = int.tryParse(match.group(1) ?? '') ?? 75;
          if (mounted) {
            setState(() => _outputVolume = volume.toDouble());
          }
        }
      }
    } catch (e) {
      debugPrint('Get output volume error: $e');
    }
  }

  Future<void> _getInputVolume() async {
    try {
      final result = await Process.run('pactl', [
        'get-source-volume',
        '@DEFAULT_SOURCE@',
      ]);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        final match = RegExp(r'(\d+)%').firstMatch(output);
        if (match != null) {
          final volume = int.tryParse(match.group(1) ?? '') ?? 75;
          if (mounted) {
            setState(() => _inputVolume = volume.toDouble());
          }
        }
      }
    } catch (e) {
      debugPrint('Get input volume error: $e');
    }
  }

  Future<void> _getBalance() async {
    try {
      // Balance is typically stored per-channel, we'll calculate from left/right
      final result = await Process.run('pactl', [
        'get-sink-volume',
        '@DEFAULT_SINK@',
      ]);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        // Try to extract left and right channel volumes
        final matches = RegExp(r'(\d+)%').allMatches(output).toList();
        if (matches.length >= 2) {
          final left = int.tryParse(matches[0].group(1) ?? '') ?? 50;
          final right = int.tryParse(matches[1].group(1) ?? '') ?? 50;
          // Calculate balance: 0 = left, 50 = center, 100 = right
          final balance = ((right - left) / 2) + 50;
          if (mounted) {
            setState(() => _balance = balance.clamp(0.0, 100.0));
          }
        }
      }
    } catch (e) {
      debugPrint('Get balance error: $e');
    }
  }

  Future<void> _setOutputDevice(AudioDevice device) async {
    try {
      await Process.run('pactl', ['set-default-sink', device.name]);
      setState(() => _selectedOutputDevice = device);
      await _refreshAudioInfo();
    } catch (e) {
      debugPrint('Set output device error: $e');
    }
  }

  Future<void> _setInputDevice(AudioDevice device) async {
    try {
      await Process.run('pactl', ['set-default-source', device.name]);
      setState(() => _selectedInputDevice = device);
      await _refreshAudioInfo();
    } catch (e) {
      debugPrint('Set input device error: $e');
    }
  }

  Future<void> _setOutputVolume(double value) async {
    setState(() => _outputVolume = value);
    try {
      final volumePercent = value.toInt();
      await Process.run('pactl', [
        'set-sink-volume',
        '@DEFAULT_SINK@',
        '$volumePercent%',
      ]);
    } catch (e) {
      debugPrint('Set output volume error: $e');
    }
  }

  Future<void> _setInputVolume(double value) async {
    setState(() => _inputVolume = value);
    try {
      final volumePercent = value.toInt();
      await Process.run('pactl', [
        'set-source-volume',
        '@DEFAULT_SOURCE@',
        '$volumePercent%',
      ]);
    } catch (e) {
      debugPrint('Set input volume error: $e');
    }
  }

  Future<void> _setBalance(double value) async {
    setState(() => _balance = value);
    try {
      // Calculate left and right volumes from balance
      // Balance: 0 = left only, 50 = center, 100 = right only
      final diff = (value - 50) * 2; // -100 to +100
      final leftPercent = (_outputVolume - diff).clamp(0.0, 100.0);
      final rightPercent = (_outputVolume + diff).clamp(0.0, 100.0);

      await Process.run('pactl', [
        'set-sink-volume',
        '@DEFAULT_SINK@',
        '${leftPercent.toInt()}%',
        '${rightPercent.toInt()}%',
      ]);
    } catch (e) {
      debugPrint('Set balance error: $e');
    }
  }

  Future<void> _testOutput() async {
    try {
      // Play a test sound
      await Process.run('paplay', ['/usr/share/sounds/freedesktop/stereo/bell.ogg']);
    } catch (_) {
      // Try alternative test sound
      try {
        await Process.run('speaker-test', ['-t', 'sine', '-f', '1000', '-l', '1', '-c', '2']);
      } catch (_) {}
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
                  'Sound',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                // Output Section
                _buildOutputSection(),
                const SizedBox(height: 32),
                // Input Section
                _buildInputSection(),
                const SizedBox(height: 32),
                // Sounds Section
                _buildSoundsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutputSection() {
    return _buildSection(
      'Output',
      children: [
        _buildDeviceDropdown(
          'Output Device',
          _selectedOutputDevice,
          _outputDevices,
          Icons.headphones_rounded,
          (device) => _setOutputDevice(device),
          showTestButton: true,
        ),
        const SizedBox(height: 24),
        _buildVolumeSlider(
          'Output Volume',
          _outputVolume,
          Icons.volume_up_rounded,
          _setOutputVolume,
        ),
        const SizedBox(height: 24),
        _buildBalanceSlider(),
        const SizedBox(height: 24),
        _buildToggleSetting(
          'Overamplification',
          _overamplification,
          'Allow volume to exceed 100%, with reduced sound quality',
          (value) => setState(() => _overamplification = value),
        ),
      ],
    );
  }

  Widget _buildInputSection() {
    return _buildSection(
      'Input',
      children: [
        _buildDeviceDropdown(
          'Input Device',
          _selectedInputDevice,
          _inputDevices,
          Icons.mic_rounded,
          (device) => _setInputDevice(device),
        ),
        const SizedBox(height: 24),
        _buildVolumeSlider(
          'Input Volume',
          _inputVolume,
          Icons.mic_rounded,
          _setInputVolume,
        ),
      ],
    );
  }

  Widget _buildSoundsSection() {
    return _buildSection(
      'Sounds',
      children: [
        _buildClickableItem(
          'Volume Levels',
          onTap: () {
            // TODO: Navigate to volume levels page
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Volume Levels - Coming soon')),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildClickableItem(
          'Alert Sound',
          value: 'Default',
          onTap: () {
            // TODO: Navigate to alert sound selection
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Alert Sound - Coming soon')),
            );
          },
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
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDeviceDropdown(
    String label,
    AudioDevice? selectedDevice,
    List<AudioDevice> devices,
    IconData icon,
    ValueChanged<AudioDevice> onChanged, {
    bool showTestButton = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.white70),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            if (showTestButton) ...[
              const Spacer(),
              TextButton(
                onPressed: _testOutput,
                child: const Text(
                  'Test...',
                  style: TextStyle(color: Colors.blueAccent),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: DropdownButton<AudioDevice>(
            value: selectedDevice,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: const Color.fromARGB(255, 45, 45, 45),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            items: devices.map((device) {
              return DropdownMenuItem<AudioDevice>(
                value: device,
                child: Text(
                  device.description,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) onChanged(newValue);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVolumeSlider(
    String label,
    double value,
    IconData icon,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.white70),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            activeTrackColor: Colors.blueAccent,
            inactiveTrackColor: Colors.white.withOpacity(0.2),
            thumbColor: Colors.white,
            overlayShape: SliderComponentShape.noOverlay,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value.clamp(0.0, _overamplification ? 150.0 : 100.0),
            min: 0,
            max: _overamplification ? 150.0 : 100.0,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Balance',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            activeTrackColor: Colors.white.withOpacity(0.2),
            inactiveTrackColor: Colors.white.withOpacity(0.2),
            thumbColor: Colors.white,
            overlayShape: SliderComponentShape.noOverlay,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: _balance.clamp(0.0, 100.0),
            min: 0,
            max: 100,
            onChanged: _setBalance,
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

  Widget _buildClickableItem(
    String label, {
    String? value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            Row(
              children: [
                if (value != null) ...[
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Colors.white54,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

