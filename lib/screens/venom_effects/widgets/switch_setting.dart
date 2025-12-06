import 'package:flutter/material.dart';

class SwitchSetting extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SwitchSetting({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70)),
        Transform.scale(
          scale: 0.8,
          child: Switch(value: value, onChanged: onChanged),
        ),
      ],
    );
  }
}
