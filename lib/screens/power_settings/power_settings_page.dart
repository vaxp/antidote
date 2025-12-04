import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:antidote/features/power_settings/power_settings.dart';

/// Power Settings Page using BLoC pattern
class PowerSettingsPage extends StatelessWidget {
  const PowerSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PowerSettingsBloc()..add(const LoadPowerSettings()),
      child: const PowerSettingsView(),
    );
  }
}

/// The main view widget that builds the UI
class PowerSettingsView extends StatelessWidget {
  const PowerSettingsView({super.key});

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
              'Power',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Opacity(
              opacity: 0.6,
              child: Text(
                'Manage battery and power settings',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w300,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const _BatteryTile(),
            const SizedBox(height: 32),
            const _PowerProfilesSection(),
            const SizedBox(height: 32),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 24),
            const _SystemActionsSection(),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Battery Tile
// ============================================================================

class _BatteryTile extends StatelessWidget {
  const _BatteryTile();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PowerSettingsBloc, PowerSettingsState>(
      buildWhen: (previous, current) =>
          previous.batteryLevel != current.batteryLevel ||
          previous.isCharging != current.isCharging,
      builder: (context, state) {
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
                state.isCharging
                    ? Icons.battery_charging_full_rounded
                    : Icons.battery_std_rounded,
                color: state.isCharging ? Colors.greenAccent : Colors.white70,
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
                        value: state.batteryLevel / 100,
                        minHeight: 6,
                        backgroundColor: Colors.white10,
                        color: state.isCharging
                            ? Colors.greenAccent
                            : (state.batteryLevel <= 20
                                  ? Colors.redAccent
                                  : Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${state.batteryLevel.toInt()}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
// Power Profiles Section
// ============================================================================

class _PowerProfilesSection extends StatelessWidget {
  const _PowerProfilesSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          child: const Row(
            children: [
              _ProfileButton(
                label: 'Saver',
                icon: Icons.eco_rounded,
                profileId: 'power-saver',
                color: Colors.greenAccent,
              ),
              _ProfileButton(
                label: 'Balanced',
                icon: Icons.balance_rounded,
                profileId: 'balanced',
                color: Colors.blueAccent,
              ),
              _ProfileButton(
                label: 'Boost',
                icon: Icons.speed_rounded,
                profileId: 'performance',
                color: Colors.redAccent,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String profileId;
  final Color color;

  const _ProfileButton({
    required this.label,
    required this.icon,
    required this.profileId,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PowerSettingsBloc, PowerSettingsState>(
      buildWhen: (previous, current) =>
          previous.activePowerProfile != current.activePowerProfile,
      builder: (context, state) {
        final isActive = state.activePowerProfile == profileId;
        return Expanded(
          child: InkWell(
            onTap: () => context.read<PowerSettingsBloc>().add(
              SetPowerProfile(profileId),
            ),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isActive
                    ? color.withOpacity(0.14)
                    : Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isActive
                      ? color.withOpacity(0.35)
                      : Colors.transparent,
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
                                colors: [
                                  color.withOpacity(0.28),
                                  color.withOpacity(0.06),
                                ],
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
                            color: Colors.black.withOpacity(
                              isActive ? 0.22 : 0.08,
                            ),
                            blurRadius: isActive ? 14 : 6,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        size: 18,
                        color: isActive ? Colors.white : Colors.white54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: isActive ? Colors.white : Colors.white54,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// System Actions Section
// ============================================================================

class _SystemActionsSection extends StatelessWidget {
  const _SystemActionsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            _PowerActionButton(
              icon: Icons.power_settings_new_rounded,
              color: Colors.redAccent,
              label: 'Shutdown',
              action: 'shutdown',
            ),
            _PowerActionButton(
              icon: Icons.restart_alt_rounded,
              color: Colors.orangeAccent,
              label: 'Reboot',
              action: 'reboot',
            ),
            _PowerActionButton(
              icon: Icons.bedtime_rounded,
              color: Colors.blueAccent,
              label: 'Suspend',
              action: 'suspend',
            ),
            _PowerActionButton(
              icon: Icons.logout_rounded,
              color: Colors.grey,
              label: 'Logout',
              action: 'logout',
            ),
          ],
        ),
      ],
    );
  }
}

class _PowerActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String action;

  const _PowerActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () =>
              context.read<PowerSettingsBloc>().add(PerformPowerAction(action)),
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
          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7)),
        ),
      ],
    );
  }
}
