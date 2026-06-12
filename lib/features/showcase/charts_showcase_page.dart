import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';

class ChartsShowcasePage extends StatelessWidget {
  const ChartsShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Charts')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _label(context, 'Line Chart'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                height: 180,
                child: LineChart(LineChartData(
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: const FlTitlesData(
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 2), FlSpot(1, 4), FlSpot(2, 3.5),
                        FlSpot(3, 6), FlSpot(4, 5), FlSpot(5, 7.2), FlSpot(6, 8),
                      ],
                      isCurved: true,
                      color: colors.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colors.primary.withOpacity(0.15),
                      ),
                    ),
                  ],
                )),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          _label(context, 'Bar Chart'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                height: 180,
                child: BarChart(BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: const FlTitlesData(
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 5, color: colors.primary)]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 8, color: colors.secondary)]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 6, color: colors.tertiary)]),
                    BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 9, color: colors.primary)]),
                    BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 7, color: colors.secondary)]),
                  ],
                )),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          _label(context, 'Pie Chart'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                height: 200,
                child: PieChart(PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 50,
                  sections: [
                    PieChartSectionData(value: 40, title: '40%', color: colors.primary, radius: 50),
                    PieChartSectionData(value: 25, title: '25%', color: colors.secondary, radius: 50),
                    PieChartSectionData(value: 20, title: '20%', color: colors.tertiary, radius: 50),
                    PieChartSectionData(value: 15, title: '15%', color: colors.error, radius: 50),
                  ],
                )),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
  );
}
