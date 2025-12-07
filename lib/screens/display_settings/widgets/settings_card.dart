import 'package:flutter/material.dart';

class SettingsCard extends StatelessWidget {
  final double height;
  final Widget child;

  const SettingsCard({super.key, required this.height, required this.child});

  @override
  Widget build(BuildContext context) {

    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }
}
