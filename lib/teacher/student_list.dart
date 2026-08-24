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
        body: {"type": "all"},
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
      final parts = dob.split('-'); // dd-MM-yyyy

      return "${parts[0]}-${parts[1]}-${parts[2]}"; // same format return
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
        centerTitle: true,
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
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.groups_rounded,
                    size: 70,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "No Students Found",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Student records will appear here.",
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];

                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {},
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        /// Avatar
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: Colors.grey.shade200,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.network(
                              student['StudentPhoto'] ?? "",
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return Center(
                                  child: Text(
                                    (student['StudentName'] ?? "S")
                                        .toString()[0]
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;

                                return const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      student['StudentName'] ?? "-",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),

                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(.10),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "Roll ${student['RollNo'] ?? '-'}",
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 5),

                              Text(
                                student['FatherName'] ?? "-",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),

                              const SizedBox(height: 3),

                              Row(
                                children: [
                                  Icon(
                                    Icons.cake_outlined,
                                    size: 13,
                                    color: Colors.orange.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    formatDate(student['DOB']),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 6),

                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey.shade400,
                          size: 20,
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
