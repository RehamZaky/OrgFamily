import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';

class DonutSection {
  const DonutSection(this.color, this.value);

  final Color color;
  final double value;
}

/// A ring chart with an optional two-line label centered in the hole —
/// used by the Overview screen's category breakdown and the Budget
/// screen's overall spent-vs-limit ring. Falls back to a plain grey ring
/// when [sections] sums to zero (nothing to show yet) rather than crashing
/// on a degenerate pie.
class SpendingDonutChart extends StatelessWidget {
  const SpendingDonutChart({
    super.key,
    required this.sections,
    this.centerLabel,
    this.centerSubLabel,
    this.size = 140,
  });

  final List<DonutSection> sections;
  final String? centerLabel;
  final String? centerSubLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final total = sections.fold<double>(0, (sum, s) => sum + s.value);
    final pieSections = total <= 0
        ? [
            PieChartSectionData(
              value: 1,
              color: Colors.grey.shade200,
              showTitle: false,
              radius: size * 0.15,
            ),
          ]
        : sections
            .where((s) => s.value > 0)
            .map((s) => PieChartSectionData(
                  value: s.value,
                  color: s.color,
                  showTitle: false,
                  radius: size * 0.15,
                ))
            .toList();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: pieSections,
              centerSpaceRadius: size * 0.32,
              sectionsSpace: 2,
              startDegreeOffset: -90,
              borderData: FlBorderData(show: false),
            ),
          ),
          if (centerLabel != null)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  centerLabel!,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                if (centerSubLabel != null)
                  Text(
                    centerSubLabel!,
                    style: TextStyle(fontSize: 11, color: context.colors.textSecondary),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
