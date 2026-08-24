import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:sonia_public_school/api_service.dart';
import 'package:sonia_public_school/homework/teacher_add_homework_page.dart';
import 'teacher_homework_detail_page.dart';

class TeacherHomeworkPage extends StatefulWidget {
  const TeacherHomeworkPage({super.key});

  @override
  State<TeacherHomeworkPage> createState() => _TeacherHomeworkPageState();
}

class _TeacherHomeworkPageState extends State<TeacherHomeworkPage> {
  List<Map<String, dynamic>> homeworks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchHomeworks();
  }

  // ---------------- FETCH HOMEWORKS ----------------
  Future<void> fetchHomeworks() async {
    setState(() => isLoading = true);

    try {
      final response = await ApiService.post(context, '/teacher/homework');

      // 🔐 token expired → AuthHelper already logout kara dega
      if (response == null || !mounted) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      debugPrint("🟢 HOMEWORK STATUS: ${response.statusCode}");
      debugPrint("📦 HOMEWORK BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        setState(() {
          if (decoded is List) {
            homeworks = List<Map<String, dynamic>>.from(decoded);
          } else {
            homeworks = [];
          }
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load homeworks (${response.statusCode})"),
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ fetchHomeworks error: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error loading homework")));
    }
  }

  // ---------------- DATE FORMAT ----------------
  String formatDate(String? date) {
    if (date == null || date.isEmpty) return '';
    try {
      return DateFormat('dd-MM-yyyy').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }

  // ---------------- FILE DOWNLOAD (IOS + ANDROID SAFE) ----------------
  Future<void> downloadFile(BuildContext context, String attachmentPath) async {
    try {
      final String fileUrl = attachmentPath.toString();

      final response = await http
          .get(Uri.parse(fileUrl))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw Exception("Download failed");
      }

      final String fileName = Uri.parse(fileUrl).pathSegments.last;

      // ================= ANDROID =================
      if (Platform.isAndroid) {
        // ✅ REAL Downloads folder (user visible)
        final Directory downloadsDir = Directory(
          '/storage/emulated/0/Download',
        );

        final String filePath = '${downloadsDir.path}/$fileName';
        final File file = File(filePath);

        await file.writeAsBytes(response.bodyBytes, flush: true);
        await OpenFile.open(file.path);
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
        await OpenFile.open(file.path);
        if (!context.mounted) return;
        await OpenFile.open(filePath); // Files app
      }
    } catch (e) {
      debugPrint("❌ Download error: $e");
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Download failed")));
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Homeworks'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : homeworks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 70,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "No Homework Found",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Tap + to create a new homework.",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : homeworks.isEmpty
          ? const Center(child: Text('No homework found.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: homeworks.length,
              itemBuilder: (context, index) {
                final hw = homeworks[index];
                final attachmentUrl = hw['Attachment'];

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeacherHomeworkDetailPage(homework: hw),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Homework Icon
                        Container(
                          height: 46,
                          width: 46,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hw['HomeworkTitle'] ?? "Homework",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _dateChip(
                                    Colors.blue,
                                    Icons.calendar_today,
                                    formatDate(hw['WorkDate']),
                                  ),

                                  _dateChip(
                                    Colors.orange,
                                    Icons.schedule,
                                    formatDate(hw['SubmissionDate']),
                                  ),
                                ],
                              ),

                              if ((hw['Remark'] ?? "")
                                  .toString()
                                  .isNotEmpty) ...[
                                const SizedBox(height: 8),

                                Text(
                                  hw['Remark'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        Column(
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TeacherAddHomeworkPage(
                                      homeworkToEdit: hw,
                                    ),
                                  ),
                                );

                                if (result == true) {
                                  fetchHomeworks();
                                }
                              },
                              child: Container(
                                height: 32,
                                width: 32,
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.orange,
                                  size: 17,
                                ),
                              ),
                            ),

                            if ((attachmentUrl ?? "")
                                .toString()
                                .isNotEmpty) ...[
                              const SizedBox(height: 8),

                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  downloadFile(context, attachmentUrl);
                                },
                                child: Container(
                                  height: 32,
                                  width: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.download_rounded,
                                    color: Colors.green,
                                    size: 17,
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 8),

                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add Homework",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TeacherAddHomeworkPage()),
          );

          if (result == true) {
            fetchHomeworks();
          }
        },
      ),
    );
  }

  Widget _dateChip(Color color, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
