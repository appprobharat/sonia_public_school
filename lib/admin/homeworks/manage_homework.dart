import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

import 'package:sonia_public_school/admin/homeworks/admin_addhomework.dart';
import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';

class AdminHomework extends StatefulWidget {
  const AdminHomework({super.key});

  @override
  State<AdminHomework> createState() => _AdminHomeworkState();
}

class _AdminHomeworkState extends State<AdminHomework> {
  final TextEditingController searchCtrl = TextEditingController();

  List homeworkList = [];
  bool isLoading = false;

  late String fromDate;
  late String toDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final oneMonthBack = DateTime(now.year, now.month - 1, now.day);

    fromDate = _formatDate(oneMonthBack);
    toDate = _formatDate(now);

    fetchHomework();
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String _formatDisplayDate(String date) {
    final parts = date.split("-"); // yyyy-MM-dd
    if (parts.length == 3) {
      return "${parts[2]}-${parts[1]}-${parts[0]}";
    }
    return date;
  }

  Future<void> _downloadFile(BuildContext context, String url) async {
    if (url.isEmpty) return;

    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Downloading...")));

      final fileName = url.split('/').last;
      late File file;

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw Exception("Download failed");
      }

      /// ANDROID → Download folder (visible in gallery)
      if (Platform.isAndroid) {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        file = File('${downloadsDir.path}/$fileName');

        await file.writeAsBytes(response.bodyBytes, flush: true);
        await OpenFile.open(file.path);
      }

      /// IOS
      if (Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        file = File('${dir.path}/$fileName');

        await file.writeAsBytes(response.bodyBytes, flush: true);
        await OpenFile.open(file.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Download failed")));
    }
  }

  Future<void> _pickDate(bool isFrom) async {
    DateTime initialDate = DateTime.parse(isFrom ? fromDate : toDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      String formatted = _formatDate(picked);

      setState(() {
        if (isFrom) {
          fromDate = formatted;
        } else {
          toDate = formatted;
        }
      });

      fetchHomework();
    }
  }

  Future<void> fetchHomework() async {
    setState(() => isLoading = true);

    final response = await ApiService.post(
      context,
      "/admin/homework/list",
      body: {"from": fromDate, "to": toDate},
    );
    debugPrint("BODY: ${response?.body}");
    if (response != null && response.statusCode == 200) {
      homeworkList = jsonDecode(response.body);
    } else {
      homeworkList = [];
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
        leading: BackButton(),
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          "Manage Homeworks",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AdminAddHomework()),
              );

              if (result == true) {
                fetchHomework();
              }
            },
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                _dateField("From", fromDate, true),
                const SizedBox(width: 8),
                _dateField("To", toDate, false),
              ],
            ),
          ),

          /// LIST
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : homeworkList.isEmpty
                ? const Center(child: Text("No homework found"))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: homeworkList.length,
                    itemBuilder: (context, index) {
                      return _homeworkCard(homeworkList[index], index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _dateField(String label, String date, bool isFrom) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _pickDate(isFrom),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _formatDisplayDate(date),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// HOMEWORK CARD
  Widget _homeworkCard(Map item, int index) {
    final homeworkId = item['id'];
    final className = item['Class']?.toString() ?? "";
    final section = item['Section']?.toString() ?? "";
    final date = item['Date']?.toString() ?? "";
    final Title = item['Title']?.toString() ?? "";
    final submission = item['Submission']?.toString() ?? "";
    final remark = item['Remark']?.toString() ?? "";
    final addedBy = item['AddedBy']?.toString() ?? "";
    final attachment = item['Attachment']?.toString() ?? "";

    final isAdmin = addedBy.toLowerCase() == "admin";

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ===== ROW 1 → CLASS + DATE + ADMIN BADGE =====
            Row(
              children: [
                Icon(Icons.school, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),

                Expanded(
                  child: Text(
                    "$className ($section)",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                /// ADMIN BADGE TOP RIGHT
                if (isAdmin)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "ADMIN",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                const SizedBox(width: 8),

                Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(date, style: const TextStyle(fontSize: 11)),
              ],
            ),

            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.title, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),

                Expanded(
                  child: Text(
                    Title.isEmpty ? "No Title available" : Title,

                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),

            /// ===== ROW 2 → REMARK + DOWNLOAD =====
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.description, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),

                Expanded(
                  child: Text(
                    remark.isEmpty ? "No remark available" : remark,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                _iconBtn(Icons.edit, AppColors.primary, () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminAddHomework(homeworkId: homeworkId),
                    ),
                  );

                  if (result == true) {
                    fetchHomework();
                  }
                }),
                SizedBox(width: 5),
                if (attachment.isNotEmpty)
                  _iconBtn(
                    Icons.download,
                    Colors.green,
                    () => _downloadFile(context, attachment),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            /// ===== ROW 3 → ASSIGN LEFT + SUBMISSION RIGHT =====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Assign: $addedBy", style: const TextStyle(fontSize: 11)),

                Text(
                  "Submission: $submission",
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 28,
        width: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
