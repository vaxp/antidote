import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:antidote/features/display_settings/display_settings.dart';
import 'package:antidote/screens/display_settings/widgets/settings_card.dart';

class NightLightCard extends StatelessWidget {
  const NightLightCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      buildWhen: (previous, current) =>
          previous.nightLight != current.nightLight,
      builder: (context, state) {
        return SettingsCard(
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
                      borderRadius: BorderRadius.circular(8),
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
