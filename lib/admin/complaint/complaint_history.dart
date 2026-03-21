import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';

class AdminComplaintHistory extends StatefulWidget {
  final int complaintId;
  final Map complaintData;

  const AdminComplaintHistory({
    super.key,
    required this.complaintId,
    required this.complaintData,
  });

  @override
  State<AdminComplaintHistory> createState() => _AdminComplaintHistoryState();
}

class _AdminComplaintHistoryState extends State<AdminComplaintHistory> {
  List historyList = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    setState(() => isLoading = true);

    print("Fetching history for ID: ${widget.complaintId}");

    final response = await ApiService.post(
      context,
      "/admin/complaint/history",
      body: {"ComplaintId": widget.complaintId.toString()},
    );

    if (response != null && response.statusCode == 200) {
      historyList = jsonDecode(response.body);
      print("History Count: ${historyList.length}");
    } else {
      historyList = [];
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4e9fb),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: const BackButton(),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Complaint History",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// ===== MAIN COMPLAINT CARD =====
                  _mainComplaintCard(widget.complaintData),

                  const SizedBox(height: 12),

                  const Text(
                    "History",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 8),

                  historyList.isEmpty
                      ? const Center(child: Text("No history found"))
                      : Column(
                          children: historyList
                              .map((e) => _historyCard(e))
                              .toList(),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _mainComplaintCard(Map data) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Row 1
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "${data['Name']} - ${data['Class']}(${data['Section']})",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(data['Date'], style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            /// Row 2
            Row(
              children: [
                Icon(Icons.phone, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    data['ContactNo'].toString(),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),

                const SizedBox(width: 6),

                Icon(Icons.person, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text("Added by ", style: const TextStyle(fontSize: 11)),
                Expanded(
                  child: Text(
                    data['AddedBy'],
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            /// Description + Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.description,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          data['Description'],
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _statusBadge(data['Status']),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(int status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status == 0 ? Colors.red : Colors.green,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status == 0 ? "Pending" : "Resolved",
        style: const TextStyle(fontSize: 10, color: Colors.white),
      ),
    );
  }

  Widget _historyCard(Map data) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// DATE ROW
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  data['Date'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            /// DESCRIPTION
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.description, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    data['Description'],
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
