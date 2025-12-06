import 'package:antidote/core/glassmorphic_container.dart';
import 'package:flutter/material.dart';

class SettingsCard extends StatelessWidget {
  final double height;
  final Widget child;

  const SettingsCard({super.key, required this.height, required this.child});

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: height,
      borderRadius: 20,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color.fromARGB(30, 17, 17, 17).withOpacity(0.12),
          const Color.fromARGB(30, 17, 17, 17).withOpacity(0.08),
        ],
      ),
      border: 1.2,
      blur: 40,
      borderGradient: const LinearGradient(colors: []),
      padding: const EdgeInsets.all(24),
      child: child,
    );
  }
}
