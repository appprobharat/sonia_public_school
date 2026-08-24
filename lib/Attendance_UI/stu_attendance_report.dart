import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sonia_public_school/api_service.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  DateTime _focusedMonth = DateTime.now();
  Map<String, String> _attendanceMap = {};
  bool _isLoading = false;
  double _attendancePercentage(Map<String, int> totals) {
    final workingDays =
        totals['Present']! +
        totals['Absent']! +
        totals['Leave']! +
        totals['HalfDay']!;

    if (workingDays == 0) return 0;

    return (totals['Present']! / workingDays) * 100;
  }

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final formattedMonth = DateFormat('yyyy-MM').format(_focusedMonth);
      final res = await ApiService.post(
        context,
        "/student/attendance",
        body: {'Month': formattedMonth},
      );

      // AuthHelper handles 401 + logout
      if (res == null) return;

      debugPrint("📥 STUDENT ATTENDANCE STATUS: ${res.statusCode}");
      debugPrint("📥 STUDENT ATTENDANCE BODY: ${res.body}");

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);

        if (!mounted) return;
        setState(() {
          _attendanceMap = {
            for (final item in data)
              item['date'].toString(): item['status'].toString(),
          };
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load attendance")),
        );
      }
    } catch (e) {
      debugPrint("🚨 STUDENT ATTENDANCE ERROR: $e");

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Something went wrong")));
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // ====================================================
  // 📊 CALCULATE TOTALS (UNCHANGED)
  // ====================================================
  Map<String, int> _calculateTotals() {
    int present = 0;
    int absent = 0;
    int leave = 0;
    int holiday = 0;
    int halfDay = 0;
    int notMarked = 0;

    for (final status in _attendanceMap.values) {
      switch (status) {
        case 'Present':
          present++;
          break;
        case 'Absent':
          absent++;
          break;
        case 'Leave':
          leave++;
          break;
        case 'Holiday':
          holiday++;
          break;
        case 'HalfDay':
          halfDay++;
          break;
        default:
          notMarked++;
      }
    }

    return {
      'Present': present,
      'Absent': absent,
      'Leave': leave,
      'Holiday': holiday,
      'HalfDay': halfDay,
      'Not Marked': notMarked,
    };
  }

  @override
  Widget build(BuildContext context) {
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final firstOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = firstOfMonth.weekday % 7;
    final totals = _calculateTotals();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_rounded, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              "My Attendance",
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: .3,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildOverviewCard(totals),

              _buildCalendarContainer(year, month, daysInMonth, startWeekday),

              _buildSummaryBox(totals),
            ],
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.1),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCalendarContainer(
    int year,
    int month,
    int daysInMonth,
    int startWeekday,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xff2563EB),
                  Color(0xff3B82F6),
                  Color(0xff60A5FA),
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _focusedMonth = DateTime(
                          _focusedMonth.year,
                          _focusedMonth.month - 1,
                        );
                      });
                      _fetchAttendance();
                    },
                  ),
                ),
                Column(
                  children: [
                    Text(
                      DateFormat.yMMMM().format(_focusedMonth),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "Attendance Calendar",
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _focusedMonth = DateTime(
                          _focusedMonth.year,
                          _focusedMonth.month + 1,
                        );
                      });
                      _fetchAttendance();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Weekdays
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: const TextStyle(
                            color: Color(0xff64748B),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // Calendar Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: daysInMonth + startWeekday,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemBuilder: (context, index) {
                if (index < startWeekday) return const SizedBox();

                final day = index - startWeekday + 1;
                final date = DateTime(year, month, day);
                final dateStr = DateFormat('yyyy-MM-dd').format(date);
                final status = _attendanceMap[dateStr] ?? 'Not Marked';
                final isToday =
                    date.day == DateTime.now().day &&
                    date.month == DateTime.now().month &&
                    date.year == DateTime.now().year;
                Color dotColor;
                switch (status) {
                  case 'Present':
                    dotColor = Colors.green;
                    break;
                  case 'Absent':
                    dotColor = Colors.red;
                    break;
                  case 'Leave':
                    dotColor = Colors.orange;
                    break;
                  case 'Holiday':
                    dotColor = Colors.black;
                    break;
                  case 'HalfDay':
                    dotColor = Colors.blue;
                    break;
                  default:
                    dotColor = Colors.grey;
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    color: isToday
                        ? const Color(0xffDBEAFE)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isToday
                          ? const Color(0xff2563EB)
                          : Colors.grey.shade200,
                      width: isToday ? 2 : 1,
                    ),
                    boxShadow: [
                      if (isToday)
                        BoxShadow(
                          color: const Color(0xff2563EB).withOpacity(.20),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        "$day",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isToday
                              ? const Color(0xff1D4ED8)
                              : status == "Absent"
                              ? Colors.red
                              : Colors.black87,
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: dotColor.withOpacity(.45),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ====================================================
  // 📊 SUMMARY BOX (UNCHANGED)
  // ====================================================
  Widget _buildSummaryBox(Map<String, int> totals) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusItem('Present', totals['Present']!, Colors.green),
              _buildStatusItem('Absent', totals['Absent']!, Colors.red),
              _buildStatusItem('Leave', totals['Leave']!, Colors.orange),
              _buildStatusItem('Holiday', totals['Holiday']!, Colors.black),
              _buildStatusItem('Half Day', totals['HalfDay']!, Colors.blue),
              _buildStatusItem(
                'Not Marked',
                totals['Not Marked']!,
                Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, int count, Color color) {
    return Column(
      children: [
        CircleAvatar(radius: 6, backgroundColor: color),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(Map<String, int> totals) {
    final percent = _attendancePercentage(totals);

    final workingDays =
        totals['Present']! +
        totals['Absent']! +
        totals['Leave']! +
        totals['HalfDay']!;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff1D4ED8), Color(0xff2563EB), Color(0xff60A5FA)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(.20),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.18),
              border: Border.all(color: Colors.white24),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              "${percent.toStringAsFixed(0)}%",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Attendance Overview",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),

                Text(
                  "$workingDays Working Days",
                  style: TextStyle(
                    color: Colors.white.withOpacity(.85),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    _miniStat(
                      Icons.check_circle,
                      Colors.greenAccent,
                      totals['Present']!,
                    ),
                    const SizedBox(width: 15),
                    _miniStat(
                      Icons.cancel,
                      Colors.redAccent,
                      totals['Absent']!,
                    ),
                    const SizedBox(width: 15),
                    _miniStat(Icons.calendar_today, Colors.amber, workingDays),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, Color color, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.14),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Text(
            "$value",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
