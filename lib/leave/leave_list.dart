import 'dart:convert';
import 'package:sonia_public_school/leave/leave_apply.dart';
import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class LeaveListPage extends StatefulWidget {
  const LeaveListPage({super.key});

  @override
  State<LeaveListPage> createState() => _LeaveListPageState();
}

class _LeaveListPageState extends State<LeaveListPage> {
  List<dynamic> leaves = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLeaves();
  }

  Future<void> fetchLeaves() async {
    setState(() => isLoading = true);

    final response = await ApiService.post(context, "/student/leave");

    if (response != null && response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        leaves = data;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      debugPrint("❌ Failed to load leave list");
    }
  }

  Color getStatusColor(dynamic status) {
    final text = getStatusText(status);

    switch (text.toLowerCase()) {
      case "approved":
        return Colors.green;
      case "pending":
        return Colors.orange;
      case "rejected":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> openAttachment(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint("❌ Cannot open file");
    }
  }

  String getStatusText(dynamic status) {
    /// 🔹 Handle numeric values

    if (status == 1 || status == "1") return "Approved";
    if (status == 0 || status == "0") return "Pending";

    final s = status.toString().toLowerCase();

    if (s == "approved") return "Approved";
    if (s == "rejected") return "Rejected";
    if (s == "pending") return "Pending";

    /// 🔹 Default case
    return "Pending";
  }

  Widget buildLeaveCard(Map<String, dynamic> leave) {
    final statusText = getStatusText(leave["Status"]);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 Purpose (Top)
            Text(
              leave["Purpose"] ?? "",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 6),

            /// 🔹 Row 1 → Start & End Date
            Row(
              children: [
                /// 🔹 Left → Start Date
                const Icon(Icons.calendar_month, size: 14),
                const SizedBox(width: 4),
                Text(leave["StartDate"], style: const TextStyle(fontSize: 12)),

                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward, size: 14),
                const SizedBox(width: 6),

                /// 🔹 End Date
                Text(leave["EndDate"], style: const TextStyle(fontSize: 12)),

                /// 🔹 Spacer → push attachment right
                const Spacer(),

                /// 🔹 Attachment (ONLY if exists)
                if (leave["Attachment"] != null &&
                    leave["Attachment"].toString().isNotEmpty)
                  InkWell(
                    onTap: () {
                      openAttachment(leave["Attachment"]);
                    },
                    child: Row(
                      children: const [
                        Icon(Icons.attach_file, size: 14, color: Colors.blue),
                        SizedBox(width: 2),
                        Text(
                          "File",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            /// 🔹 Row 2 → Days | Applied | Status
            Row(
              children: [
                /// Days
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.timelapse, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "${leave["LeaveDays"]} days",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),

                /// Applied Date
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.edit_calendar, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        leave["ApplyDate"],
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),

                /// Status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: getStatusColor(statusText).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: getStatusColor(statusText),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Leaves'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      /// ✅ FAB ADDED HERE
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      floatingActionButton: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10, right: 4),
          child: FloatingActionButton.extended(
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add),
            label: const Text("Apply"),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ApplyLeavePage()),
              );

              if (result == true) {
                fetchLeaves();
              }
            },
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : leaves.isEmpty
          ? const Center(child: Text("No leave records found"))
          : RefreshIndicator(
              onRefresh: fetchLeaves,
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: leaves.length,
                itemBuilder: (context, index) {
                  return buildLeaveCard(leaves[index]);
                },
              ),
            ),
    );
  }
}
