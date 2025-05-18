import 'package:flutter/material.dart';
import '../models/task.dart';

class PrioritySelector extends StatelessWidget {
  final Priority selectedPriority;
  final Function(Priority) onPriorityChanged;

  const PrioritySelector({
    Key? key,
    required this.selectedPriority,
    required this.onPriorityChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priority*',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _PriorityOption(
                label: 'HIGH',
                color: Colors.red,
                isSelected: selectedPriority == Priority.high,
                onTap: () => onPriorityChanged(Priority.high),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PriorityOption(
                label: 'MEDIUM',
                color: Colors.orange,
                isSelected: selectedPriority == Priority.medium,
                onTap: () => onPriorityChanged(Priority.medium),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PriorityOption(
                label: 'LOW',
                color: Colors.green,
                isSelected: selectedPriority == Priority.low,
                onTap: () => onPriorityChanged(Priority.low),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PriorityOption extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PriorityOption({
    Key? key,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
