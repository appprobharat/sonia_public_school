import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';

class SubjectsPage extends StatefulWidget {
  @override
  _SubjectsPageState createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  List<dynamic> subjects = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSubjects();
  }

  Future<void> fetchSubjects() async {
    try {
      final response = await ApiService.post(context, "/student/subject");

      if (!mounted) return;

      if (response == null) {
        setState(() => isLoading = false);
        return;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          if (data is List) {
            subjects = data;
          } else if (data is Map && data.containsKey('data')) {
            subjects = data['data'] ?? [];
          } else {
            subjects = [];
          }
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load subjects')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : subjects.isEmpty
          ? const Center(child: Text("No subjects found."))
          : Column(
              children: [
                _summaryCard(),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                    itemCount: subjects.length,
                    itemBuilder: (_, index) =>
                        _subjectCard(subjects[index], index),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _summaryCard() {
    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: AppColors.appBarGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.menu_book_rounded, color: Colors.white),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Total Subjects",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),

                Text(
                  "${subjects.length}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Academic",
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subjectCard(dynamic subject, int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
    ];

    final color = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.book_rounded, color: color),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject['Subject'] ?? "",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  "Subject ${index + 1}",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "#${index + 1}",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
