import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';

class StudentResultPage extends StatefulWidget {
  const StudentResultPage({Key? key}) : super(key: key);

  @override
  State<StudentResultPage> createState() => _StudentResultPageState();
}

class _StudentResultPageState extends State<StudentResultPage> {
  String? selectedExamId;
  List exams = [];
  List results = [];
  bool isLoading = false;
  bool isExamLoading = true;

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

    setState(() => isExamLoading = true);

    try {
      final res = await ApiService.post(
        context,
        '/get_exam',
      );

      if (res == null) return;

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        List examList = [];

        if (decoded is List) {
          examList = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          examList = decoded['data'];
        }

        if (!mounted) return;
        setState(() {
          exams = examList;
          isExamLoading = false;
        });
        debugPrint("📦 Exams length: ${exams.length}");
        debugPrint("📦 Exams data: $exams");
      } else {
        _showError("Failed to load exams");
      }
    } catch (e) {
      _showError("Something went wrong");
    }
  }

  // ====================================================
  // 🔹 FETCH RESULTS (SAFE)
  // ====================================================
  Future<void> fetchResults() async {
    if (selectedExamId == null) {
      _showSnack("Please select an exam");
      return;
    }

    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final res = await ApiService.post(
        context,
        '/teacher/result',
        body: {'ExamId': selectedExamId},
      );

      if (res == null) return;

      if (res.statusCode == 200) {
        if (!mounted) return;

        setState(() {
          results = jsonDecode(res.body);
        });
      } else {
        _showSnack("Failed to fetch results");
      }
    } catch (e) {
      _showSnack("Something went wrong");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showError(String msg) {
    if (!mounted) return;

    setState(() {
      isExamLoading = false;
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ====================================================
  // 🧱 UI (UNCHANGED)
  // ====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          "Student Result",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // 🔽 Exam Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedExamId,
                  hint: const Text("Select Exam"),
                  isExpanded: true,
                  items: exams.map<DropdownMenuItem<String>>((exam) {
                    return DropdownMenuItem<String>(
                      value: exam['ExamId'].toString(),
                      child: Text(exam['Exam']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedExamId = value);
                    fetchResults();
                  },
                ),
              ),
            ),

            const SizedBox(height: 10),

            if (isLoading)
              const CircularProgressIndicator(color: AppColors.primary),

            if (!isLoading && results.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final student = results[index];
                    final marks = student['Marks'] as List;

                    double totalMarks = 0;
                    double obtainedMarks = 0;

                    for (var m in marks) {
                      totalMarks += double.tryParse(m['TotalMark'] ?? '0') ?? 0;
                      if (m['IsPresent'] == "Yes") {
                        obtainedMarks +=
                            double.tryParse(m['GetMark'] ?? '0') ?? 0;
                      }
                    }

                    final percentage = totalMarks > 0
                        ? (obtainedMarks / totalMarks) * 100
                        : 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "R_No: ${student['RollNo']}  ||  ${student['StudentName']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "F Name: ${student['FatherName']}",
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 10),

                            Row(
                              children: const [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    "Subject",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Spacer(),
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    "Total",
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 15),
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    "Obt",
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),

                            Column(
                              children: marks.map((m) {
                                return Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(m['Subject']),
                                    ),
                                    const Spacer(),
                                    SizedBox(
                                      width: 40,
                                      child: Text(
                                        m['TotalMark'],
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    SizedBox(
                                      width: 40,
                                      child: Text(
                                        m['IsPresent'] == "Yes"
                                            ? m['GetMark']
                                            : "Ab",
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: m['IsPresent'] == "Yes"
                                              ? Colors.black
                                              : Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),

                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total: ${obtainedMarks.toInt()} / ${totalMarks.toInt()}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Percentage: ${percentage.toStringAsFixed(2)}%",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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
      ),
    );
  }
}
