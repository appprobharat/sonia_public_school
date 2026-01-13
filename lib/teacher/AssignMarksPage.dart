import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';


class AssignMarksPage extends StatefulWidget {
  const AssignMarksPage({super.key});

  @override
  State<AssignMarksPage> createState() => _AssignMarksPageState();
}

class _AssignMarksPageState extends State<AssignMarksPage> {
  String? selectedExamId;
  String? selectedSubjectId;

  List exams = [];
  List subjects = [];
  List students = [];
  List filteredStudents = [];

  bool isLoading = false;
  bool isSubmitting = false;

  String searchQuery = '';

  final TextEditingController totalMarkController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// one controller per student
  final Map<int, TextEditingController> obtainControllers = {};

  @override
  void initState() {
    super.initState();
    fetchExams();
    fetchSubjects();
  }

  @override
  void dispose() {
    totalMarkController.dispose();
    for (final c in obtainControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------------- EXAMS ----------------
  Future<void> fetchExams() async {
    try {
      final response = await ApiService.post(
        context,
        "/get_exam",
      );

      if (response == null || !mounted) return;

      debugPrint("🟢 EXAMS STATUS: ${response.statusCode}");
      debugPrint("📦 EXAMS BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          setState(() => exams = decoded);
        }
      }
    } catch (e) {
      debugPrint("❌ fetchExams error: $e");
    }
  }

  // ---------------- SUBJECTS ----------------
  Future<void> fetchSubjects() async {
    try {
      final response = await ApiService.post(
        context,
        "/get_subject",
      );

      if (response == null || !mounted) return;

      debugPrint("🟢 SUBJECT STATUS: ${response.statusCode}");
      debugPrint("📦 SUBJECT BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          setState(() => subjects = decoded);
        }
      }
    } catch (e) {
      debugPrint("❌ fetchSubjects error: $e");
    }
  }

  // ---------------- STUDENTS ----------------
  Future<void> fetchStudents() async {
    if (selectedExamId == null || selectedSubjectId == null) return;

    setState(() => isLoading = true);

    try {
      final response = await ApiService.post(
        context,
        "/teacher/mark",
        body: {"ExamId": selectedExamId, "SubjectId": selectedSubjectId},
      );

      if (response == null || !mounted) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      debugPrint("🟢 MARK STATUS: ${response.statusCode}");
      debugPrint("📦 MARK BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // clear old controllers
        for (final c in obtainControllers.values) {
          c.dispose();
        }
        obtainControllers.clear();

        students = List.from(data['marks'] ?? []);

        if (students.isNotEmpty) {
          totalMarkController.text =
              students.first['TotalMark']?.toString() ?? '';
        }

        for (var s in students) {
          s['IsPresent'] ??= 'Yes';
          final id = s['id'];

          obtainControllers[id] = TextEditingController(
            text: s['GetMark']?.toString() ?? '',
          );
        }

        setState(() {
          filteredStudents = List.from(students);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("❌ fetchStudents error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ---------------- SEARCH ----------------
  void filterStudents(String query) {
    setState(() {
      searchQuery = query;
      filteredStudents = students.where((s) {
        return s['StudentName'].toString().toLowerCase().contains(
              query.toLowerCase(),
            ) ||
            s['FatherName'].toString().toLowerCase().contains(
              query.toLowerCase(),
            );
      }).toList();
    });
  }

  // ---------------- SUBMIT ----------------
  Future<void> updateMarks() async {
    // validation unchanged

    setState(() => isSubmitting = true);

    final payload = {
      "ExamId": selectedExamId,
      "SubjectId": selectedSubjectId,
      "marks": students.map((s) {
        return {
          "StudentId": s['id'],
          "IsPresent": s['IsPresent'],
          "TotalMark": s['TotalMark'],
          "GetMark": s['GetMark'],
        };
      }).toList(),
    };

    try {
      final response = await ApiService.post(
        context,
        "/teacher/mark/store",
        body: payload,
      );

      if (response == null || !mounted) return;

      setState(() => isSubmitting = false);

      final msg = response.statusCode == 200
          ? jsonDecode(response.body)['message']
          : "Failed to submit marks";

      _alert(msg);
    } catch (e) {
      if (mounted) setState(() => isSubmitting = false);
      _alert(e.toString());
    }
  }

  void _alert(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Alert'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ---------------- UI (UNCHANGED) ----------------
  @override
  Widget build(BuildContext context) {
    // ⛔ UI untouched as requested
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assign Marks"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),

      body: Stack(
        children: [
          ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      DropdownButtonFormField(
                        decoration: const InputDecoration(
                          labelText: 'Select Exam',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedExamId,
                        items: exams
                            .map(
                              (e) => DropdownMenuItem(
                                value: e['ExamId'],
                                child: Text(e['Exam']),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => selectedExamId = val as String?),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField(
                        decoration: const InputDecoration(
                          labelText: 'Select Subject',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedSubjectId,
                        items: subjects
                            .map(
                              (s) => DropdownMenuItem(
                                value: s['SubjectId'].toString(),
                                child: Text(s['Subject']),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => selectedSubjectId = val),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () => fetchStudents(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            "Search",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (students.isNotEmpty) ...[
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(
                    hintText: "Search student by Name",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: filterStudents,
                ),
              ],
              ...filteredStudents.map((student) {
                final hasObtainedMarks =
                    (student['GetMark']?.toString().trim().isNotEmpty ??
                        false) &&
                    student['GetMark'].toString().trim() != '0';

                final isMarked = hasObtainedMarks;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isMarked
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    border: Border.all(
                      color: isMarked
                          ? Colors.green.shade200
                          : Colors.red.shade200,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Roll No: ${student['RollNo']} | ${student['StudentName']}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                "F Name: ${_toTitleCase(student['FatherName'].toString())}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            SizedBox(width: 5),
                            Flexible(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            student['IsPresent'] = 'Yes';
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6,
                                            horizontal: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: student['IsPresent'] == 'Yes'
                                                ? Colors.green
                                                : Colors.green[300],
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Column(
                                            children: const [
                                              Text(
                                                'P',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              SizedBox(height: 3),
                                              Text(
                                                'Present',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            student['IsPresent'] = 'No';
                                            student['GetMark'] = '0';
                                            final id =
                                                student['id']; // ✅ Use same id used in controller
                                            final controller =
                                                obtainControllers[id];
                                            if (controller != null) {
                                              controller.text = '0';

                                              // optional: set cursor to end
                                              controller.selection =
                                                  TextSelection.fromPosition(
                                                    TextPosition(
                                                      offset: controller
                                                          .text
                                                          .length,
                                                    ),
                                                  );
                                            }
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6,
                                            horizontal: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: student['IsPresent'] == 'No'
                                                ? Colors.red
                                                : Colors.red[200],
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Column(
                                            children: const [
                                              Text(
                                                'A',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              SizedBox(height: 3),
                                              Text(
                                                'Absent',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            SizedBox(
                              width: 100,
                              height: 40,
                              child: TextField(
                                controller: totalMarkController,
                                decoration: const InputDecoration(
                                  labelText: "Total Marks",
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 12.0,
                                    horizontal: 10.0,
                                  ),
                                ),
                                keyboardType: TextInputType.number,

                                onChanged: (val) {
                                  setState(() {
                                    for (var s in students) {
                                      s['TotalMark'] = val;
                                    }
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 100,
                              height: 40,
                              child: TextField(
                                decoration: const InputDecoration(
                                  labelText: "Obtain Marks",
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 12.0,
                                    horizontal: 10.0,
                                  ),
                                ),
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                controller: obtainControllers[student['id']],
                                onChanged: (val) {
                                  student['GetMark'] = val;

                                  setState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              if (students.isNotEmpty)
                ElevatedButton(
                  onPressed: isSubmitting ? null : updateMarks,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: AppColors.primary,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Update Marks",
                          style: TextStyle(color: Colors.white),
                        ),
                ),
            ],
          ),
          if (isLoading) const Center(child: CircularProgressIndicator(color: AppColors.primary),),
        ],
      ),
    );
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }
}
