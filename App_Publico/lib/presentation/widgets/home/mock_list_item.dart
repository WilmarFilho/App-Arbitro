import 'package:flutter/material.dart';

class MockListItem extends StatelessWidget {
  final String sectionType;

  const MockListItem({
    super.key,
    required this.sectionType,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon = sectionType == 'Árbitros' 
      ? Icons.person 
      : Icons.workspace_premium;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 15),
          Text(
            'Item de $sectionType Mockado',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}