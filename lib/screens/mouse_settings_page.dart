import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:antidote/features/mouse_settings/mouse_settings.dart';

/// Mouse Settings Page using BLoC pattern
class MouseSettingsPage extends StatelessWidget {
  const MouseSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MouseSettingsBloc()..add(const LoadMouseSettings()),
      child: const MouseSettingsView(),
    );
  }
}

/// The main view widget that builds the UI
class MouseSettingsView extends StatelessWidget {
  const MouseSettingsView({super.key});

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
            const _Tabs(),
            const SizedBox(height: 24),
            const _TabContent(),
            const SizedBox(height: 32),
            const _TestButton(),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Tabs
// ============================================================================

class _Tabs extends StatelessWidget {
  const _Tabs();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MouseSettingsBloc, MouseSettingsState>(
      buildWhen: (previous, current) =>
          previous.selectedTab != current.selectedTab,
      builder: (context, state) {
        return Row(
          children: [
            _TabButton(
              label: 'Mouse',
              isSelected: state.selectedTab == 0,
              onTap: () =>
                  context.read<MouseSettingsBloc>().add(const ChangeTab(0)),
            ),
            const SizedBox(width: 8),
            _TabButton(
              label: 'Touchpad',
              isSelected: state.selectedTab == 1,
              onTap: () =>
                  context.read<MouseSettingsBloc>().add(const ChangeTab(1)),
            ),
          ],
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
}

// ============================================================================
// Tab Content
// ============================================================================

class _TabContent extends StatelessWidget {
  const _TabContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MouseSettingsBloc, MouseSettingsState>(
      buildWhen: (previous, current) =>
          previous.selectedTab != current.selectedTab,
      builder: (context, state) {
        return state.selectedTab == 0
            ? const _MouseTab()
            : const _TouchpadTab();
      },
    );
  }
}

// ============================================================================
// Mouse Tab
// ============================================================================

class _MouseTab extends StatelessWidget {
  const _MouseTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _GeneralSection(),
        SizedBox(height: 24),
        _MouseSection(),
        SizedBox(height: 24),
        _ScrollDirectionSection(),
      ],
    );
  }
}

class _GeneralSection extends StatelessWidget {
  const _GeneralSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MouseSettingsBloc, MouseSettingsState>(
      buildWhen: (previous, current) =>
          previous.primaryButton != current.primaryButton,
      builder: (context, state) {
        return _Section(
          title: 'General',
          children: [
            Column(
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
                      child: _SegmentedButton(
                        label: 'Left',
                        isSelected: state.primaryButton == 'left',
                        onTap: () => context.read<MouseSettingsBloc>().add(
                          const SetPrimaryButton('left'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SegmentedButton(
                        label: 'Right',
                        isSelected: state.primaryButton == 'right',
                        onTap: () => context.read<MouseSettingsBloc>().add(
                          const SetPrimaryButton('right'),
                        ),
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
            ),
          ],
        );
      },
    );
  }
}

class _MouseSection extends StatelessWidget {
  const _MouseSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MouseSettingsBloc, MouseSettingsState>(
      buildWhen: (previous, current) =>
          previous.mousePointerSpeed != current.mousePointerSpeed ||
          previous.mouseAcceleration != current.mouseAcceleration,
      builder: (context, state) {
        return _Section(
          title: 'Mouse',
          children: [
            _PointerSpeedSlider(
              label: 'Pointer Speed',
              value: state.mousePointerSpeed,
              onChanged: (value) => context.read<MouseSettingsBloc>().add(
                SetMousePointerSpeed(value),
              ),
            ),
            const SizedBox(height: 24),
            Row(
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
                      const Text(
                        'Mouse Acceleration',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: state.mouseAcceleration,
                  onChanged: (value) => context.read<MouseSettingsBloc>().add(
                    SetMouseAcceleration(value),
                  ),
                  activeColor: Colors.blueAccent,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ScrollDirectionSection extends StatelessWidget {
  const _ScrollDirectionSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MouseSettingsBloc, MouseSettingsState>(
      buildWhen: (previous, current) =>
          previous.scrollDirection != current.scrollDirection,
      builder: (context, state) {
        return _Section(
          title: 'Scroll Direction',
          children: [
            _RadioOption(
              title: 'Traditional',
              description: 'Scrolling moves the view',
              isSelected: state.scrollDirection == 'traditional',
              icon: Icons.arrow_upward_rounded,
              onTap: () => context.read<MouseSettingsBloc>().add(
                const SetScrollDirection('traditional'),
              ),
            ),
            const SizedBox(height: 16),
            _RadioOption(
              title: 'Natural',
              description: 'Scrolling moves the content',
              isSelected: state.scrollDirection == 'natural',
              icon: Icons.arrow_downward_rounded,
              onTap: () => context.read<MouseSettingsBloc>().add(
                const SetScrollDirection('natural'),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// Touchpad Tab
// ============================================================================

class _TouchpadTab extends StatelessWidget {
  const _TouchpadTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        const _TouchpadSection(),
        const SizedBox(height: 24),
        const _ClickingSection(),
        const SizedBox(height: 24),
        const _TapToClickSection(),
      ],
    );
  }
}

class _TouchpadSection extends StatelessWidget {
  const _TouchpadSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MouseSettingsBloc, MouseSettingsState>(
      buildWhen: (previous, current) =>
          previous.touchpadEnabled != current.touchpadEnabled ||
          previous.disableWhileTyping != current.disableWhileTyping ||
          previous.touchpadPointerSpeed != current.touchpadPointerSpeed,
      builder: (context, state) {
        return _Section(
          title: 'Touchpad',
          children: [
            _ToggleSetting(
              label: 'Touchpad',
              value: state.touchpadEnabled,
              onChanged: (value) => context.read<MouseSettingsBloc>().add(
                SetTouchpadEnabled(value),
              ),
            ),
            const SizedBox(height: 16),
            _ToggleSetting(
              label: 'Disable Touchpad While Typing',
              value: state.disableWhileTyping,
              onChanged: (value) => context.read<MouseSettingsBloc>().add(
                SetDisableWhileTyping(value),
              ),
            ),
            const SizedBox(height: 24),
            _PointerSpeedSlider(
              label: 'Pointer Speed',
              value: state.touchpadPointerSpeed,
              onChanged: (value) => context.read<MouseSettingsBloc>().add(
                SetTouchpadPointerSpeed(value),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ClickingSection extends StatelessWidget {
  const _ClickingSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MouseSettingsBloc, MouseSettingsState>(
      buildWhen: (previous, current) =>
          previous.secondaryClick != current.secondaryClick,
      builder: (context, state) {
        return _Section(
          title: 'Clicking',
          children: [
            const Text(
              'Secondary Click',
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
                  child: _SegmentedButton(
                    label: 'Two-finger',
                    isSelected: state.secondaryClick == 'two-finger',
                    onTap: () => context.read<MouseSettingsBloc>().add(
                      const SetSecondaryClick('two-finger'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SegmentedButton(
                    label: 'Corner',
                    isSelected: state.secondaryClick == 'corner',
                    onTap: () => context.read<MouseSettingsBloc>().add(
                      const SetSecondaryClick('corner'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _TapToClickSection extends StatelessWidget {
  const _TapToClickSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MouseSettingsBloc, MouseSettingsState>(
      buildWhen: (previous, current) =>
          previous.tapToClick != current.tapToClick,
      builder: (context, state) {
        return _Section(
          title: 'Tap to Click',
          children: [
            _ToggleSetting(
              label: 'Tap to Click',
              description: 'Single finger tap to click buttons',
              value: state.tapToClick,
              onChanged: (value) =>
                  context.read<MouseSettingsBloc>().add(SetTapToClick(value)),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// Test Button
// ============================================================================

class _TestButton extends StatelessWidget {
  const _TestButton();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Test your mouse settings here')),
          );
        },
        icon: const Icon(Icons.mouse_rounded),
        label: const Text('Test Mouse'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }
}

// ============================================================================
// Shared UI Components
// ============================================================================

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

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
}

class _SegmentedButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentedButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _PointerSpeedSlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _PointerSpeedSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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
              style: TextStyle(fontSize: 12, color: Colors.white70),
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
                  value: value.clamp(0.0, 1.0),
                  min: 0,
                  max: 1,
                  onChanged: onChanged,
                ),
              ),
            ),
            const Text(
              'Fast',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ],
    );
  }
}

class _RadioOption extends StatelessWidget {
  final String title;
  final String description;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  const _RadioOption({
    required this.title,
    required this.description,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
}

class _ToggleSetting extends StatelessWidget {
  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleSetting({
    required this.label,
    this.description,
    required this.value,
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
