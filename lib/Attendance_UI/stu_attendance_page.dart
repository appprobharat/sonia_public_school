import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sonia_public_school/api_service.dart';


class AttendanceAnalyticsPage extends StatefulWidget {
  const AttendanceAnalyticsPage({super.key});

  @override
  State<AttendanceAnalyticsPage> createState() =>
      _AttendanceAnalyticsPageState();
}

class _AttendanceAnalyticsPageState extends State<AttendanceAnalyticsPage> {
  bool _isLoading = true;
  Map<String, dynamic>? analyticsData;

  @override
  void initState() {
    super.initState();
    fetchAttendanceAnalytics();
  }

  // ====================================================
  // 🎨 STATUS STYLE (SAFE)
  // ====================================================
  Map<String, dynamic> getStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case "present":
        return {
          'bg': Colors.green.shade50,
          'text': Colors.green.shade700,
          'icon': Icons.check_circle,
        };
      case "absent":
        return {
          'bg': Colors.red.shade50,
          'text': Colors.red.shade700,
          'icon': Icons.cancel,
        };
      case "leave":
        return {
          'bg': Colors.yellow.shade50,
          'text': Colors.yellow.shade700,
          'icon': Icons.airline_seat_flat,
        };
      case "halfday":
        return {
          'bg': Colors.blue.shade50,
          'text': Colors.blue.shade700,
          'icon': Icons.access_time,
        };
      case "holiday":
        return {
          'bg': Colors.grey.shade300,
          'text': Colors.black54,
          'icon': Icons.celebration,
        };
      default:
        return {
          'bg': Colors.grey.shade200,
          'text': Colors.grey.shade600,
          'icon': Icons.help_outline,
        };
    }
  }

  // ====================================================
  // 🔐 SAFE FETCH (iOS + Android)
  // ====================================================
  Future<void> fetchAttendanceAnalytics() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final res = await ApiService.post(
  context,
  "/student/attendance/analytics",
);

      // AuthHelper already handles 401 + logout
      if (res == null) return;

      debugPrint("📥 ANALYTICS STATUS: ${res.statusCode}");
      debugPrint("📥 ANALYTICS BODY: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (!mounted) return;
        setState(() {
          analyticsData = Map<String, dynamic>.from(data);
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load analytics")),
        );
      }
    } catch (e) {
      debugPrint("🚨 ANALYTICS ERROR: $e");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong")),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = analyticsData;
    String todayStatus = (data?['today_status'] ?? 'Not Mark').toString();
    final style = getStatusStyle(todayStatus);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Attendance Analysis",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary),)
          : data == null
              ? const Center(child: Text("No data found"))
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ---------------- Today Status ----------------
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  "Today's Attendance",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: style['bg'],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      todayStatus.toUpperCase(),
                                      style: TextStyle(
                                        color: style['text'],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      style['icon'],
                                      color: style['text'],
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ---------------- Circular Indicator ----------------
                        Center(
                          child: CircularPercentIndicator(
                            radius: 90,
                            lineWidth: 12,
                            percent:
                                ((data['yearly_percentage'] ?? 0) / 100)
                                    .clamp(0.0, 1.0),
                            center: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${data['yearly_percentage'] ?? 0}%",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text("Attendance"),
                              ],
                            ),
                            progressColor: Colors.green,
                            backgroundColor: Colors.grey.shade200,
                            circularStrokeCap: CircularStrokeCap.round,
                          ),
                        ),

                        const SizedBox(height: 20),

                        AttendanceAnalyticsWidget(
                          monthlyData:
                              List<Map<String, dynamic>>.from(
                            data['monthly_data'] ?? [],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

// ====================================================
// 📊 MONTHLY CHART (UNCHANGED UI)
// ====================================================
class AttendanceAnalyticsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> monthlyData;

  const AttendanceAnalyticsWidget({super.key, required this.monthlyData});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(top: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: 100,
              barGroups: monthlyData
                  .asMap()
                  .entries
                  .map(
                    (e) => BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY:
                              (e.value['percentage'] ?? 0).toDouble(),
                          color: AppColors.primary,
                          width: 14,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
