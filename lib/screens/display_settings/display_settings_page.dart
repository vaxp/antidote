import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:antidote/features/display_settings/display_settings.dart';
import 'package:antidote/screens/display_settings/widgets/display_header.dart';
import 'package:antidote/screens/display_settings/widgets/settings_grid.dart';
import 'package:antidote/screens/display_settings/widgets/fractional_scaling_section.dart';


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
            const DisplayHeader(),
            const SizedBox(height: 48),
            const SettingsGrid(),
            const SizedBox(height: 24),
            const FractionalScalingSection(),
          ],
        ),
      ),
    );
  }
}
