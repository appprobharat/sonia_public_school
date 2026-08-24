import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class HolidayHomeworkDetailPage extends StatelessWidget {
  final Map<String, dynamic> homeworkData;

  const HolidayHomeworkDetailPage({super.key, required this.homeworkData});

  Future<void> openAttachment(String url) async {
    try {
      final uri = Uri.parse(url);

      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("OPEN FILE ERROR => $e");
    }
  }

  String formatDate(String? date) {
    if (date == null || date.isEmpty) return "-";

    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(date));
    } catch (e) {
      return date;
    }
  }

  Color getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case "summer":
        return Colors.orange;

      case "winter":
        return Colors.blue;

      case "festival":
        return Colors.purple;

      case "national":
        return Colors.green;

      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = homeworkData['Title']?.toString() ?? '';
    final description = homeworkData['Description']?.toString() ?? '';
    final className = homeworkData['Class']?.toString() ?? '';
    final type = homeworkData['Type']?.toString() ?? '';
    final date = homeworkData['Date']?.toString() ?? '';
    final attachment = homeworkData['Attachment']?.toString() ?? '';

    final hasAttachment = attachment.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      appBar: AppBar(
        title: const Text(
          "Homework Details",
          style: TextStyle(color: Colors.white),
        ),

        backgroundColor: Colors.blue,

        iconTheme: const IconThemeData(color: Colors.white),
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
              /// TYPE
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),

                decoration: BoxDecoration(
                  color: getTypeColor(type).withOpacity(0.12),

                  borderRadius: BorderRadius.circular(30),
                ),

                child: Text(
                  type,

                  style: TextStyle(
                    color: getTypeColor(type),

                    fontSize: 12,

                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              /// TITLE
              Text(
                title,

                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              /// CLASS + DATE
              Row(
                children: [
                  Icon(
                    Icons.school_rounded,
                    size: 18,
                    color: Colors.grey.shade700,
                  ),

                  const SizedBox(width: 6),

                  Text(
                    className,

                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const Spacer(),

                  Icon(
                    Icons.calendar_month_rounded,
                    size: 18,
                    color: Colors.grey.shade700,
                  ),

                  const SizedBox(width: 6),

                  Text(
                    formatDate(date),

                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// DESCRIPTION
              const Text(
                "Description",

                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 10),

              Text(
                description,

                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),

     
              if (hasAttachment) ...[
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,

                  height: 48,

                  child: ElevatedButton.icon(
                    onPressed: () {
                      openAttachment(attachment);
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,

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
