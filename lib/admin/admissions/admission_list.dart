import 'dart:convert';

import 'package:sonia_public_school/admin/admissions/stu_model.dart';
import 'package:flutter/material.dart';
import 'package:sonia_public_school/admin/admissions/quick_admission.dart';
import 'package:sonia_public_school/api_service.dart';

class AdmissionListPage extends StatefulWidget {
  const AdmissionListPage({super.key});

  @override
  State<AdmissionListPage> createState() => _AdmissionListPageState();
}

class _AdmissionListPageState extends State<AdmissionListPage> {
  bool isLoading = true;

  List<StudentModel> students = [];
  List<StudentModel> filteredStudents = [];

  final TextEditingController searchCtrl = TextEditingController();
  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  void _onSearch(String query) {
    if (query.isEmpty) {
      filteredStudents = students;
      FocusScope.of(context).unfocus();
    } else {
      final q = query.toLowerCase();

      filteredStudents = students.where((s) {
        return s.studentName.toLowerCase().contains(q) ||
            s.fatherName.toLowerCase().contains(q) ||
            s.ledgerNo.toLowerCase().contains(q) ||
            s.contactNo.toLowerCase().contains(q);
      }).toList();
    }

    setState(() {});
  }

  Future<void> fetchStudents() async {
    final response = await ApiService.post(
      context,
      "/admin/student/list",
      body: {},
    );

    if (response != null && response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      students = data.map((e) => StudentModel.fromJson(e)).toList();
      filteredStudents = students;
    }

    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),
      appBar: AppBar(
        leading: const BackButton(),
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text("Admissions"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuickAdmissionPage()),
              );

              if (result == true) {
                fetchStudents();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            const SizedBox(height: 8),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredStudents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.school_outlined,
                            size: 42,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "No Students Found",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: filteredStudents.length,
                      itemBuilder: (context, index) {
                        final s = filteredStudents[index];
                        return StudentCard(
                          id: s.id,
                          name: s.studentName,
                          ledger: s.ledgerNo,
                          father: s.fatherName,
                          classText: s.className,
                          section: s.section,
                          mobile: s.contactNo,
                          address: s.address,
                          color: AppColors.primary,
                          photo: s.photo,
                          onEdit: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    QuickAdmissionPage(studentId: s.id),
                              ),
                            );

                            if (result == true) {
                              fetchStudents();
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: searchCtrl,
                      onChanged: _onSearch,
                      decoration: const InputDecoration(
                        hintText: 'Search student...',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StudentCard extends StatelessWidget {
  final int id;
  final String name;
  final String ledger;
  final String father;
  final String classText;
  final String section;
  final String mobile;
  final String address;
  final Color color;
  final String photo;
  final VoidCallback onEdit;

  const StudentCard({
    super.key,
    required this.id,
    required this.name,
    required this.ledger,
    required this.father,
    required this.classText,
    required this.section,
    required this.mobile,
    required this.address,
    required this.color,
    required this.photo,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: photo.isNotEmpty
                  ? Image.network(
                      photo,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                    )
                  : const Icon(Icons.person, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        InkWell(
                          onTap: onEdit,
                          child: const Icon(
                            Icons.edit,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text("($father)", style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.credit_card,
                      size: 13,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(ledger, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 25),
                    const Icon(
                      Icons.school,
                      size: 13,
                      color: Color(0xff4DA3FF),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Class $classText ',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text('($section)', style: const TextStyle(fontSize: 11)),
                  ],
                ),
                _row(Icons.call, 'Mobile No: $mobile'),
                _row(Icons.home, address),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.green),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
