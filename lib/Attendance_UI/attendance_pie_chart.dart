import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';

import '../api_service.dart';

class AttendancePieChart extends StatelessWidget {
  final int present;
  final int absent;
  final int leave;
  final int halfDay;
  final int workingDays;

  const AttendancePieChart({
    super.key,
    required this.present,
    required this.absent,
    required this.leave,
    required this.halfDay,
    required this.workingDays,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    // Base size that looks good on regular screens
    double baseChartRadius = 140;

    double chartRadius = screenWidth < 360
        ? baseChartRadius * 0.85
        : screenWidth > 600
            ? baseChartRadius * 1.2
            : baseChartRadius;

    final Map<String, double> dataMap = {
      "Present": present.toDouble(),
      "Absent": absent.toDouble(),
      "Leave": leave.toDouble(),
      "Half Day": halfDay.toDouble(),
    };

    final List<Color> colorList = [
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.blue,
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: "📊 Monthly Attendance ",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                TextSpan(
                  text: "(Working Days: $workingDays)",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PieChart(
            dataMap: dataMap,
            chartType: ChartType.disc,
            chartRadius: chartRadius,
            colorList: colorList,
            chartValuesOptions: const ChartValuesOptions(
              showChartValueBackground: false,
              decimalPlaces: 0,
              showChartValuesInPercentage: false,
              chartValueStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            legendOptions: const LegendOptions(
              legendPosition: LegendPosition.right,
              showLegendsInRow: false,
              legendTextStyle: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
