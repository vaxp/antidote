import 'package:flutter/material.dart';
import 'package:antidote/screens/shortcuts/ShortcutsPage.dart';
import 'package:antidote/screens/keyboard_settings/widgets/section_container.dart';
import 'package:antidote/screens/keyboard_settings/widgets/clickable_item.dart';

class KeyboardShortcutsSection extends StatelessWidget {
  const KeyboardShortcutsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: 'Keyboard Shortcuts',
      children: [
        ClickableItem(
          label: 'View and Customize Shortcuts',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ShortcutsPage()),
            );
          },
        ),
      ],
    );
  }
}
