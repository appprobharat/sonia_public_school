import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sonia_public_school/api_service.dart';
import 'package:sonia_public_school/complaint/addComplaint.dart';
import 'package:sonia_public_school/complaint/complaint_detail_page.dart';

class ViewComplaintPage extends StatefulWidget {
  const ViewComplaintPage({super.key});

  @override
  State<ViewComplaintPage> createState() => _ViewComplaintPageState();
}

class _ViewComplaintPageState extends State<ViewComplaintPage> {
  List<dynamic> complaints = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchComplaints();
  }

  // ====================================================
  // 🔐 SAFE FETCH COMPLAINTS (iOS + ANDROID)
  // ====================================================
  Future<void> fetchComplaints() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final res = await ApiService.post(context, '/student/complaint');

      // AuthHelper handles 401 + logout
      if (res == null) return;

      debugPrint("📥 COMPLAINT LIST STATUS: ${res.statusCode}");
      debugPrint("📥 COMPLAINT LIST BODY: ${res.body}");

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        if (!mounted) return;
        setState(() {
          complaints = decoded is List ? decoded : [];
        });
      } else {
        if (!mounted) return;
        complaints = [];
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load complaints')),
        );
      }
    } catch (e) {
      debugPrint("🚨 COMPLAINT LIST ERROR: $e");

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Something went wrong')));
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Color getStatusColor(int status) {
    return status == 1 ? Colors.green : Colors.orange;
  }

  String getStatusText(int status) {
    return status == 1 ? 'Solved' : 'Pending';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Complaints',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : complaints.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.support_agent_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "No Complaints Yet",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Tap + button to raise a complaint.",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: complaints.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final complaint = complaints[index];
                final status = complaint['Status'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
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
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ComplaintDetailPage(
                            complaintId: complaint['id'],
                            date: complaint['Date'],
                            description: complaint['Description'],
                            status: status,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 88,
                          decoration: BoxDecoration(
                            color: getStatusColor(status),
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(14),
                            ),
                          ),
                        ),

                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(
                                          .08,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.calendar_today_rounded,
                                        size: 15,
                                        color: AppColors.primary,
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    Expanded(
                                      child: Text(
                                        formatDate(complaint['Date'] ?? ''),
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),

                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: getStatusColor(
                                          status,
                                        ).withOpacity(.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            status == 1
                                                ? Icons.check_circle
                                                : Icons.schedule,
                                            color: getStatusColor(status),
                                            size: 12,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            getStatusText(status),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: getStatusColor(status),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 6),

                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  complaint['Description']?.replaceAll(
                                        r"\r\n",
                                        "\n",
                                      ) ??
                                      "",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.grey.shade700,
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
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddComplaint()),
          ).then((_) {
            fetchComplaints(); // refresh after add
          });
        },
      ),
    );
  }
}

// ====================================================
// 📅 DATE FORMATTER (SAFE)
// ====================================================
String formatDate(String dateStr) {
  try {
    final date = DateTime.parse(dateStr);
    return DateFormat('dd-MM-yyyy').format(date);
  } catch (_) {
    return dateStr;
  }
}
