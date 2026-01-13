import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sonia_public_school/api_service.dart';

class ComplaintDetailPage extends StatefulWidget {
  final int complaintId;
  final String date;
  final String description;
  final int status;

  const ComplaintDetailPage({
    super.key,
    required this.complaintId,
    required this.date,
    required this.description,
    required this.status,
  });

  @override
  State<ComplaintDetailPage> createState() => _ComplaintDetailPageState();
}

class _ComplaintDetailPageState extends State<ComplaintDetailPage> {
  List<dynamic> history = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchComplaintHistory();
  }

  // ====================================================
  // 🔐 SAFE FETCH COMPLAINT HISTORY (iOS + ANDROID)
  // ====================================================
  Future<void> fetchComplaintHistory() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final res = await ApiService.post(
        context,
        '/student/complaint/history',
        body: {"ComplaintId": widget.complaintId},
      );

      // AuthHelper already handles 401 + logout
      if (res == null) return;

      debugPrint("📥 COMPLAINT HISTORY STATUS: ${res.statusCode}");
      debugPrint("📥 COMPLAINT HISTORY BODY: ${res.body}");

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        if (!mounted) return;

        if (decoded is List) {
          setState(() {
            history = decoded;
          });
        } else {
          history = [];
        }
      } else {
        if (!mounted) return;
        history = [];
      }
    } catch (e) {
      debugPrint("🚨 HISTORY ERROR: $e");

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Something went wrong")));
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  String getStatusText(int status) {
    return status == 1 ? "Solved" : "Pending";
  }

  Color getStatusColor(int status) {
    return status == 1 ? Colors.green : Colors.orange;
  }

  String formatDate(String rawDate) {
    try {
      final parsedDate = DateTime.parse(rawDate);
      return DateFormat('dd-MM-yyyy').format(parsedDate);
    } catch (_) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Complaint Details",
          style: TextStyle(color: Colors.white),
        ),
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
                  // 🔷 Original Complaint
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.date_range,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                formatDate(widget.date),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: getStatusColor(
                                    widget.status,
                                  ).withOpacity(0.1),
                                  border: Border.all(
                                    color: getStatusColor(widget.status),
                                  ),
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

                  // 🧾 History
                  const Text(
                    "Complaint History",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                                  const Icon(
                                    Icons.timeline,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    formatDate(item['Date'] ?? ''),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item['Description']?.replaceAll(
                                      r'\r\n',
                                      '\n',
                                    ) ??
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
