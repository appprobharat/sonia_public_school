import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class LeaveApprovalListPage extends StatefulWidget {
  const LeaveApprovalListPage({super.key});

  @override
  State<LeaveApprovalListPage> createState() => _LeaveApprovalListPageState();
}

class _LeaveApprovalListPageState extends State<LeaveApprovalListPage> {
  List<dynamic> leaves = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLeaves();
  }

  Future<void> openAttachment(String url) async {
    final Uri uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint("❌ Could not open attachment");
    }
  }

  Future<void> updateLeaveStatus(int id, int status) async {
    setState(() {});

    final body = {"id": id, "Status": status.toString()};

    final response = await ApiService.post(
      context,
      "/teacher/leave/action",
      body: body,
    );

    if (response != null && response.statusCode == 200) {
      setState(() {
        final index = leaves.indexWhere((e) => e["id"] == id);
        if (index != -1) {
          leaves[index]["Status"] = status == 1 ? "Approved" : "Rejected";
        }
      });
    }
  }

  Future<void> fetchLeaves() async {
    setState(() => isLoading = true);

    final response = await ApiService.post(context, "/teacher/leave");

    if (response != null && response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        leaves = data;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
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

  void confirmAction(int id, int status) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm"),
        content: Text(
          status == 1 ? "Approve this leave?" : "Reject this leave?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              updateLeaveStatus(id, status);
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  Widget buildLeaveCard(Map<String, dynamic> leave) {
    final status = leave["Status"].toString().toLowerCase();

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 Row → Name + Status Badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    leave["StudentName"] ?? "",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                /// Status Badge
                buildStatusChip(leave["Status"]),
              ],
            ),

            const SizedBox(height: 3),

            /// 🔹 Purpose
            Text(
              leave["Purpose"] ?? "",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),

            const SizedBox(height: 4),

            /// 🔹 Row → Start → End
            Row(
              children: [
                /// Left → Dates
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        leave["StartDate"],
                        style: const TextStyle(fontSize: 11),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward, size: 12),
                      const SizedBox(width: 6),
                      Text(
                        leave["EndDate"],
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),

                /// Right → Attachment
                if (leave["Attachment"] != null &&
                    leave["Attachment"].toString().isNotEmpty)
                  InkWell(
                    onTap: () => openAttachment(leave["Attachment"]),
                    child: Row(
                      children: const [
                        Icon(Icons.attach_file, size: 12, color: Colors.blue),
                        SizedBox(width: 2),
                        Text(
                          "File",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 4),

            /// 🔹 Row → Days | Apply Date
            Row(
              children: [
                /// Left → Days
                Expanded(
                  child: Text(
                    "${leave["LeaveDays"]} days",
                    style: const TextStyle(fontSize: 11),
                  ),
                ),

                /// Right → Apply Date
                Text(
                  leave["ApplyDate"],
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 4),

            /// 🔹 Action Buttons (compact style)
            if (status == "pending")
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  buildActionChip(
                    "Reject",
                    Colors.red,
                    () => confirmAction(leave["id"], 0),
                  ),

                  buildActionChip(
                    "Approve",
                    Colors.green,
                    () => confirmAction(leave["id"], 1),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget buildStatusChip(String status) {
    Color color = getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget buildActionChip(String text, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Approval'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : leaves.isEmpty
          ? const Center(child: Text("No leave requests"))
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
