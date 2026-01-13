import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:sonia_public_school/api_service.dart';

class ViewHomeworksPage extends StatelessWidget {
  final List<Map<String, dynamic>> homeworks;

  const ViewHomeworksPage({super.key, required this.homeworks});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Assigned Homeworks",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: homeworks.length,
        itemBuilder: (context, index) {
          final hw = homeworks[index];

          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(hw['HomeworkTitle'] ?? 'No Title'),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Assign: ${_formatDate(hw['WorkDate'])}"),
                    Text("Submit: ${_formatDate(hw['SubmissionDate'])}"),
                    Text("Remark: ${hw['Remark'] ?? ''}"),
                  ],
                ),
              ),
              trailing: hw['Attachment'] != null
                  ? IconButton(
                      icon: const Icon(
                        Icons.download,
                        color: AppColors.primary,
                      ),
                      onPressed: () {
                        String fileUrl = hw['Attachment'];
                        if (!fileUrl.startsWith('http')) {
                          fileUrl =
                              ApiService.homeworkAttachment(fileUrl);
                        }
                        downloadFile(context, fileUrl);
                      },
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  // ============================
  // 📥 SAFE DOWNLOAD (iOS + ANDROID)
  // ============================
  Future<void> downloadFile(BuildContext context, String fileUrl) async {
    try {
      final response = await http.get(Uri.parse(fileUrl));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw Exception("Failed to download file");
      }

      // ✅ App-specific directory (NO permission needed)
      final dir = await getApplicationDocumentsDirectory();
      final fileName = fileUrl.split('/').last;
      final file = File('${dir.path}/$fileName');

      await file.writeAsBytes(response.bodyBytes, flush: true);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Downloaded to ${file.path}")));

      await OpenFile.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Download error: $e")));
    }
  }
}
