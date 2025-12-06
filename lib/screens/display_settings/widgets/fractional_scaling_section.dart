import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:antidote/features/display_settings/display_settings.dart';
import 'package:antidote/screens/display_settings/widgets/settings_card.dart';

class FractionalScalingSection extends StatelessWidget {
  const FractionalScalingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplaySettingsBloc, DisplaySettingsState>(
      buildWhen: (previous, current) =>
          previous.fractionalScaling != current.fractionalScaling,
      builder: (context, state) {
        return SettingsCard(
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
