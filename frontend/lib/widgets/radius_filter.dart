import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class RadiusFilter extends StatelessWidget {
  final double currentRadiusKm;
  final ValueChanged<double> onRadiusChanged;

  const RadiusFilter({
    super.key,
    required this.currentRadiusKm,
    required this.onRadiusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final distances = [2.0, 5.0, 10.0, 20.0];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: distances.map((km) {
        final isSelected = currentRadiusKm == km;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
            selected: isSelected,
            label: Text("${km.toInt()} km"),
            selectedColor: AppColors.primary,
            backgroundColor: Colors.white,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
            onSelected: (_) => onRadiusChanged(km),
          ),
        );
      }).toList(),
    );
  }
}
