import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';

class Exam {
  final String id;
  final String name;

  Exam({required this.id, required this.name});
}

class ExamScheduleItem {
  final String subject;
  final String date;
  final String day;
  final String time;
  final String endTime;
  final String remark;

  ExamScheduleItem({
    required this.subject,
    required this.date,
    required this.day,
    required this.time,
    required this.endTime,
    required this.remark,
  });
}

class ExamSchedulePage extends StatefulWidget {
  const ExamSchedulePage({super.key});

  @override
  State<ExamSchedulePage> createState() => _ExamSchedulePageState();
}

class _ExamSchedulePageState extends State<ExamSchedulePage> {



  List<Exam> exams = [];
  Exam? selectedExam;
  List<ExamScheduleItem> scheduleContent = [];

  bool isLoadingExams = true;
  bool isLoadingSchedule = false;

  @override
  void initState() {
    super.initState();
    fetchExams();
  }

  // ====================================================
  // 🔹 FETCH EXAMS (SAFE)
  // ====================================================
  Future<void> fetchExams() async {
    if (!mounted) return;
    setState(() => isLoadingExams = true);

    try {
      final res = await ApiService.post(
        context,
        '/get_exam',
        body: {}, // 🔥 IMPORTANT: empty JSON body
      );

      if (res == null) {
        if (!mounted) return;
        setState(() => isLoadingExams = false);
        return;
      }

      debugPrint("📘 Exams response: ${res.body}");

      if (res.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(res.body);

        final loadedExams = decoded.map((e) {
          return Exam(
            id: e['ExamId'].toString(),
            name: e['Exam']?.toString() ?? '',
          );
        }).toList();

        if (!mounted) return;
        setState(() {
          exams = loadedExams;
          isLoadingExams = false;
        });

        if (exams.isNotEmpty) {
          selectedExam = exams.first;
          fetchScheduleForExam(selectedExam!.id);
        }
      } else {
        _failExams("Failed to load exams");
      }
    } catch (e) {
      debugPrint("❌ fetchExams error: $e");
      _failExams("Something went wrong");
    }
  }

  void _failExams(String msg) {
    if (!mounted) return;
    setState(() => isLoadingExams = false);
    _showSnackBar(msg);
  }

  // ====================================================
  // 🔹 FETCH SCHEDULE (SAFE)
  // ====================================================
  Future<void> fetchScheduleForExam(String examId) async {
    if (!mounted) return;

    setState(() {
      isLoadingSchedule = true;
      scheduleContent.clear();
    });

    try {
      final res = await ApiService.post(
        context,
        "/schedule",
        body: {'ExamId': examId},
      );

      if (res == null) return;

      if (res.statusCode == 200) {
        final List decoded = jsonDecode(res.body);

        final loadedSchedule = decoded
            .map(
              (item) => ExamScheduleItem(
                subject: item['Subject'] ?? '',
                date: item['Date'] ?? '',
                day: item['Day'] ?? '',
                time: item['Time'] ?? '',
                endTime: item['EndTime'] ?? '',
                remark: item['Remark'] ?? '',
              ),
            )
            .toList();

        if (!mounted) return;
        setState(() {
          scheduleContent = loadedSchedule;
          isLoadingSchedule = false;
        });
      } else {
        _failSchedule("Failed to load schedule");
      }
    } catch (e) {
      _failSchedule("Something went wrong");
    }
  }

  void _failSchedule(String msg) {
    if (!mounted) return;
    setState(() => isLoadingSchedule = false);
    _showSnackBar(msg);
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ====================================================
  // 🧱 UI (UNCHANGED)
  // ====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Exam Schedule",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildExamSelector(),
          const SizedBox(height: 10),
          _buildScheduleList(),
        ],
      ),
    );
  }

  Widget _buildExamSelector() {
    if (isLoadingExams) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (exams.isEmpty) {
      return const Center(child: Text("No exams available."));
    }

    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: exams.length,
        itemBuilder: (context, index) {
          final exam = exams[index];
          final isSelected =
              selectedExam != null && selectedExam!.id == exam.id;

          return GestureDetector(
            onTap: () {
              setState(() => selectedExam = exam);
              fetchScheduleForExam(exam.id);
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
                    exam.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
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

  Widget _buildScheduleList() {
    if (isLoadingSchedule) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (scheduleContent.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            selectedExam == null
                ? "Select an exam to view the schedule."
                : "No schedule available for ${selectedExam!.name}.",
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: scheduleContent.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final item = scheduleContent[index];
          return _buildScheduleCard(item);
        },
      ),
    );
  }

  Widget _buildScheduleCard(ExamScheduleItem item) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.subject,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const Divider(height: 16),
            _buildInfoRow(Icons.calendar_today, 'Date', item.date),
            _buildInfoRow(Icons.calendar_view_day, 'Day', item.day),
            _buildInfoRow(
              Icons.access_time,
              'Time',
              '${item.time} - ${item.endTime}',
            ),
            _buildInfoRow(Icons.info_outline, 'Remark', item.remark),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
