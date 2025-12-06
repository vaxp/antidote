import 'package:flutter/material.dart';


class VolumeSlider extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final double max;
  final ValueChanged<double> onChanged;

  const VolumeSlider({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.max = 100.0,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.white70),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            activeTrackColor: Colors.blueAccent,
            inactiveTrackColor: Colors.white.withOpacity(0.2),
            thumbColor: Colors.white,
            overlayShape: SliderComponentShape.noOverlay,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value.clamp(0.0, max),
            min: 0,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}


class BalanceSlider extends StatelessWidget {
  final double balance;
  final ValueChanged<double> onChanged;

  const BalanceSlider({
    super.key,
    required this.balance,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Balance',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            activeTrackColor: Colors.white.withOpacity(0.2),
            inactiveTrackColor: Colors.white.withOpacity(0.2),
            thumbColor: Colors.white,
            overlayShape: SliderComponentShape.noOverlay,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: balance.clamp(0.0, 100.0),
            min: 0,
            max: 100,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
