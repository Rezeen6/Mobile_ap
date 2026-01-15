import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/meal_model.dart';

class MacroDistributionChart extends StatelessWidget {
  final NutritionInfo? current;
  final NutritionInfo? target;

  const MacroDistributionChart({
    super.key,
    this.current,
    this.target,
  });

  @override
  Widget build(BuildContext context) {
    if (current == null || target == null) {
      return const SizedBox.shrink();
    }

    final proteinPercent = (current!.protein * 4 / target!.calories * 100).clamp(0.0, 100.0);
    final carbsPercent = (current!.carbohydrates * 4 / target!.calories * 100).clamp(0.0, 100.0);
    final fatPercent = (current!.fat * 9 / target!.calories * 100).clamp(0.0, 100.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Macronutrient Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      sections: [
                        PieChartSectionData(
                          value: proteinPercent,
                          color: Colors.blue,
                          title: '${proteinPercent.toStringAsFixed(0)}%',
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: carbsPercent,
                          color: Colors.green,
                          title: '${carbsPercent.toStringAsFixed(0)}%',
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: fatPercent,
                          color: Colors.purple,
                          title: '${fatPercent.toStringAsFixed(0)}%',
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem('Protein', Colors.blue, current!.protein, target!.protein),
                    const SizedBox(height: 12),
                    _buildLegendItem('Carbs', Colors.green, current!.carbohydrates, target!.carbohydrates),
                    const SizedBox(height: 12),
                    _buildLegendItem('Fat', Colors.purple, current!.fat, target!.fat),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, double current, double target) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${current.toStringAsFixed(0)}g / ${target.toStringAsFixed(0)}g',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

