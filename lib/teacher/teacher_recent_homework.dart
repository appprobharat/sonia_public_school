import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sonia_public_school/api_service.dart';
import 'package:sonia_public_school/teacher/teacher_homework_detail_page.dart';
import 'package:sonia_public_school/teacher/teacher_homework_page.dart';


class TeacherRecentHomeworks extends StatelessWidget {
  final List<Map<String, dynamic>> homeworks;

  const TeacherRecentHomeworks({super.key, required this.homeworks});

  @override
  Widget build(BuildContext context) {
    final limitedHomeworks = homeworks.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📝 Recent Homeworks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TeacherHomeworkPage(),
                    ),
                  );
                },
                child: const Text("View All"),
              ),
            ],
          ),
          limitedHomeworks.isEmpty
              ? const Text("No homeworks available.")
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: limitedHomeworks.length,
                  itemBuilder: (context, index) {
                    final hw = limitedHomeworks[index];

                    return ListTile(
                      leading: const Icon(Icons.book, color: AppColors.primary),
                      title: Text(hw['HomeworkTitle'] ?? ''),
                      subtitle: Text(
                        "Submission: ${formatDate(hw['SubmissionDate'])}",
                      ),
                      trailing: hw['Attachment'] != null
                          ? IconButton(
                              icon: const Icon(
                                Icons.download,
                                color: AppColors.primary,
                              ),
                              onPressed: () {
                                final attachment = hw['Attachment'];

                                if (attachment == null ||
                                    attachment.toString().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Attachment not available"),
                                    ),
                                  );
                                  return;
                                }

                                // ✅ Teacher homework FINAL S3 URL
                                final String fileUrl =
                                    attachment.toString().startsWith('http')
                                    ? attachment.toString()
                                    : 'https://s3.ap-south-1.amazonaws.com/'
                                          'school.edusathi.in/homeworks/$attachment';

                                debugPrint(
                                  "📎 TEACHER HW DOWNLOAD URL: $fileUrl",
                                );

                                _downloadFile(context, fileUrl);
                              },
                            )
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TeacherHomeworkDetailPage(homework: hw),
                          ),
                        );
                      },
                    );
                  },
                ),
        ],
      ),
    );
  }

  // ---------------- SAFE FILE DOWNLOAD ----------------
  Future<void> _downloadFile(BuildContext context, String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Attachment not available")));
      return;
    }

    try {
      debugPrint("⬇️ Downloading: $url");

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw Exception("Failed to download file");
      }

      final fileName = Uri.parse(url).pathSegments.last;

      // ================= ANDROID =================
      if (Platform.isAndroid) {
        // ✅ Real user-visible Downloads folder
        final downloadsDir = Directory('/storage/emulated/0/Download');
        final filePath = '${downloadsDir.path}/$fileName';

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes, flush: true);

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("File saved to Downloads folder")),
        );
      }

      // ================= iOS =================
      if (Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/$fileName';

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes, flush: true);

        if (!context.mounted) return;
        await OpenFile.open(filePath); // Files app
      }
    } catch (e) {
      debugPrint("❌ Teacher HW download error: $e");
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Download failed")));
    }
  }

  // ---------------- DATE FORMAT ----------------
  String formatDate(String? date) {
    if (date == null || date.isEmpty) return "";
    try {
      final parsedDate = DateTime.parse(date);
      return "${parsedDate.day.toString().padLeft(2, '0')}-"
          "${parsedDate.month.toString().padLeft(2, '0')}-"
          "${parsedDate.year}";
    } catch (_) {
      return date;
    }
  }
}
