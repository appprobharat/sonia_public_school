import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';


class ResultCardPage extends StatefulWidget {
  const ResultCardPage({super.key});

  @override
  State<ResultCardPage> createState() => _ResultCardPageState();
}

class _ResultCardPageState extends State<ResultCardPage> {
  List<dynamic> exams = [];
  String? selectedExamId;

  List<dynamic> studentResults = [];
  List<dynamic> filteredResults = [];

  bool isLoading = false;
  bool showSearchBar = false;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchExams();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ---------------- FETCH EXAMS ----------------
  Future<void> fetchExams() async {
    try {
      final response = await ApiService.post(
        context,
        "/get_exam",
      );

      if (response == null) return;
      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          setState(() {
            exams = decoded;
          });
        }
      }
    } catch (_) {}
  }

  // ---------------- FETCH RESULTS ----------------
  Future<void> fetchResults() async {
    if (selectedExamId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an exam')));
      return;
    }

    setState(() {
      isLoading = true;
      showSearchBar = false;
    });

    try {
      final response = await ApiService.post(
        context,
        '/teacher/result',
        body: {'ExamId': selectedExamId},
      );

      if (response == null) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          if (data is List) {
            studentResults = data;
            filteredResults = data;
            showSearchBar = true;
          } else {
            studentResults = [];
            filteredResults = [];
            showSearchBar = false;
          }
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        studentResults = [];
        filteredResults = [];
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ---------------- UTIL ----------------
  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map(
          (w) => w.isNotEmpty
              ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v.toDouble();
    if (v is double) return v;
    return double.tryParse(v.toString()) ?? 0;
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Result"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ---------------- FILTER CARD ----------------
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedExamId,
                      decoration: const InputDecoration(
                        labelText: 'Select Exam',
                        border: OutlineInputBorder(),
                      ),
                      items: exams
                          .map<DropdownMenuItem<String>>(
                            (e) => DropdownMenuItem(
                              value: e['ExamId'].toString(),
                              child: Text(e['Exam']),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => selectedExamId = v),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: fetchResults,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text(
                          'Search',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ---------------- SEARCH ----------------
            if (showSearchBar)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by Student name...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (q) {
                    final query = q.toLowerCase();
                    setState(() {
                      filteredResults = studentResults.where((s) {
                        final name = (s['StudentName'] ?? '')
                            .toString()
                            .toLowerCase();
                        final roll = (s['RollNo'] ?? '').toString();
                        return name.contains(query) || roll.contains(query);
                      }).toList();
                    });
                  },
                ),
              ),

            // ---------------- RESULTS ----------------
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary),)
                  : filteredResults.isEmpty
                  ? const Center(child: Text('No results found.'))
                  : ListView.builder(
                      itemCount: filteredResults.length,
                      itemBuilder: (context, index) {
                        final student = filteredResults[index];

                        // 🔐 SAFE MARKS EXTRACTION
                        final marks = student['Marks'] is List
                            ? student['Marks'] as List
                            : <dynamic>[];

                        int totalMarks = 0;
                        double obtainedMarks = 0;

                        for (var m in marks) {
                          totalMarks += _toInt(m['TotalMark']);
                          if (m['IsPresent'] == 'Yes') {
                            obtainedMarks += _toDouble(m['GetMark']);
                          }
                        }

                        final percentage = totalMarks > 0
                            ? (obtainedMarks / totalMarks) * 100
                            : 0.0;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "R_No: ${student['RollNo']}  ||  ${student['StudentName']}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "F Name: ${_toTitleCase(student['FatherName'].toString())}",
                                ),
                                const Divider(),
                                if (marks.isEmpty) ...[
                                  const Text(
                                    "Marks not available",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ] else ...[
                                  ...marks.map(
                                    (m) => Row(
                                      children: [
                                        Expanded(
                                          flex: 5,
                                          child: Text(m['Subject']),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            m['TotalMark'].toString(),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            m['IsPresent'] == 'No'
                                                ? 'Ab'
                                                : m['GetMark'].toString(),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: m['IsPresent'] == 'No'
                                                  ? Colors.red
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Total: $obtainedMarks / $totalMarks",
                                      ),
                                      Text(
                                        "Percentage: ${percentage.toStringAsFixed(2)}%",
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
