import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:sonia_public_school/api_service.dart';
import 'package:sonia_public_school/homework/homework_detail_page.dart';
import 'package:sonia_public_school/homework/homework_page.dart';

bool _isDownloading = false; // 🔒 download lock (logic only)

// ====================================================
// 📅 DATE FORMAT (SAFE)
// ====================================================
String formatDate(String? inputDate) {
  if (inputDate == null || inputDate.isEmpty) return '';
  try {
    return DateFormat('dd-MM-yyyy').format(DateTime.parse(inputDate));
  } catch (_) {
    return inputDate;
  }
}

// ====================================================
// 📥 SAFE FILE DOWNLOAD (iOS + Android)
// ====================================================
Future<void> downloadFile(BuildContext context, String filePath) async {
  if (_isDownloading) return;
  _isDownloading = true;

  // ✅ URL now comes from ApiService
  final fullUrl = filePath.startsWith('http')
      ? filePath
      : ApiService.homeworkAttachment(filePath);

  try {
    final fileName = fullUrl.split('/').last;
    final dio = Dio();
    late String savePath;

    // ================= ANDROID =================
    if (Platform.isAndroid) {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      savePath = '${downloadsDir.path}/$fileName';

      await dio.download(fullUrl, savePath);

      // ✅ Preview open
      await OpenFile.open(savePath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("📥 Downloaded & Preview opened")),
        );
      }
    }

    // ================= iOS =================
    if (Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      savePath = '${dir.path}/$fileName';

      await dio.download(fullUrl, savePath);

      // ✅ Preview open
      await OpenFile.open(savePath);
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ Download failed")));
    }
  } finally {
    _isDownloading = false;
  }
}

// ====================================================
// 📝 RECENT HOMEWORKS WIDGET (UI UNCHANGED)
// ====================================================
Widget buildRecentHomeworks(
  BuildContext context,
  List<Map<String, dynamic>> homeworks,
) {
  final limitedHomeworks = homeworks.take(3).toList();

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
                  MaterialPageRoute(builder: (_) => const HomeworkPage()),
                );
              },
              child: const Text(
                "View All",
                style: TextStyle(color: AppColors.primary),
              ),
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HomeworkDetailPage(homework: hw),
                        ),
                      );
                    },
                    leading: const Icon(Icons.book, color: AppColors.primary),
                    title: Text(
                      hw['HomeworkTitle'] ?? '',
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      'Submission: ${formatDate(hw['SubmissionDate'])}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: hw['Attachment'] != null
                        ? IconButton(
                            icon: const Icon(
                              Icons.download,
                              color: AppColors.primary,
                            ),
                            onPressed: () {
                              downloadFile(context, hw['Attachment']);
                            },
                          )
                        : const SizedBox.shrink(),
                  );
                },
              ),
      ],
    ),
  );
}
