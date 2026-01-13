import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sonia_public_school/api_service.dart';

import 'package:sonia_public_school/teacher/complaint_teacher/teacher_add_complaint_page.dart';
import 'package:sonia_public_school/teacher/complaint_teacher/teacher_complaint_details.dart';

class TeacherComplaintListPage extends StatefulWidget {
  const TeacherComplaintListPage({super.key});

  @override
  State<TeacherComplaintListPage> createState() =>
      _TeacherComplaintListPageState();
}

class _TeacherComplaintListPageState extends State<TeacherComplaintListPage> {
  List<dynamic> complaints = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchComplaints();
  }

  // ---------------- FETCH COMPLAINTS ----------------
  Future<void> fetchComplaints() async {
    debugPrint("🟡 fetchComplaints START");

    if (mounted) setState(() => isLoading = true);

    try {
      final response = await ApiService.post(
        context,
        'https://school.edusathi.in/api/teacher/complaint',
      );

      // token expired → AuthHelper already logout kara dega
      if (response == null || !mounted) return;

      debugPrint("🟢 STATUS CODE: ${response.statusCode}");
      debugPrint("📦 RAW BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        setState(() {
          complaints = decoded is List ? decoded : [];
          isLoading = false;
        });

        debugPrint("📊 COMPLAINT COUNT: ${complaints.length}");
      } else {
        setState(() {
          complaints = [];
          isLoading = false;
        });
        debugPrint("⚠️ Non-200 response");
      }
    } catch (e) {
      debugPrint("❌ fetchComplaints ERROR: $e");
      if (!mounted) return;
      setState(() {
        complaints = [];
        isLoading = false;
      });
    }

    debugPrint("🔚 fetchComplaints END");
  }

  // ---------------- HELPERS ----------------
  Color getStatusColor(int status) =>
      status == 1 ? Colors.green : Colors.orange;

  String getStatusText(int status) => status == 1 ? 'Solved' : 'Pending';

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Student Complaints',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : complaints.isEmpty
          ? const Center(child: Text('No complaints available'))
          : RefreshIndicator(
              onRefresh: fetchComplaints,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: complaints.length,
                itemBuilder: (context, index) {
                  final complaint = complaints[index];
                  final int status = complaint['Status'] ?? 0;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TeacherComplaintDetailPage(
                            complaintId: complaint['id'],
                            date: complaint['Date'] ?? '',
                            description: complaint['Description'] ?? '',
                            status: status,
                            studentName: complaint['StudentName'] ?? '',
                          ),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              complaint['StudentName'] ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.date_range,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  formatDate(complaint['Date'] ?? ''),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: status != 0
                                      ? null
                                      : () => _openUpdateDialog(complaint),
                                  child: _buildStatusChip(status),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              complaint['Description']?.replaceAll(
                                    r"\r\n",
                                    "\n",
                                  ) ??
                                  '',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TeacherAddComplaintPage()),
          );
          if (result == true && mounted) {
            fetchComplaints();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ---------------- STATUS CHIP ----------------
  Widget _buildStatusChip(int status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: getStatusColor(status).withOpacity(0.1),
        border: Border.all(color: getStatusColor(status)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == 0 ? Icons.timelapse : Icons.check_circle,
            size: 16,
            color: getStatusColor(status),
          ),
          const SizedBox(width: 6),
          Text(
            getStatusText(status),
            style: TextStyle(
              color: getStatusColor(status),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- UPDATE DIALOG ----------------
  void _openUpdateDialog(Map complaint) {
    final TextEditingController descController = TextEditingController();
    int selectedStatus = 1;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Update Complaint"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: selectedStatus,
              items: const [
                DropdownMenuItem(value: 0, child: Text("Pending")),
                DropdownMenuItem(value: 1, child: Text("Solved")),
              ],
              onChanged: (v) => selectedStatus = v ?? 1,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Description"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (descController.text.trim().isEmpty) return;

              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('auth_token') ?? '';

              await http.post(
                Uri.parse(
                  "https://school.edusathi.in/api/teacher/complaint/history/store",
                ),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Accept': 'application/json',
                },
                body: {
                  'ComplaintId': complaint['id'].toString(),
                  'Status': selectedStatus.toString(),
                  'Description': descController.text.trim(),
                },
              );

              if (!mounted) return;
              Navigator.pop(context);
              fetchComplaints();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}

// ---------------- DATE FORMAT ----------------
String formatDate(String dateStr) {
  try {
    return DateFormat('dd-MM-yyyy').format(DateTime.parse(dateStr));
  } catch (_) {
    return dateStr;
  }
}
