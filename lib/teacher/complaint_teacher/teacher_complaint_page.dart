import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sonia_public_school/api_service.dart';


class TeacherComplaintPage extends StatefulWidget {
  final int complaintId;
  final String date;
  final String description;
  final int status;

  const TeacherComplaintPage({
    super.key,
    required this.complaintId,
    required this.date,
    required this.description,
    required this.status,
  });

  @override
  State<TeacherComplaintPage> createState() => _TeacherComplaintPageState();
}

class _TeacherComplaintPageState extends State<TeacherComplaintPage> {
  List<dynamic> complaintHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchComplaintHistory();
  }

  // ---------------- FETCH HISTORY ----------------
  Future<void> fetchComplaintHistory() async {
    try {
      if (mounted) setState(() => isLoading = true);

      final response = await ApiService.post(
        context,
        'https://school.edusathi.in/api/teacher/complaint/history',
        body: {'ComplaintId': widget.complaintId},
      );

      // 🔐 token expired → auto logout handled
      if (response == null || !mounted) return;

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);

        setState(() {
          complaintHistory = decoded is List ? decoded : [];
          isLoading = false;
        });
      } else {
        setState(() {
          complaintHistory = [];
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        complaintHistory = [];
        isLoading = false;
      });
    }
  }

  String formatDate(String raw) {
    try {
      return DateFormat('dd-MM-yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  // ---------------- STATUS BADGE ----------------
  Widget getStatusBadge(int status) {
    String text;
    Color color;

    switch (status) {
      case 0:
        text = 'Pending';
        color = Colors.orange;
        break;
      case 1:
        text = 'Resolved';
        color = Colors.green;
        break;
      default:
        text = 'Unknown';
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Complaint Details"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary),)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔷 Complaint Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("📅 ${formatDate(widget.date)}"),

                        const SizedBox(height: 8),
                        Text(
                          widget.description.replaceAll(r'\r\n', '\n'),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        getStatusBadge(widget.status),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    "Complaint History",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (complaintHistory.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text("No history available")),
                    )
                  else
                    ...complaintHistory.map((entry) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "📅 ${entry['Date'] ?? ''}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry['Description']?.replaceAll(
                                      r'\r\n',
                                      '\n',
                                    ) ??
                                    '',
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
    );
  }
}
