import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sonia_public_school/api_service.dart';

class TeacherComplaintDetailPage extends StatefulWidget {
  final int complaintId;
  final String date;
  final String description;
  final int status;
  final String studentName;

  const TeacherComplaintDetailPage({
    super.key,
    required this.complaintId,
    required this.date,
    required this.description,
    required this.status,
    required this.studentName,
  });

  @override
  State<TeacherComplaintDetailPage> createState() =>
      _TeacherComplaintDetailPageState();
}

class _TeacherComplaintDetailPageState
    extends State<TeacherComplaintDetailPage> {
  List<dynamic> history = [];
  bool isLoading = true;

  final String apiUrl =
      '${ApiService.Url}/api/teacher/complaint/history';

  @override
  void initState() {
    super.initState();
    fetchComplaintHistory();
  }

  // ---------------- FETCH HISTORY ----------------
 Future<void> fetchComplaintHistory() async {
  debugPrint("🟡 fetchComplaintHistory START");
  debugPrint("🆔 ComplaintId: ${widget.complaintId}");

  try {
    final response = await ApiService.post(
      context,
      '/teacher/complaint/history',
      body: {
        'ComplaintId': widget.complaintId.toString(),
      },
    );

    // token expired → AuthHelper logout kara dega
    if (response == null || !mounted) return;

    debugPrint("🟢 STATUS CODE: ${response.statusCode}");
    debugPrint("📦 RAW BODY: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      setState(() {
        history = decoded is List ? decoded : [];
        isLoading = false;
      });

      debugPrint("📊 HISTORY COUNT: ${history.length}");
    } else {
      setState(() {
        history = [];
        isLoading = false;
      });
      debugPrint("⚠️ Non-200 response");
    }
  } catch (e) {
    debugPrint("❌ fetchComplaintHistory ERROR: $e");
    if (!mounted) return;
    setState(() {
      history = [];
      isLoading = false;
    });
  }

  debugPrint("🔚 fetchComplaintHistory END");
}

  // ---------------- HELPERS ----------------
  String getStatusText(int status) => status == 1 ? "Solved" : "Pending";

  Color getStatusColor(int status) =>
      status == 1 ? Colors.green : Colors.orange;

  String formatDate(String rawDate) {
    try {
      final parsedDate = DateTime.parse(rawDate);
      return DateFormat('dd-MM-yyyy').format(parsedDate);
    } catch (_) {
      return rawDate;
    }
  }

  // ---------------- UI (UNCHANGED) ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Complaint Details", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        leading: const BackButton(color: Colors.white),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔷 Complaint Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.studentName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.date_range,
                                  color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                formatDate(widget.date),
                                style:
                                    const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: getStatusColor(widget.status)
                                      .withOpacity(0.1),
                                  border: Border.all(
                                      color: getStatusColor(widget.status)),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  getStatusText(widget.status),
                                  style: TextStyle(
                                    color: getStatusColor(widget.status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.description.replaceAll(r'\r\n', '\n'),
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🧾 History Section
                  const Text(
                    "Complaint History",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (history.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(child: Text("No history found.")),
                    )
                  else
                    ...history.map(
                      (item) => Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.timeline,
                                      size: 18, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    formatDate(item['Date'] ?? ''),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item['Description']
                                        ?.replaceAll(r'\r\n', '\n') ??
                                    '',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
