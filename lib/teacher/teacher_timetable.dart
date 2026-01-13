import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';


class TeacherTimeTablePage extends StatefulWidget {
  const TeacherTimeTablePage({super.key});

  @override
  State<TeacherTimeTablePage> createState() => _TeacherTimeTablePageState();
}

class _TeacherTimeTablePageState extends State<TeacherTimeTablePage> {
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
    fetchTimeTableForDay(1); 
  }

 Future<void> fetchTimeTableForDay(int dayCode) async {
  if (!mounted) return;

  setState(() => isLoading = true);

  debugPrint("🟡 fetchTimeTableForDay START | Day: $dayCode");

  try {
    final response = await ApiService.post(
      context,
      '/teacher/timetable',
      body: {'Day': dayCode},
    );

    // 🔐 token expired → AuthHelper already logout kara dega
    if (response == null || !mounted) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    debugPrint("🟢 STATUS CODE: ${response.statusCode}");
    debugPrint("📦 RAW BODY: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      setState(() {
        periods = decoded is List ? decoded : [];
      });

      debugPrint("📊 PERIOD COUNT: ${periods.length}");
    } else {
      setState(() => periods = []);
      _showSnack("Failed to load timetable (${response.statusCode})");
    }
  } catch (e) {
    debugPrint("❌ fetchTimeTableForDay ERROR: $e");
    if (!mounted) return;
    setState(() => periods = []);
    _showSnack("Something went wrong");
  } finally {
    if (mounted) {
      setState(() => isLoading = false);
    }
    debugPrint("🔚 fetchTimeTableForDay END");
  }
}

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
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
        title: const Text(
          "Teacher Time Table",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildDaySelector(),
          const SizedBox(height: 10),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : periods.isEmpty
                    ? const Center(child: Text("No timetable available"))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: periods.length,
                        itemBuilder: (context, index) {
                          final period = periods[index];
                          final slot = period['Slot'];
                          final isLunch =
                              slot == "2" ||
                              (period['Period']?.toString().toUpperCase() ==
                                  'LUNCH');

                          Color bgColor =
                              slot == "2" ? Colors.orange : AppColors.primary;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IntrinsicHeight(
                              child: Row(
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
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
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
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                )
                                              : Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
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
                                                      "Class: ${period['Class'] ?? '-'}"
                                                      "${period['Section'] != null ? ' (${period['Section']})' : ''}",
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
              if (day == selectedDay) return; // prevent duplicate calls
              setState(() => selectedDay = day);
              fetchTimeTableForDay(getDayCode(day));
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 1.2),
              ),
              child: Row(
                children: [
                  if (isSelected) ...[
                    const Icon(Icons.check,
                        color: Colors.white, size: 16),
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
