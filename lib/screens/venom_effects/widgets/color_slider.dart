import 'package:flutter/material.dart';

class ColorSlider extends StatelessWidget {
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;
  final bool enabled;

  const ColorSlider({
    super.key,
    required this.value,
    required this.color,
    required this.onChanged,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: SizedBox(
        height: 20,
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            thumbColor: Colors.white,
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: SliderComponentShape.noOverlay,
          ),
          child: Slider(
            value: value,
            min: 0,
            max: 1,
            onChanged: enabled ? onChanged : null,
          ),
        ),
      ),
    );
  }
}
