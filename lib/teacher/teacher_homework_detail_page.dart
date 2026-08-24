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
        await OpenFile.open(filePath);

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
        await OpenFile.open(filePath);
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
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Homework Details",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      homework['HomeworkTitle'] ?? "Homework",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// Dates
            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    "Assigned",
                    formatDate(homework['WorkDate']),
                    Icons.calendar_today,
                    Colors.blue,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _infoCard(
                    "Submission",
                    formatDate(homework['SubmissionDate']),
                    Icons.schedule,
                    Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// Remark
            _sectionCard(
              icon: Icons.edit_note,
              title: "Teacher Remark",
              color: Colors.deepPurple,
              child: Text(
                homework['Remark'] ?? "No remarks provided",
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),

            if (attachment != null && fileName != null) ...[
              const SizedBox(height: 16),

              _sectionCard(
                icon: Icons.attach_file,
                title: "Attachment",
                color: Colors.green,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      downloadFile(context, attachment.toString(), fileName);
                    },
                    icon: const Icon(
                      Icons.download_rounded,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "Download Attachment",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          child,
        ],
      ),
    );
  }
}
