import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/meal_model.dart';

class TrendChart extends StatelessWidget {
  final Map<DateTime, NutritionInfo> weeklyData;
  final String metric; // 'calories', 'protein', 'carbs', 'fat'
  final Color color;

  const TrendChart({
    super.key,
    required this.weeklyData,
    this.metric = 'calories',
    this.color = Colors.orange,
  });

  @override
  Widget build(BuildContext context) {
    if (weeklyData.isEmpty) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No data available',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    final sortedEntries = weeklyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final spots = sortedEntries.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final nutritionInfo = entry.value.value;
      final value = _getValue(nutritionInfo);
      return FlSpot(index, value);
    }).toList();

    final maxValue = sortedEntries
        .map((e) => _getValue(e.value))
        .reduce((a, b) => a > b ? a : b);

    final minValue = sortedEntries
        .map((e) => _getValue(e.value))
        .reduce((a, b) => a < b ? a : b);

    // Calculate horizontal interval, ensuring it's never zero
    final valueRange = maxValue - minValue;
    final horizontalInterval = valueRange > 0 ? valueRange / 5 : (maxValue > 0 ? maxValue / 5 : 1.0);

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getTitle(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '7 Days',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: horizontalInterval,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200]!,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            _formatValue(value),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < sortedEntries.length) {
                          final date = sortedEntries[value.toInt()].key;
                          return Text(
                            DateFormat('E').format(date),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!),
                    left: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                minX: 0,
                maxX: (sortedEntries.length - 1).toDouble(),
                minY: minValue * 0.8,
                maxY: maxValue * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: color,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipPadding: const EdgeInsets.all(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getValue(NutritionInfo info) {
    switch (metric) {
      case 'calories':
        return info.calories;
      case 'protein':
        return info.protein;
      case 'carbs':
        return info.carbohydrates;
      case 'fat':
        return info.fat;
      default:
        return info.calories;
    }
  }

  String _getTitle() {
    switch (metric) {
      case 'calories':
        return 'Calories Trend';
      case 'protein':
        return 'Protein Trend';
      case 'carbs':
        return 'Carbs Trend';
      case 'fat':
        return 'Fat Trend';
      default:
        return 'Nutrition Trend';
    }
  }

  String _formatValue(double value) {
    if (metric == 'calories') {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(0);
  }
}

