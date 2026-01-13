import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sonia_public_school/api_service.dart';


class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _focusedMonth = DateTime.now();
  Map<String, int> _statusMap = {};

  int _present = 0;
  int _absent = 0;
  int _leave = 0;
  int _half = 0;
  int _holiday = 0;
  String? _selectedDate;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  // ====================================================
  // 🔐 SAFE ATTENDANCE FETCH (iOS + Android)
  // ====================================================
  Future<void> _fetchAttendance({String? selectedDate}) async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    final dateToSend =
        selectedDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
     final res = await ApiService.post(
  context,
  "/teacher/std_attendance/report",
  body: {'Date': dateToSend},
);


      // 🔐 AuthHelper handles 401 + logout
      if (res == null) return;

      debugPrint("📥 ATTENDANCE STATUS: ${res.statusCode}");
      debugPrint("📥 ATTENDANCE BODY: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (!mounted) return;

        setState(() {
          _present = data['present'] ?? 0;
          _absent = data['absent'] ?? 0;
          _leave = data['leave'] ?? 0;
          _half = data['half_day'] ?? 0;
          _holiday = data['holiday'] ?? 0;

          _statusMap = {
            for (final item in (data['days'] ?? []))
              item['date'].toString(): item['status'] ?? 0,
          };

          _selectedDate = dateToSend;
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load attendance")),
        );
      }
    } catch (e) {
      debugPrint("🚨 ATTENDANCE ERROR: $e");

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
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final firstOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = (firstOfMonth.weekday) % 7;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attendance Report',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 12),
                _buildCalendarContainer(
                  year,
                  month,
                  daysInMonth,
                  startWeekday,
                ),
                const SizedBox(height: 10),
                _buildSummaryBoxes(),
              ],
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.1),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ===================== UI (UNCHANGED) =====================

  Widget _buildCalendarContainer(
    int year,
    int month,
    int daysInMonth,
    int startWeekday,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              gradient: LinearGradient(
                colors: [Colors.lightBlue, Colors.blueAccent],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
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
                Text(
                  DateFormat.yMMMM().format(_focusedMonth),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
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
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

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
              itemBuilder: (context, idx) {
                if (idx < startWeekday) return const SizedBox();

                final day = idx - startWeekday + 1;
                final date = DateTime(year, month, day);
                final dateStr = DateFormat('yyyy-MM-dd').format(date);

                final status = _statusMap[dateStr] ?? 0;
                final dotColor = status > 0 ? Colors.green : Colors.grey;
                final isSelected = _selectedDate == dateStr;

                return GestureDetector(
                  onTap: () {
                    if (status > 0) {
                      _fetchAttendance(selectedDate: dateStr);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isSelected ? Colors.green.shade50 : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Colors.lightGreen
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '$day',
                          style:
                              const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Positioned(
                          bottom: 4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
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
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSummaryBoxes() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.grey,
                borderRadius:
                    BorderRadius.only(topLeft: Radius.circular(10)),
              ),
              child: Text(
                'Date Record (${DateFormat('dd-MMM-yyyy').format(
                  _selectedDate != null
                      ? DateTime.parse(_selectedDate!)
                      : DateTime.now(),
                )})',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatusBox('PRESENT', _present, Colors.green),
                    _buildStatusBox('ABSENT', _absent, Colors.red),
                    _buildStatusBox('LEAVE', _leave, Colors.yellow),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatusBox('HALF-DAY', _half, Colors.blue),
                    _buildStatusBox(
                      'HOLIDAY',
                      _holiday,
                      Colors.brown,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBox(String title, int count, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$title: $count',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
