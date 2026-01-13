import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';

class TeacherAddComplaintPage extends StatefulWidget {
  const TeacherAddComplaintPage({super.key});

  @override
  State<TeacherAddComplaintPage> createState() =>
      _TeacherAddComplaintPageState();
}

class _TeacherAddComplaintPageState extends State<TeacherAddComplaintPage> {
  final _formKey = GlobalKey<FormState>();

  List<dynamic> students = [];
  int? selectedStudentId;
  final TextEditingController descriptionController = TextEditingController();

  bool isSubmitting = false;
  bool isLoadingStudents = true;

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  // ---------------- FETCH STUDENTS ----------------
 Future<void> fetchStudents() async {
  debugPrint("🟡 fetchStudents START");

  try {
    final response = await ApiService.post(
      context,
      '/get_student',
    );

    // token expired → AuthHelper logout kara dega
    if (response == null || !mounted) return;

    debugPrint("🟢 STATUS CODE: ${response.statusCode}");
    debugPrint("📦 RAW BODY: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      setState(() {
        students = decoded is List ? decoded : [];
        isLoadingStudents = false;
      });

      debugPrint("📊 STUDENT COUNT: ${students.length}");
    } else {
      setState(() => isLoadingStudents = false);
      _showSnackBar("Failed to load students");
    }
  } catch (e) {
    debugPrint("❌ fetchStudents ERROR: $e");
    if (!mounted) return;
    setState(() {
      students = [];
      isLoadingStudents = false;
    });
    _showSnackBar("Error loading students");
  }

  debugPrint("🔚 fetchStudents END");
}


  // ---------------- SUBMIT COMPLAINT ----------------
 Future<void> submitComplaint() async {
  if (!_formKey.currentState!.validate()) return;

  if (selectedStudentId == null) {
    _showSnackBar("Please select a student");
    return;
  }

  setState(() => isSubmitting = true);

  debugPrint("🟡 submitComplaint START");

  try {
    final response = await ApiService.post(
      context,
      '/teacher/complaint/store',
      body: {
        'StudentId': selectedStudentId.toString(),
        'Description': descriptionController.text.trim(),
      },
    );

    if (response == null || !mounted) {
      if (mounted) setState(() => isSubmitting = false);
      return;
    }

    debugPrint("🟢 STATUS CODE: ${response.statusCode}");
    debugPrint("📦 RAW BODY: ${response.body}");

    final decoded = jsonDecode(response.body);

    setState(() => isSubmitting = false);

    if (response.statusCode == 200 && decoded['status'] == true) {
      _showSnackBar(decoded['message'] ?? "Complaint submitted");
      Navigator.pop(context, true);
    } else {
      _showSnackBar(decoded['message'] ?? "Submission failed");
    }
  } catch (e) {
    debugPrint("❌ submitComplaint ERROR: $e");
    if (!mounted) return;
    setState(() => isSubmitting = false);
    _showSnackBar("Something went wrong");
  }

  debugPrint("🔚 submitComplaint END");
}


  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ---------------- UI (UNCHANGED) ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Add Complaint",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                value: selectedStudentId,
                isExpanded: true,
                hint: const Text("Select Student"),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                items: students.map<DropdownMenuItem<int>>((student) {
                  final displayName =
                      "${student['StudentName']} S/D/O ${student['FatherName']}";
                  return DropdownMenuItem<int>(
                    value: student['id'],
                    child: Text(
                      displayName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedStudentId = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "Complaint Description",
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter complaint description";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: isSubmitting ? null : submitComplaint,
                icon: const Icon(Icons.send),
                label: const Text("Submit"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
