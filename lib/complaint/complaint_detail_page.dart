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
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.calendar_today_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ),

                            const SizedBox(width: 8),

                            Expanded(
                              child: Text(
                                formatDate(widget.date),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: getStatusColor(
                                  widget.status,
                                ).withOpacity(.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.status == 1
                                        ? Icons.check_circle
                                        : Icons.schedule,
                                    size: 13,
                                    color: getStatusColor(widget.status),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    getStatusText(widget.status),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: getStatusColor(widget.status),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Text(
                          widget.description.replaceAll(r'\r\n', '\n'),
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.5,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      const Icon(
                        Icons.history_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Complaint History",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (history.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.history_toggle_off_rounded,
                                size: 65,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "No History Found",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "Updates will appear here.",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ...history.map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Container(
                                  width: 2,
                                  height: 75,
                                  color: Colors.blue.shade100,
                                ),
                              ],
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(.04),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time_filled,
                                          size: 15,
                                          color: AppColors.primary,
                                        ),

                                        const SizedBox(width: 5),

                                        Text(
                                          formatDate(item['Date'] ?? ''),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    Text(
                                      item['Description']?.replaceAll(
                                            r'\r\n',
                                            '\n',
                                          ) ??
                                          '',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
