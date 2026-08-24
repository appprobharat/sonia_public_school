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

  Future<void> downloadFile(String filePath) async {
    if (isDownloading) return;

    setState(() => isDownloading = true);

    try {
      final fullUrl = filePath.toString();

      final fileName = fullUrl.split('/').last;

      final response = await http.get(Uri.parse(fullUrl));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw Exception("Download failed");
      }

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

  @override
  Widget build(BuildContext context) {
    final homework = widget.homework;
    final attachment = homework['Attachment'];

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          "Homework Details",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ///================ Header Card ===================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(.30),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          homework['HomeworkTitle'] ?? "Homework",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 19,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "Latest Assignment",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            ///============== Date Cards =================
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    title: "Assigned",
                    value: formatDate(homework['WorkDate']),
                    icon: Icons.calendar_today_rounded,
                    color: Colors.blue,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _buildInfoCard(
                    title: "Submission",
                    value: formatDate(homework['SubmissionDate']),
                    icon: Icons.alarm,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            ///============== Remark ===================
            if ((homework['Remark'] ?? "").toString().trim().isNotEmpty)
              _buildSectionCard(
                icon: Icons.edit_note_rounded,
                title: "Teacher Remark",
                color: Colors.deepPurple,
                child: Text(
                  homework['Remark'],
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),
              ),

            if ((homework['Remark'] ?? "").toString().trim().isNotEmpty)
              const SizedBox(height: 18),

            ///============== Attachment ===================
            if (attachment != null)
              _buildSectionCard(
                icon: Icons.attach_file_rounded,
                title: "Attachment",
                color: Colors.green,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(.06),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 42,
                            width: 42,
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.picture_as_pdf,
                              color: Colors.green,
                            ),
                          ),

                          const SizedBox(width: 12),

                          const Expanded(
                            child: Text(
                              "Homework Attachment",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.download,
                              color: Colors.green,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: _buildDownloadButton(attachment),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
  //====================== Info Card ======================

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 17),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  //====================== Section Card ======================

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(.10),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),

              const SizedBox(width: 10),

              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          child,
        ],
      ),
    );
  }

  //====================== Download Button ======================

  Widget _buildDownloadButton(String attachment) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: isDownloading ? null : () => downloadFile(attachment),
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
        label: Text(
          isDownloading ? "Downloading..." : "Download Attachment",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
