import 'package:sonia_public_school/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentHolidayHomeworkDetailPage extends StatelessWidget {
  final Map<String, dynamic> homeworkData;

  const StudentHolidayHomeworkDetailPage({
    super.key,
    required this.homeworkData,
  });

  String formatDate(String? date) {
    if (date == null || date.isEmpty) return "-";

    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(date));
    } catch (e) {
      return date;
    }
  }

  Future<void> previewFile(String url) async {
    try {
      final uri = Uri.parse(url);

      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("PREVIEW ERROR => $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = homeworkData["Title"]?.toString() ?? "";
    final type = homeworkData["Type"]?.toString() ?? "";
    final date = homeworkData["Date"]?.toString() ?? "";
    final description = homeworkData["Description"]?.toString() ?? "";

    final attachment = homeworkData["Attachment"]?.toString() ?? "";

    final hasAttachment = attachment.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      appBar: AppBar(
        title: const Text(
          "Homework Details",
          style: TextStyle(color: Colors.white),
        ),

        backgroundColor: AppColors.primary,

        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),

        child: Container(
          width: double.infinity,

          padding: const EdgeInsets.all(16),

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.circular(18),

            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),

                blurRadius: 8,

                offset: const Offset(0, 3),
              ),
            ],
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              /// TOP ROW
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Expanded(
                    child: Text(
                      title,

                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),

                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.10),

                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: Text(
                      type,

                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              /// DATE
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 18,
                    color: Colors.grey.shade700,
                  ),

                  const SizedBox(width: 6),

                  Text(
                    formatDate(date),

                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              /// DESCRIPTION TITLE
              const Text(
                "Description",

                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 10),

              /// DESCRIPTION
              Text(
                description,

                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.grey.shade800,
                ),
              ),

              /// ATTACHMENT BUTTON
              if (hasAttachment) ...[
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 46,

                  child: ElevatedButton.icon(
                    onPressed: () {
                      previewFile(attachment);
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,

                      elevation: 0,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

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
              ],
            ],
          ),
        ),
      ),
    );
  }
}
