import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';

class TimeTablePage extends StatefulWidget {
  const TimeTablePage({super.key});

  @override
  State<TimeTablePage> createState() => _TimeTablePageState();
}

class _TimeTablePageState extends State<TimeTablePage> {
  final List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  String selectedDay = 'Monday';
  List<dynamic> periods = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTimeTableForDay(1); // Monday
  }

  // ====================================================
  // 🔐 SAFE FETCH TIMETABLE (iOS + Android)
  // ====================================================
  Future<void> fetchTimeTableForDay(int dayCode) async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      debugPrint("📤 TIMETABLE REQUEST DAY: $dayCode");

      final res = await ApiService.post(
        context,
        '/student/timetable',
        body: {'Day': dayCode},
      );

      // AuthHelper handles 401 + logout
      if (res == null) return;

      debugPrint("📥 TIMETABLE STATUS: ${res.statusCode}");
      debugPrint("📥 TIMETABLE BODY: ${res.body}");

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        if (!mounted) return;
        setState(() {
          periods = decoded is List ? decoded : [];
        });
      } else {
        if (!mounted) return;
        setState(() => periods = []);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load time table')),
        );
      }
    } catch (e) {
      debugPrint("🚨 TIMETABLE ERROR: $e");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong")),
      );
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  int getDayCode(String day) {
    switch (day) {
      case 'Monday':
        return 1;
      case 'Tuesday':
        return 2;
      case 'Wednesday':
        return 3;
      case 'Thursday':
        return 4;
      case 'Friday':
        return 5;
      case 'Saturday':
        return 6;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Time Table", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildDaySelector(),
          const SizedBox(height: 10),
          isLoading
              ? const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                )
              : Expanded(
                  child: periods.isEmpty
                      ? const Center(child: Text("No timetable available"))
                      : ListView.builder(
                          itemCount: periods.length,
                          padding: const EdgeInsets.all(12),
                          itemBuilder: (context, index) {
                            final period = periods[index];
                            final slot = period['Slot'];
                            final isLunch = slot == "2";

                            Color bgColor;
                            if (slot == "1") {
                              bgColor = AppColors.primary;
                            } else if (slot == "2") {
                              bgColor = Colors.orange;
                            } else {
                              bgColor = AppColors.primary;
                            }

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                      width: 80,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: bgColor,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          bottomLeft: Radius.circular(12),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            period['Period'] ?? '',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${period['FromTime']} - ${period['ToTime']}",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: isLunch
                                            ? const Text(
                                                "LUNCH BREAK",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            : (period['Subject'] == null ||
                                                    period['Subject']
                                                        .toString()
                                                        .trim()
                                                        .isEmpty)
                                                ? const Text(
                                                    "❌ Not Scheduled",
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  )
                                                : Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "Subject: ${period['Subject']}",
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        "Teacher: ${period['Teacher'] ?? '-'}",
                                                      ),
                                                      Text(
                                                        "Room No: ${period['RoomNo'] ?? '-'}",
                                                      ),
                                                    ],
                                                  ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ],
      ),
    );
  }

  // ====================================================
  // 📅 DAY SELECTOR (UNCHANGED)
  // ====================================================
  Widget _buildDaySelector() {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = selectedDay == day;

          return GestureDetector(
            onTap: () {
              setState(() => selectedDay = day);
              fetchTimeTableForDay(getDayCode(day));
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 1.2),
              ),
              child: Row(
                children: [
                  if (isSelected) ...[
                    const Icon(Icons.check, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    day,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
