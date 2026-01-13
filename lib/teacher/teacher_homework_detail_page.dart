import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sonia_public_school/api_service.dart';

class TeacherHomeworkDetailPage extends StatelessWidget {
  final Map<String, dynamic> homework;

  const TeacherHomeworkDetailPage({super.key, required this.homework});

  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day.toString().padLeft(2, '0')}-"
          "${date.month.toString().padLeft(2, '0')}-"
          "${date.year}";
    } catch (_) {
      return dateStr;
    }
  }

  // ---------------- DOWNLOAD FILE ----------------
  Future<void> downloadFile(
    BuildContext context,
    String url,
    String fileName,
  ) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw Exception("Failed to download file");
      }

      // ================= ANDROID =================
      if (Platform.isAndroid) {
        // ✅ REAL Downloads folder (user visible)
        final Directory downloadsDir = Directory(
          '/storage/emulated/0/Download',
        );

        final String filePath = '${downloadsDir.path}/$fileName';
        final File file = File(filePath);

        await file.writeAsBytes(response.bodyBytes, flush: true);

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("📥 File saved to Downloads folder")),
        );
      }

      // ================= iOS =================
      if (Platform.isIOS) {
        final Directory dir = await getApplicationDocumentsDirectory();
        final String filePath = '${dir.path}/$fileName';

        final File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes, flush: true);

        if (!context.mounted) return;
        await OpenFile.open(filePath); // Files app
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ Download failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final attachment = homework['Attachment'];
    final String? fileName =
        (attachment != null && attachment.toString().isNotEmpty)
        ? Uri.parse(attachment.toString()).pathSegments.last
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Homework Details",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                homework['HomeworkTitle'] ?? 'Untitled',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Assignment: ${formatDate(homework['WorkDate'])}",
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    "Submission: ${formatDate(homework['SubmissionDate'])}",
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                "📝 Remark:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(homework['Remark'] ?? 'No remarks provided'),
              const SizedBox(height: 20),
              if (attachment != null && fileName != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    onPressed: () {
                      String fileUrl = homework['Attachment'].toString();

                      if (!fileUrl.startsWith('http')) {
                        fileUrl =
                            'https://s3.ap-south-1.amazonaws.com/'
                            'school.edusathi.in/homeworks/$fileUrl';
                      }

                      debugPrint("📎 TEACHER HW DETAIL DOWNLOAD URL: $fileUrl");

                      downloadFile(context, fileUrl, fileName);
                    },

                    icon: const Icon(Icons.download, color: Colors.white),
                    label: const Text(
                      "Download Attachment",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
