import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sonia_public_school/api_service.dart';

class HomeworkDetailPage extends StatefulWidget {
  final Map<String, dynamic> homework;

  const HomeworkDetailPage({super.key, required this.homework});

  @override
  State<HomeworkDetailPage> createState() => _HomeworkDetailPageState();
}

class _HomeworkDetailPageState extends State<HomeworkDetailPage> {
  bool isDownloading = false;

  String formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      return DateFormat('dd-MM-yyyy').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }

  // ====================================================
  // 📥 SAFE FILE DOWNLOAD (iOS + Android)
  // ====================================================
  Future<void> downloadFile(String filePath) async {
    if (isDownloading) return;

    setState(() => isDownloading = true);

    try {
      // ✅ URL CENTRALIZED (no hardcode)
      final fullUrl = filePath.startsWith('http')
          ? filePath
          : ApiService.homeworkAttachment(filePath);

      final fileName = fullUrl.split('/').last;

      final response = await http.get(Uri.parse(fullUrl));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw Exception("Download failed");
      }

      // ================= ANDROID =================
      if (Platform.isAndroid) {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        final file = File('${downloadsDir.path}/$fileName');

        await file.writeAsBytes(response.bodyBytes, flush: true);

        // ✅ PREVIEW OPEN
        await OpenFile.open(file.path);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("📥 Downloaded & preview opened")),
        );
      }

      // ================= iOS =================
      if (Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');

        await file.writeAsBytes(response.bodyBytes, flush: true);

        // ✅ PREVIEW OPEN
        await OpenFile.open(file.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ Download error")));
    } finally {
      if (!mounted) return;
      setState(() => isDownloading = false);
    }
  }

  // ====================================================
  // 🧱 UI (UNCHANGED)
  // ====================================================
  @override
  Widget build(BuildContext context) {
    final attachment = widget.homework['Attachment'];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Homework Detail",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.homework['HomeworkTitle'] ?? 'Untitled',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Assignment: ${formatDate(widget.homework['WorkDate'])}"),
                Text(
                  "Submission: ${formatDate(widget.homework['SubmissionDate'])}",
                ),
              ],
            ),

            const SizedBox(height: 20),

            if ((widget.homework['Remark'] ?? '').toString().isNotEmpty) ...[
              const Text(
                "📝 Remark:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(widget.homework['Remark']),
              const SizedBox(height: 20),
            ],

            if (attachment != null)
              Center(
                child: ElevatedButton.icon(
                  onPressed: isDownloading
                      ? null
                      : () => downloadFile(attachment),
                  icon: isDownloading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download_rounded, color: Colors.white),
                  label: const Text(
                    "Download Attachment",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
