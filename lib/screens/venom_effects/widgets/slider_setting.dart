import 'package:flutter/material.dart';

class SliderSetting extends StatelessWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final bool enabled;

  const SliderSetting({
    super.key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.white60),
              ),
              Text(
                value.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFBB9AF7),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(
              context,
            ).copyWith(overlayShape: SliderComponentShape.noOverlay),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ],
      ),
    );
  }
}
