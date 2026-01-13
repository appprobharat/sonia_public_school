import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';



class AssignSkillsPage extends StatefulWidget {
  const AssignSkillsPage({super.key});

  @override
  State<AssignSkillsPage> createState() => _AssignSkillsPageState();
}

class _AssignSkillsPageState extends State<AssignSkillsPage> {
  List<Map<String, dynamic>> studentList = [];
  List<Map<String, dynamic>> filteredList = [];
  List<Map<String, dynamic>> skills = [];
  // List<Map<String, dynamic>> examList = [];

  String? selectedExam;
  String? selectedSkill;
  List exams = [];
  bool isSubmitting = false;
  bool showTable = false;
  bool isLoading = false;

  final TextEditingController searchController = TextEditingController();
  final Map<String, TextEditingController> gradeControllers = {};

  @override
  void initState() {
    super.initState();
    fetchExams();
    fetchSkills();
  }

  @override
  void dispose() {
    searchController.dispose();
    for (final c in gradeControllers.values) {
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

  // ---------------- SKILLS ----------------
Future<void> fetchSkills() async {
  try {
    final response = await ApiService.post(
      context,
      "/get_skill",
    );

    // 🔐 token expired / server issue
    if (response == null) return;

    if (response.statusCode == 200 && mounted) {
      skills = List<Map<String, dynamic>>.from(
        jsonDecode(response.body),
      );
      setState(() {});
    }
  } catch (e) {
    debugPrint("❌ FETCH SKILLS ERROR: $e");
  }
}


  // ---------------- STUDENTS ----------------
 Future<void> _fetchStudents() async {
  if (selectedExam == null || selectedSkill == null) return;

  setState(() {
    isLoading = true;
    showTable = false;
  });

  try {
    final resp = await ApiService.post(
      context,
      "/teacher/skill",
      body: {
        "ExamId": int.parse(selectedExam!),
        "SkillId": int.parse(selectedSkill!),
      },
    );

    // 🔐 token expire / server timeout
    if (resp == null) return;

    if (!mounted) return;

    final data = jsonDecode(resp.body);

    // 🔁 Dispose old controllers
    for (final c in gradeControllers.values) {
      c.dispose();
    }
    gradeControllers.clear();

    if (data['skills'] != null) {
      studentList =
          List<Map<String, dynamic>>.from(data['skills']).map((s) {
        return {
          "studentid": s['id'],
          "name": s['StudentName'],
          "father": s['FatherName'],
          "roll": s['RollNo'],
          "status": s['Status'],
          "Grade": s['Grade'] ?? '',
        };
      }).toList();

      filteredList = List.from(studentList);

      for (final student in studentList) {
        final id = student['studentid'].toString();
        gradeControllers[id] = TextEditingController(
          text: student['Grade'] ?? '',
        );
      }

      setState(() => showTable = true);
    }

    if (data['msg'] != null && data['msg'].toString().trim().isNotEmpty) {
      _alert(data['msg']);
    }
  } catch (e) {
    _alert("❌ Error: $e");
  } finally {
    if (mounted) {
      setState(() => isLoading = false);
    }
  }
}

  // ---------------- SUBMIT ----------------
 Future<void> _submitSkills() async {
  if (!mounted) return;

  setState(() => isSubmitting = true);

  try {
    // 🔎 Validation
    for (final s in studentList) {
      final id = s['studentid'].toString();
      final grade =
          gradeControllers[id]?.text.trim().toUpperCase() ?? '';

      if (grade.isEmpty) {
        _alert("Please enter Grade for all students.");
        setState(() => isSubmitting = false);
        return;
      }

      s['Grade'] = grade;
    }

    final payload = {
      "ExamId": int.parse(selectedExam!),
      "SkillId": int.parse(selectedSkill!),
      "skills": studentList
          .map(
            (s) => {
              "StudentId": s['studentid'],
              "Grade": s['Grade'],
            },
          )
          .toList(),
    };

    final response = await ApiService.post(
      context,
      "/teacher/skill/store",
      body: payload,
    );

    // 🔐 token expired / timeout handled
    if (response == null) return;

    if (!mounted) return;

    final data = jsonDecode(response.body);

    _alert(data['message'] ?? 'Skills updated successfully');
  } catch (e) {
    _alert("❌ Error: $e");
  } finally {
    if (mounted) {
      setState(() => isSubmitting = false);
    }
  }
}

  void _alert(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Notice'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Skills'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary),)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedExam,
                          decoration: InputDecoration(
                            labelText: 'Select Exam',
                            border: OutlineInputBorder(),
                          ),
                          items: exams.map((exam) {
                            if (exams.isNotEmpty)
                              selectedExam ??= exams.first['ExamId'].toString();
                            return DropdownMenuItem(
                              value: exam['ExamId'].toString(),
                              child: Text(exam['Exam']),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedExam = value;
                            });
                          },
                        ),
                        SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedSkill,
                          decoration: InputDecoration(
                            labelText: 'Select Skill',
                            border: OutlineInputBorder(),
                          ),
                          items: skills
                              .map(
                                (skill) => DropdownMenuItem(
                                  value: skill['SkillId'].toString(),
                                  child: Text(skill['Skill']),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => selectedSkill = val),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: selectedSkill == null
                                ? null
                                : _fetchStudents,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                            child: const Text(
                              'Search',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (showTable) ...[
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search by name or roll',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (query) {
                      setState(() {
                        filteredList = studentList.where((s) {
                          final name = s['name'].toLowerCase();
                          final roll = s['roll'].toString();
                          return name.contains(query.toLowerCase()) ||
                              roll.contains(query);
                        }).toList();
                      });
                    },
                  ),
                  SizedBox(height: 12),
                  ...filteredList.map((student) {
                    final isMarked =
                        (student['Grade']?.toString().trim().isNotEmpty ??
                        false);
                    return Container(
                      decoration: BoxDecoration(
                        color: isMarked
                            ? Colors.green.shade50
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isMarked ? Colors.green : Colors.red,
                          width: 1.2,
                        ),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Roll No: ${student['roll']}  |  ${student['name']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Father: ${student['father']}',
                            style: const TextStyle(
                              color: Colors.grey,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 1,
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              const Text('Grade:'),
                              SizedBox(width: 8),
                              SizedBox(
                                width: 80,
                                child: TextField(
                                  controller:
                                      gradeControllers[student['studentid']
                                          .toString()],
                                  decoration: InputDecoration(
                                    hintText: 'Grade',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                  ),
                                  onChanged: (val) {
                                    final grade = val.trim().toUpperCase();
                                    student['Grade'] = grade;
                                    student['status'] = grade.isNotEmpty
                                        ? 'Marked'
                                        : 'Not Marked';

                                    final idx = studentList.indexWhere(
                                      (s) =>
                                          s['studentid'] ==
                                          student['studentid'],
                                    );

                                    if (idx != -1) {
                                      studentList[idx]['Grade'] = val;
                                      studentList[idx]['status'] =
                                          student['status'];
                                    }
                                    setState(() {});
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: isSubmitting
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primary),)
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submitSkills,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text(
                                'Submit Skills',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ],
            ),
    );
  }
}
