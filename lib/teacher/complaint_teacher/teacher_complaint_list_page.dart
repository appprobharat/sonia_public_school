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
      final response = await ApiService.post(context, '/teacher/complaint');

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
      backgroundColor: const Color(0xffF5F7FB),
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

                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
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
                            color: Colors.black.withOpacity(.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 42,
                            width: 42,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.report_problem_outlined,
                              color: AppColors.primary,
                              size: 20,
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
                                        complaint['StudentName'] ?? "-",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),

                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: status == 0
                                          ? () => _openUpdateDialog(complaint)
                                          : null,
                                      child: _buildStatusChip(status),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 5),

                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      formatDate(complaint['Date'] ?? ''),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 5),

                                Text(
                                  complaint['Description']?.replaceAll(
                                        r"\r\n",
                                        "\n",
                                      ) ??
                                      "",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 4),

                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: Colors.grey.shade400,
                          ),
                        ],
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
    final solved = status == 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: solved ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            solved ? Icons.check_circle : Icons.access_time_filled,
            size: 13,
            color: solved ? Colors.green : Colors.orange,
          ),

          const SizedBox(width: 4),

          Text(
            solved ? "Solved" : "Pending",
            style: TextStyle(
              color: solved ? Colors.green : Colors.orange,
              fontSize: 11,
              fontWeight: FontWeight.w700,
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
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: AppColors.primary,
                      size: 30,
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    "Update Complaint",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    complaint['StudentName'] ?? "",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),

                  const SizedBox(height: 18),

                  DropdownButtonFormField<int>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      labelText: "Complaint Status",
                      prefixIcon: const Icon(Icons.flag_outlined),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text("Pending")),
                      DropdownMenuItem(value: 1, child: Text("Solved")),
                    ],
                    onChanged: (v) {
                      setDialogState(() {
                        selectedStatus = v ?? 1;
                      });
                    },
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: descController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Write update...",
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 60),
                        child: Icon(Icons.description_outlined),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.save_outlined, size: 18),
                          label: const Text("Save"),
                          onPressed: () async {
                            if (descController.text.trim().isEmpty) return;

                            final prefs = await SharedPreferences.getInstance();
                            final token = prefs.getString('auth_token') ?? '';

                            await http.post(
                              Uri.parse(
                                "${ApiService.Url}/api/teacher/complaint/history/store",
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
