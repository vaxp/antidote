import 'package:flutter/material.dart';
import 'section_container.dart';
import 'common_widgets.dart';


class SoundsSection extends StatelessWidget {
  const SoundsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: 'Sounds',
      children: [
        ClickableItem(
          label: 'Volume Levels',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Volume Levels - Coming soon')),
            );
          },
        ),
        const SizedBox(height: 16),
        ClickableItem(
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
