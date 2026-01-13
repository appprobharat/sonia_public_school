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
      final response = await ApiService.post(
        context,
        '/teacher/homework',
      );

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
    final String fileUrl = attachmentPath.startsWith('http')
        ? attachmentPath
        : 'https://s3.ap-south-1.amazonaws.com/'
            'school.edusathi.in/homeworks/$attachmentPath';

    debugPrint("⬇️ Download URL: $fileUrl");

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
      final Directory downloadsDir =
          Directory('/storage/emulated/0/Download');

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
    debugPrint("❌ Download error: $e");
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Download failed")),
    );
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
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary),)
          : homeworks.isEmpty
          ? const Center(child: Text('No homework found.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: homeworks.length,
              itemBuilder: (context, index) {
                final hw = homeworks[index];
                final attachmentUrl = hw['Attachment'];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeacherHomeworkDetailPage(homework: hw),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hw['HomeworkTitle'] ?? 'Untitled',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "📅 ${formatDate(hw['WorkDate'])}",
                                style: const TextStyle(fontSize: 13),
                              ),
                              Text(
                                "Submission: ${formatDate(hw['SubmissionDate'])}",
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if ((hw['Remark'] ?? '').isNotEmpty)
                            Text(
                              "📝 ${(hw['Remark'] as String).length > 150 ? hw['Remark'].substring(0, 150) + '...' : hw['Remark']}",
                              style: const TextStyle(fontSize: 13),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: AppColors.primary,
                                ),
                                onPressed: () async {
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
                              ),
                              if (attachmentUrl != null)
                                IconButton(
                                  icon: const Icon(
                                    Icons.download_rounded,
                                    color: AppColors.primary,
                                  ),
                                  onPressed: () {
                                    downloadFile(context, attachmentUrl);
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
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
}
