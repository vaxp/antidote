import 'package:flutter/material.dart';

class RadioOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const RadioOption({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Radio(
            value: isSelected,
            groupValue: true,
            onChanged: (_) => onTap(),
            activeColor: Colors.blueAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
