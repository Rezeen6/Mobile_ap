import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/meal_model.dart';

enum TimeRange { today, week, month }

class AdvancedMacroTrendsChart extends StatefulWidget {
  final Map<DateTime, NutritionInfo> weeklyData;
  final NutritionInfo? todayNutrition;

  const AdvancedMacroTrendsChart({
    super.key,
    required this.weeklyData,
    this.todayNutrition,
  });

  @override
  State<AdvancedMacroTrendsChart> createState() => _AdvancedMacroTrendsChartState();
}

class _AdvancedMacroTrendsChartState extends State<AdvancedMacroTrendsChart> {
  TimeRange _selectedRange = TimeRange.month;

  Map<DateTime, NutritionInfo> get _filteredData {
    final now = DateTime.now();
    switch (_selectedRange) {
      case TimeRange.today:
        // For today, show today's data
        if (widget.todayNutrition != null) {
          final today = DateTime(now.year, now.month, now.day);
          return {today: widget.todayNutrition!};
        }
        // If no today data, show last 7 days as fallback
        final weekAgo = now.subtract(const Duration(days: 7));
        return Map.fromEntries(
          widget.weeklyData.entries.where((e) => e.key.isAfter(weekAgo)),
        );
      case TimeRange.week:
        final weekAgo = now.subtract(const Duration(days: 7));
        final filtered = Map.fromEntries(
          widget.weeklyData.entries.where((e) => e.key.isAfter(weekAgo)),
        );
        // If no data, return empty, otherwise return filtered
        return filtered;
      case TimeRange.month:
        final monthAgo = now.subtract(const Duration(days: 30));
        final filtered = Map.fromEntries(
          widget.weeklyData.entries.where((e) => e.key.isAfter(monthAgo)),
        );
        // Group by week for month view
        if (filtered.length > 7) {
          final weeklyGrouped = <DateTime, NutritionInfo>{};
          final sorted = filtered.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
          for (int i = 0; i < sorted.length; i += 7) {
            final weekStart = sorted[i].key;
            final weekData = sorted.skip(i).take(7).map((e) => e.value).toList();
            // Average nutrition for the week
            final avgNutrition = NutritionInfo(
              calories: weekData.map((n) => n.calories).reduce((a, b) => a + b) / weekData.length,
              protein: weekData.map((n) => n.protein).reduce((a, b) => a + b) / weekData.length,
              carbohydrates: weekData.map((n) => n.carbohydrates).reduce((a, b) => a + b) / weekData.length,
              fat: weekData.map((n) => n.fat).reduce((a, b) => a + b) / weekData.length,
              fiber: weekData.map((n) => n.fiber).reduce((a, b) => a + b) / weekData.length,
            );
            weeklyGrouped[weekStart] = avgNutrition;
          }
          return weeklyGrouped;
        }
        return filtered;
    }
  }

  List<MapEntry<DateTime, NutritionInfo>> get _sortedData {
    final entries = _filteredData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final data = _sortedData;

    if (data.isEmpty && _selectedRange == TimeRange.today && widget.todayNutrition == null) {
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
        child: Center(
          child: Text(
            'No data available',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    // Calculate spots for each macronutrient
    final carbsSpots = data.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final value = entry.value.value.carbohydrates;
      return FlSpot(index, value);
    }).toList();

    final proteinSpots = data.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final value = entry.value.value.protein;
      return FlSpot(index, value);
    }).toList();

    final fatSpots = data.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final value = entry.value.value.fat;
      return FlSpot(index, value);
    }).toList();

    // Calculate max value across all macronutrients
    double maxValue = 0;
    for (var entry in data) {
      final nutrition = entry.value;
      maxValue = [
        maxValue,
        nutrition.carbohydrates,
        nutrition.protein,
        nutrition.fat,
      ].reduce((a, b) => a > b ? a : b);
    }

    final minValue = 0.0;
    final valueRange = maxValue - minValue;
    final horizontalInterval = valueRange > 0 ? valueRange / 5 : (maxValue > 0 ? maxValue / 5 : 1.0);

    // Colors for each macronutrient
    const carbsColor = Color(0xFF9E9E9E); // Grey
    const proteinColor = Color(0xFF2196F3); // Blue
    const fatColor = Color(0xFFFF9800); // Orange

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
          // Time Range Selection
          Row(
            children: [
              const Text(
                'Time Range',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              _buildTimeRangeButton('Today', TimeRange.today),
              const SizedBox(width: 8),
              _buildTimeRangeButton('Week', TimeRange.week),
              const SizedBox(width: 8),
              _buildTimeRangeButton('Month', TimeRange.month),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                onPressed: () {
                  // TODO: Implement custom date picker
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Custom date selection coming soon')),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Chart Title
          const Center(
            child: Text(
              'Macronutrient Trends',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Chart
          SizedBox(
            height: 280,
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
                            value.toStringAsFixed(1),
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
                        if (value.toInt() >= 0 && value.toInt() < data.length) {
                          final date = data[value.toInt()].key;
                          String label;
                          if (_selectedRange == TimeRange.today) {
                            label = DateFormat('HH:mm').format(date);
                          } else if (_selectedRange == TimeRange.week) {
                            label = DateFormat('E').format(date);
                          } else {
                            // For month view, show week number or date
                            label = 'W${value.toInt() + 1}';
                          }
                          return Text(
                            label,
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
                maxX: data.isEmpty ? 1 : (data.length > 1 ? (data.length - 1).toDouble() : 1.0),
                minY: 0,
                maxY: maxValue > 0 ? maxValue * 1.2 : 100,
                lineBarsData: [
                  // Carbohydrates line
                  LineChartBarData(
                    spots: carbsSpots,
                    isCurved: true,
                    color: carbsColor,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: carbsColor,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                  // Protein line
                  LineChartBarData(
                    spots: proteinSpots,
                    isCurved: true,
                    color: proteinColor,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: proteinColor,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                  // Fat line
                  LineChartBarData(
                    spots: fatSpots,
                    isCurved: true,
                    color: fatColor,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: fatColor,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipPadding: const EdgeInsets.all(8),
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                        String label;
                        switch (touchedSpot.barIndex) {
                          case 0:
                            label = 'Carbs: ${touchedSpot.y.toStringAsFixed(1)}g';
                            break;
                          case 1:
                            label = 'Protein: ${touchedSpot.y.toStringAsFixed(1)}g';
                            break;
                          case 2:
                            label = 'Fat: ${touchedSpot.y.toStringAsFixed(1)}g';
                            break;
                          default:
                            label = '';
                        }
                        return LineTooltipItem(
                          label,
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(carbsColor, 'Carbohydrates'),
              const SizedBox(width: 20),
              _buildLegendItem(proteinColor, 'Proteins'),
              const SizedBox(width: 20),
              _buildLegendItem(fatColor, 'Fats'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeButton(String label, TimeRange range) {
    final isSelected = _selectedRange == range;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRange = range;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B4513) : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}




