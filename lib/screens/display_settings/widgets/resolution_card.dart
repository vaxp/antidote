import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:antidote/features/display_settings/display_settings.dart';
import 'package:antidote/screens/display_settings/widgets/settings_card.dart';

class ResolutionCard extends StatelessWidget {
  const ResolutionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      buildWhen: (previous, current) =>
          previous.currentResolution != current.currentResolution ||
          previous.nativeResolution != current.nativeResolution ||
          previous.availableResolutions != current.availableResolutions ||
          previous.displayServer != current.displayServer,
      builder: (context, state) {
        return SettingsCard(
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
                    borderRadius: BorderRadius.circular(8),
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
