import 'package:flutter/material.dart';

class RadioOption extends StatelessWidget {
  final String title;
  final String description;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  const RadioOption({
    super.key,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blueAccent.withOpacity(0.1)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Colors.blueAccent
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.blueAccent, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Radio(
              value: isSelected,
              groupValue: true,
              onChanged: (_) => onTap(),
              activeColor: Colors.blueAccent,
            ),
          ],
        ),
      ),
    );
  }
}
