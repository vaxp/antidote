import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:antidote/features/keyboard_settings/keyboard_settings.dart';
import 'package:antidote/screens/keyboard_settings/widgets/input_sources_section.dart';
import 'package:antidote/screens/keyboard_settings/widgets/input_source_switching_section.dart';
import 'package:antidote/screens/keyboard_settings/widgets/special_character_entry_section.dart';
import 'package:antidote/screens/keyboard_settings/widgets/keyboard_shortcuts_section.dart';


class KeyboardSettingsPage extends StatelessWidget {
  const KeyboardSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          KeyboardSettingsBloc()..add(const LoadKeyboardSettings()),
      child: const KeyboardSettingsView(),
    );
  }
}


class KeyboardSettingsView extends StatelessWidget {
  const KeyboardSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<KeyboardSettingsBloc, KeyboardSettingsState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage &&
          current.errorMessage != null,
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Keyboard',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Configure keyboard and input settings',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 48),
              const InputSourcesSection(),
              const SizedBox(height: 24),
              const InputSourceSwitchingSection(),
              const SizedBox(height: 24),
              const SpecialCharacterEntrySection(),
              const SizedBox(height: 24),
              const KeyboardShortcutsSection(),
            ],
          ),
        ),
      ),
    );
  }
}
