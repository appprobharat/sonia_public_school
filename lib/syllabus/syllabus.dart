import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import 'package:sonia_public_school/api_service.dart';

class SyllabusPage extends StatefulWidget {
  const SyllabusPage({super.key});

  @override
  State<SyllabusPage> createState() => _SyllabusPageState();
}

class _SyllabusPageState extends State<SyllabusPage> {
  List<dynamic> exams = [];
  Map<String, dynamic>? selectedExam;
  List<dynamic> syllabusContent = [];

  bool isLoadingExams = true;
  bool isLoadingSyllabus = false;

  @override
  void initState() {
    super.initState();
    fetchExams();
  }

  // ---------------- FETCH EXAMS ----------------
  Future<void> fetchExams() async {
    if (!mounted) return;

    setState(() => isLoadingExams = true);

    try {
      final response = await ApiService.post(context, '/get_exam');

      // 🔐 token expired → auto logout already handled
      if (response == null) return;

      debugPrint("📦 RAW EXAM BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        // ✅ API RETURNS PURE LIST
        final List<dynamic> examList = decoded is List ? decoded : [];

        if (!mounted) return;

        setState(() {
          exams = examList;
          isLoadingExams = false;
        });

        debugPrint("📦 Exams length: ${exams.length}");
        debugPrint("📦 Exams data: $exams");

        // ✅ AUTO LOAD FIRST EXAM SYLLABUS
        if (exams.isNotEmpty && exams.first['ExamId'] != null) {
          selectedExam = exams.first;
          fetchSyllabusForExam(selectedExam!['ExamId'].toString());
        }
      } else {
        _failExamLoad("Failed to load exams");
      }
    } catch (e) {
      debugPrint("❌ fetchExams exception: $e");
      _failExamLoad("Error loading exams");
    }
  }

  void _failExamLoad(String msg) {
    if (!mounted) return;
    setState(() => isLoadingExams = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------- FETCH SYLLABUS ----------------
  Future<void> fetchSyllabusForExam(String examId) async {
    if (!mounted) return;
    setState(() => isLoadingSyllabus = true);

    try {
      final response = await ApiService.post(
        context,
        "/syllabus",
        body: {'ExamId': examId},
      );
      debugPrint("📤 Sending ExamId: $examId");
      debugPrint("📥 STATUS CODE: ${response?.statusCode}");
      debugPrint("📥 BODY: ${response?.body}");
      if (response == null) {
        if (!mounted) return;
        setState(() => isLoadingSyllabus = false);
        return;
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (!mounted) return;
        setState(() {
          syllabusContent = decoded is List ? decoded : [];
          isLoadingSyllabus = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          syllabusContent = [];
          isLoadingSyllabus = false;
        });
        _showSnackBar('Failed to load syllabus.');
      }
    } catch (e) {
      debugPrint("❌ fetchSyllabus error: $e");
      if (!mounted) return;
      setState(() {
        syllabusContent = [];
        isLoadingSyllabus = false;
      });
      _showSnackBar('Error loading syllabus');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------------- UI (UNCHANGED) ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      appBar: AppBar(
        title: const Text("Syllabus", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(.85)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.menu_book_rounded, color: Colors.white),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Exam Syllabus",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "Select an exam to view syllabus",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildExamSelector(),
          const SizedBox(height: 10),
          _buildSyllabusList(),
        ],
      ),
    );
  }

  Widget _buildExamSelector() {
    if (isLoadingExams) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (exams.isEmpty) {
      return const Center(child: Text("No exams available."));
    }

    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: exams.length,
        itemBuilder: (context, index) {
          final exam = exams[index];
          final isSelected =
              selectedExam != null && selectedExam!['ExamId'] == exam['ExamId'];

          return GestureDetector(
            onTap: () {
              setState(() => selectedExam = exam);
              if (exam['ExamId'] != null) {
                fetchSyllabusForExam(exam['ExamId'].toString());
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.primary.withOpacity(.25)),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: AppColors.primary.withOpacity(.25),
                      blurRadius: 8,
                    ),
                ],
              ),

              child: Row(
                children: [
                  if (isSelected) ...[
                    const Icon(Icons.check, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    exam['Exam']?.toString() ?? '',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSyllabusList() {
    if (isLoadingSyllabus) {
      return const Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 15),
              Text(
                "Loading syllabus...",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    if (syllabusContent.isEmpty) {
      return const Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_book_outlined, size: 70, color: Colors.grey),
              const SizedBox(height: 14),
              Text(
                "No Syllabus Available",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "Select another exam.",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: syllabusContent.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final item = syllabusContent[index];
          final subject = item['Subject']?.toString() ?? '';
          final content = item['Content']?.toString() ?? '';
          final cleanContent = content
              .replaceAll('<figure class="table">', '')
              .replaceAll('<figure>', '')
              .replaceAll('</figure>', '')
              .replaceAll('&nbsp;', ' ')
              .replaceAll(r'\u2019', "'")
              .replaceAll('\n', '');
          print("👉 CLEAN CONTENT: $cleanContent");

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width,
                      ),
                      child: Html(
                        data: cleanContent,
                        extensions: [TableHtmlExtension()],
                        style: {
                          "table": Style(
                            border: Border.all(color: Colors.black),
                          ),
                          "td": Style(
                            padding: HtmlPaddings.all(8),
                            border: Border.all(color: Colors.grey),
                          ),
                          "th": Style(
                            padding: HtmlPaddings.all(8),
                            backgroundColor: Colors.grey.shade300,
                          ),
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
