import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:antidote/features/audio_settings/audio_settings.dart';

/// Audio Settings Page using BLoC pattern
class AudioSettingsPage extends StatelessWidget {
  const AudioSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AudioSettingsBloc()..add(const LoadAudioSettings()),
      child: const AudioSettingsView(),
    );
  }
}

/// The main view widget that builds the UI
class AudioSettingsView extends StatelessWidget {
  const AudioSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sound',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure audio devices and settings',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 48),
            const _OutputSection(),
            const SizedBox(height: 32),
            const _InputSection(),
            const SizedBox(height: 32),
            const _SoundsSection(),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Output Section
// ============================================================================

class _OutputSection extends StatelessWidget {
  const _OutputSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioSettingsBloc, AudioSettingsState>(
      builder: (context, state) {
        return _SectionContainer(
          title: 'Output',
          children: [
            _DeviceDropdown(
              label: 'Output Device',
              selectedDevice: state.selectedOutputDevice,
              devices: state.outputDevices,
              icon: Icons.headphones_rounded,
              onChanged: (device) => context.read<AudioSettingsBloc>().add(
                SetOutputDevice(device),
              ),
              showTestButton: true,
              onTest: () => context.read<AudioSettingsBloc>().add(
                const TestAudioOutput(),
              ),
            ),
            const SizedBox(height: 24),
            _VolumeSlider(
              label: 'Output Volume',
              value: state.outputVolume,
              icon: Icons.volume_up_rounded,
              max: state.overamplification ? 150.0 : 100.0,
              onChanged: (value) =>
                  context.read<AudioSettingsBloc>().add(SetOutputVolume(value)),
            ),
            const SizedBox(height: 24),
            _BalanceSlider(
              balance: state.balance,
              onChanged: (value) =>
                  context.read<AudioSettingsBloc>().add(SetBalance(value)),
            ),
            const SizedBox(height: 24),
            _ToggleSetting(
              label: 'Overamplification',
              value: state.overamplification,
              description:
                  'Allow volume to exceed 100%, with reduced sound quality',
              onChanged: (value) => context.read<AudioSettingsBloc>().add(
                SetOveramplification(value),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// Input Section
// ============================================================================

class _InputSection extends StatelessWidget {
  const _InputSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioSettingsBloc, AudioSettingsState>(
      builder: (context, state) {
        return _SectionContainer(
          title: 'Input',
          children: [
            _DeviceDropdown(
              label: 'Input Device',
              selectedDevice: state.selectedInputDevice,
              devices: state.inputDevices,
              icon: Icons.mic_rounded,
              onChanged: (device) =>
                  context.read<AudioSettingsBloc>().add(SetInputDevice(device)),
            ),
            const SizedBox(height: 24),
            _VolumeSlider(
              label: 'Input Volume',
              value: state.inputVolume,
              icon: Icons.mic_rounded,
              onChanged: (value) =>
                  context.read<AudioSettingsBloc>().add(SetInputVolume(value)),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// Sounds Section
// ============================================================================

class _SoundsSection extends StatelessWidget {
  const _SoundsSection();

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      title: 'Sounds',
      children: [
        _ClickableItem(
          label: 'Volume Levels',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Volume Levels - Coming soon')),
            );
          },
        ),
        const SizedBox(height: 16),
        _ClickableItem(
          label: 'Alert Sound',
          value: 'Default',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Alert Sound - Coming soon')),
            );
          },
        ),
      ],
    );
  }
}

// ============================================================================
// Shared UI Components
// ============================================================================

class _SectionContainer extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionContainer({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
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
}

class _DeviceDropdown extends StatelessWidget {
  final String label;
  final AudioDevice? selectedDevice;
  final List<AudioDevice> devices;
  final IconData icon;
  final ValueChanged<AudioDevice> onChanged;
  final bool showTestButton;
  final VoidCallback? onTest;

  const _DeviceDropdown({
    required this.label,
    required this.selectedDevice,
    required this.devices,
    required this.icon,
    required this.onChanged,
    this.showTestButton = false,
    this.onTest,
  });

  @override
  Widget build(BuildContext context) {
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
            if (showTestButton && onTest != null) ...[
              const Spacer(),
              TextButton(
                onPressed: onTest,
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
            dropdownColor: const Color.fromARGB(255, 18, 22, 32),
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
}

class _VolumeSlider extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final double max;
  final ValueChanged<double> onChanged;

  const _VolumeSlider({
    required this.label,
    required this.value,
    required this.icon,
    this.max = 100.0,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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
            value: value.clamp(0.0, max),
            min: 0,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _BalanceSlider extends StatelessWidget {
  final double balance;
  final ValueChanged<double> onChanged;

  const _BalanceSlider({required this.balance, required this.onChanged});

  @override
  Widget build(BuildContext context) {
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
            value: balance.clamp(0.0, 100.0),
            min: 0,
            max: 100,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _ToggleSetting extends StatelessWidget {
  final String label;
  final bool value;
  final String? description;
  final ValueChanged<bool> onChanged;

  const _ToggleSetting({
    required this.label,
    required this.value,
    this.description,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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
                  description!,
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
}

class _ClickableItem extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback? onTap;

  const _ClickableItem({required this.label, this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
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
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
            Row(
              children: [
                if (value != null) ...[
                  Text(
                    value!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.6),
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
