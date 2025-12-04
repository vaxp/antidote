import 'package:antidote/core/glassmorphic_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:antidote/features/display_settings/display_settings.dart';

/// Display Settings Page using BLoC pattern
class DisplaySettingsPage extends StatelessWidget {
  const DisplaySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DisplaySettingsBloc()..add(const InitializeDisplaySettings()),
      child: const DisplaySettingsView(),
    );
  }
}

/// The main view widget that builds the UI
class DisplaySettingsView extends StatelessWidget {
  const DisplaySettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Header(),
            const SizedBox(height: 48),
            const _SettingsGrid(),
            const SizedBox(height: 24),
            const _FractionalScalingSection(),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Header
// ============================================================================

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Display',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Manage your display settings',
          style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.6)),
        ),
      ],
    );
  }
}

// ============================================================================
// Settings Grid
// ============================================================================

class _SettingsGrid extends StatelessWidget {
  const _SettingsGrid();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      builder: (context, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isTwoColumn = constraints.maxWidth > 1200;
            return Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                SizedBox(
                  width: isTwoColumn
                      ? (constraints.maxWidth - 24) / 2
                      : double.infinity,
                  child: const _ResolutionCard(),
                ),
                SizedBox(
                  width: isTwoColumn
                      ? (constraints.maxWidth - 24) / 2
                      : double.infinity,
                  child: const _RefreshRateCard(),
                ),
                if (state.brightnessSupported)
                  SizedBox(
                    width: isTwoColumn
                        ? (constraints.maxWidth - 24) / 2
                        : double.infinity,
                    child: const _BrightnessCard(),
                  ),
                SizedBox(
                  width: isTwoColumn
                      ? (constraints.maxWidth - 24) / 2
                      : double.infinity,
                  child: const _OrientationCard(),
                ),
                SizedBox(
                  width: isTwoColumn
                      ? (constraints.maxWidth - 24) / 2
                      : double.infinity,
                  child: const _ScaleCard(),
                ),
                SizedBox(
                  width: isTwoColumn
                      ? (constraints.maxWidth - 24) / 2
                      : double.infinity,
                  child: const _NightLightCard(),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ============================================================================
// Resolution Card
// ============================================================================

class _ResolutionCard extends StatelessWidget {
  const _ResolutionCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      buildWhen: (previous, current) =>
          previous.currentResolution != current.currentResolution ||
          previous.nativeResolution != current.nativeResolution ||
          previous.availableResolutions != current.availableResolutions ||
          previous.displayServer != current.displayServer,
      builder: (context, state) {
        return _SettingsCard(
          height: 180,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resolution',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (state.displayServer != 'Unknown')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: state.displayServer == 'Wayland'
                                ? Colors.blue.withOpacity(0.2)
                                : Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: state.displayServer == 'Wayland'
                                  ? Colors.blue.withOpacity(0.5)
                                  : Colors.green.withOpacity(0.5),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            state.displayServer,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: state.displayServer == 'Wayland'
                                  ? Colors.blueAccent
                                  : Colors.greenAccent,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (state.nativeResolution != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Native',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                        Text(
                          '${state.nativeResolution!.width}x${state.nativeResolution!.height}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (state.currentResolution != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${state.currentResolution!.width}x${state.currentResolution!.height} (${state.currentResolution!.aspectRatio})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              if (state.availableResolutions.isNotEmpty)
                Expanded(
                  child: DropdownButton<DisplayResolution>(
                    value: state.currentResolution,
                    isExpanded: true,
                    underline: const SizedBox(),
                    dropdownColor: const Color.fromARGB(255, 12, 12, 12),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    hint: const Text(
                      'Select Resolution',
                      style: TextStyle(color: Colors.white54),
                    ),
                    items: state.availableResolutions.map((resolution) {
                      return DropdownMenuItem<DisplayResolution>(
                        value: resolution,
                        child: Text(resolution.toString()),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        context.read<DisplaySettingsBloc>().add(
                          SetResolution(newValue),
                        );
                      }
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// Refresh Rate Card
// ============================================================================

class _RefreshRateCard extends StatelessWidget {
  const _RefreshRateCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      buildWhen: (previous, current) =>
          previous.refreshRate != current.refreshRate ||
          previous.availableRefreshRates != current.availableRefreshRates,
      builder: (context, state) {
        return _SettingsCard(
          height: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Refresh Rate',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  state.refreshRate,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (state.availableRefreshRates.isNotEmpty)
                Expanded(
                  child: DropdownButton<String>(
                    value:
                        state.availableRefreshRates.contains(state.refreshRate)
                        ? state.refreshRate
                        : null,
                    isExpanded: true,
                    underline: const SizedBox(),
                    dropdownColor: const Color.fromARGB(255, 12, 12, 12),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: state.availableRefreshRates.map((rate) {
                      return DropdownMenuItem<String>(
                        value: rate,
                        child: Text(rate),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        context.read<DisplaySettingsBloc>().add(
                          SetRefreshRate(newValue),
                        );
                      }
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// Brightness Card
// ============================================================================

class _BrightnessCard extends StatelessWidget {
  const _BrightnessCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      buildWhen: (previous, current) =>
          previous.brightness != current.brightness,
      builder: (context, state) {
        return _SettingsCard(
          height: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Brightness',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${state.brightness.round()}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(
                    Icons.brightness_low_rounded,
                    color: Colors.white.withOpacity(0.5),
                    size: 20,
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        activeTrackColor: Colors.blueAccent,
                        inactiveTrackColor: Colors.white.withOpacity(0.2),
                        thumbColor: Colors.white,
                        overlayShape: SliderComponentShape.noOverlay,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                        ),
                      ),
                      child: Slider(
                        value: state.brightness.clamp(0.0, 100.0),
                        min: 0,
                        max: 100,
                        onChanged: (value) => context
                            .read<DisplaySettingsBloc>()
                            .add(SetBrightness(value)),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.brightness_high_rounded,
                    color: Colors.white.withOpacity(0.5),
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// Orientation Card
// ============================================================================

class _OrientationCard extends StatelessWidget {
  const _OrientationCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      buildWhen: (previous, current) =>
          previous.orientation != current.orientation,
      builder: (context, state) {
        return _SettingsCard(
          height: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Orientation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _OrientationButton(
                    label: 'Landscape',
                    icon: Icons.crop_landscape_rounded,
                    isSelected: state.orientation == 'Landscape',
                    onTap: () => context.read<DisplaySettingsBloc>().add(
                      const SetOrientation('Landscape'),
                    ),
                  ),
                  _OrientationButton(
                    label: 'Portrait',
                    icon: Icons.crop_portrait_rounded,
                    isSelected: state.orientation.contains('Portrait'),
                    onTap: () => context.read<DisplaySettingsBloc>().add(
                      const SetOrientation('Portrait Left'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OrientationButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _OrientationButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blueAccent.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Colors.blueAccent
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.blueAccent : Colors.white70,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Scale Card
// ============================================================================

class _ScaleCard extends StatelessWidget {
  const _ScaleCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      buildWhen: (previous, current) => previous.scale != current.scale,
      builder: (context, state) {
        return _SettingsCard(
          height: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Scale',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${state.scale}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ScaleButton(
                      label: '100%',
                      isSelected: state.scale == 100,
                      onTap: () => context.read<DisplaySettingsBloc>().add(
                        const SetScale(100),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ScaleButton(
                      label: '125%',
                      isSelected: state.scale == 125,
                      onTap: () => context.read<DisplaySettingsBloc>().add(
                        const SetScale(125),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ScaleButton(
                      label: '150%',
                      isSelected: state.scale == 150,
                      onTap: () => context.read<DisplaySettingsBloc>().add(
                        const SetScale(150),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ScaleButton(
                      label: '200%',
                      isSelected: state.scale == 200,
                      onTap: () => context.read<DisplaySettingsBloc>().add(
                        const SetScale(200),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScaleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ScaleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blueAccent.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Colors.blueAccent
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Night Light Card
// ============================================================================

class _NightLightCard extends StatelessWidget {
  const _NightLightCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      buildWhen: (previous, current) =>
          previous.nightLight != current.nightLight,
      builder: (context, state) {
        return _SettingsCard(
          height: 120,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: state.nightLight
                          ? Colors.orange.withOpacity(0.2)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.nightlight_round,
                      color: state.nightLight ? Colors.orange : Colors.white54,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Night Light',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Reduce blue light for better sleep',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: state.nightLight,
                onChanged: (value) => context.read<DisplaySettingsBloc>().add(
                  SetNightLight(value),
                ),
                activeColor: Colors.orange,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// Fractional Scaling Section
// ============================================================================

class _FractionalScalingSection extends StatelessWidget {
  const _FractionalScalingSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      buildWhen: (previous, current) =>
          previous.fractionalScaling != current.fractionalScaling,
      builder: (context, state) {
        return _SettingsCard(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Fractional Scaling',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Enable finer scale adjustments (experimental)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
              Switch(
                value: state.fractionalScaling,
                onChanged: (value) => context.read<DisplaySettingsBloc>().add(
                  SetFractionalScaling(value),
                ),
                activeColor: Colors.blueAccent,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// Shared Settings Card
// ============================================================================

class _SettingsCard extends StatelessWidget {
  final double height;
  final Widget child;

  const _SettingsCard({required this.height, required this.child});

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: height,
      borderRadius: 20,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color.fromARGB(30, 17, 17, 17).withOpacity(0.12),
          const Color.fromARGB(30, 17, 17, 17).withOpacity(0.08),
        ],
      ),
      border: 1.2,
      blur: 40,
      borderGradient: const LinearGradient(colors: []),
      padding: const EdgeInsets.all(24),
      child: child,
    );
  }
}
