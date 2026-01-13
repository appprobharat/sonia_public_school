import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';
import 'package:sonia_public_school/connect_teacher/teacher_chat.dart';

class TeacherChatStudentListPage extends StatefulWidget {
  const TeacherChatStudentListPage({super.key});

  @override
  State<TeacherChatStudentListPage> createState() =>
      _TeacherChatStudentListPageState();
}

class _TeacherChatStudentListPageState
    extends State<TeacherChatStudentListPage> {
  List<dynamic> students = [];
  List<dynamic> filteredStudents = [];

  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  // ====================================================
  // 🔐 SAFE FETCH STUDENTS (iOS + Android)
  // ====================================================
  Future<void> fetchStudents() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final res = await ApiService.post(
        context,
        "/teacher/student/list",
      );

      // AuthHelper already handles 401 + logout
      if (res == null) return;

      debugPrint("📥 STUDENT LIST STATUS: ${res.statusCode}");
      debugPrint("📥 STUDENT LIST BODY: ${res.body}");

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);

        if (!mounted) return;
        setState(() {
          students = data;
          filteredStudents = data;
        });
      } else {
        if (!mounted) return;
        setState(() {
          students.clear();
          filteredStudents.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load students")),
        );
      }
    } catch (e) {
      debugPrint("🚨 FETCH STUDENTS ERROR: $e");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong")),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // ====================================================
  // 🔍 SEARCH FILTER
  // ====================================================
  void _filterStudents(String query) {
    if (!mounted) return;

    setState(() {
      filteredStudents = students
          .where(
            (s) => s['StudentName']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  // ====================================================
  // 🧱 UI (UNCHANGED)
  // ====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: _isSearching
            ? TextField(
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'Search student...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: _filterStudents,
              )
            : const Text(
                "Students Chat",
                style: TextStyle(color: Colors.white),
              ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  filteredStudents = students;
                }
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary),)
          : filteredStudents.isEmpty
              ? const Center(
                  child: Text(
                    "No students found",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: filteredStudents.length,
                  itemBuilder: (context, index) {
                    return _buildStudentCard(filteredStudents[index]);
                  },
                ),
    );
  }

  Widget _buildStudentCard(dynamic student) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1.5,
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeacherChatScreen(
                studentId: student['id'],
                studentName: student['StudentName'] ?? 'Unknown',
                studentPhoto: student['StudentPhoto'] ?? '',
              ),
            ),
          );
        },
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: student['StudentPhoto'] != null &&
                  student['StudentPhoto'].toString().isNotEmpty
              ? NetworkImage(student['StudentPhoto'])
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                student['StudentName'] ?? 'Unknown',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
            if (student['RollNo'] != null)
              Text(
                "Roll No: ${student['RollNo']}",
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              "DOB: ${student['DOB'] ?? 'N/A'}",
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 2),
            Text(
              "Father: ${student['FatherName'] ?? ''}",
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        trailing: const Icon(
          Icons.chat_bubble_outline,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
