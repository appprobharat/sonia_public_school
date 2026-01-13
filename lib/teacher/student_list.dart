import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';


class StudentListPage extends StatefulWidget {
  const StudentListPage({super.key});

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  bool _isLoading = false;
  List<dynamic> _students = [];

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  // ---------------- FETCH STUDENTS ----------------
  Future<void> fetchStudents() async {
    if (!mounted) return;

    debugPrint("🟡 fetchStudents CALLED");

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.post(
        context,
        '/teacher/student/list',
      );

      if (response == null) {
        debugPrint("🔴 RESPONSE NULL (TOKEN EXPIRED)");
        return;
      }

      debugPrint("🟢 STATUS CODE: ${response.statusCode}");
      debugPrint("📦 RAW BODY: ${response.body}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        debugPrint("📦 DECODED TYPE: ${decoded.runtimeType}");

        List list = [];

        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          list = decoded['data'];
        }

        debugPrint("📊 STUDENT COUNT: ${list.length}");

        setState(() {
          _students = list;
        });
      } else {
        debugPrint("❌ API ERROR: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load students (${response.statusCode})'),
          ),
        );
      }
    } catch (e) {
      debugPrint("🚨 EXCEPTION: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint("🔚 fetchStudents END");
      }
    }
  }

  // ---------------- DATE FORMAT ----------------
  String formatDate(String? dob) {
    if (dob == null || dob.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dob);
      return "${date.day.toString().padLeft(2, '0')}-"
          "${date.month.toString().padLeft(2, '0')}-"
          "${date.year}";
    } catch (_) {
      return 'Invalid';
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Student List',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchStudents,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _students.isEmpty
          ? const Center(
              child: Text('No students found', style: TextStyle(fontSize: 16)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student['StudentName'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Roll No: ${student['RollNo'] ?? '-'}",
                          style: const TextStyle(fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Father: ${student['FatherName'] ?? '-'}",
                          style: const TextStyle(fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "DOB: ${formatDate(student['DOB'])}",
                          style: const TextStyle(fontSize: 15),
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
