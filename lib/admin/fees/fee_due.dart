import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';

class FeeDuePage extends StatefulWidget {
  const FeeDuePage({super.key});

  @override
  State<FeeDuePage> createState() => _FeeDuePageState();
}

class _FeeDuePageState extends State<FeeDuePage> {
  List<Map<String, dynamic>> classList = [];
  List<Map<String, dynamic>> sectionList = [];
  List<dynamic> studentList = [];
  String? selectedClass;
  String? selectedSection;
  bool loadingClass = false;
  bool loadingSection = false;
  bool isLoading = false;
  int? selectedSectionId;
  @override
  void initState() {
    super.initState();
    fetchClasses();
    fetchFeeDue();
  }

  Future<void> fetchClasses() async {
    setState(() => loadingClass = true);

    final res = await ApiService.post(context, "/get_class");

    if (res != null && res.statusCode == 200) {
      classList = List<Map<String, dynamic>>.from(
        (jsonDecode(res.body) as List),
      );
    }

    setState(() => loadingClass = false);
  }

  Future<void> fetchSections(int classId) async {
    setState(() {
      loadingSection = true;
      sectionList.clear();
      selectedSection = null;
      selectedSectionId = null;
    });

    final res = await ApiService.post(
      context,
      "/get_section",
      body: {"ClassId": classId},
    );

    if (res != null && res.statusCode == 200) {
      sectionList = List<Map<String, dynamic>>.from(
        (jsonDecode(res.body) as List),
      );

      if (sectionList.isNotEmpty) {
        selectedSectionId = sectionList.first['id'];
        selectedSection = sectionList.first['SectionName'];
      }
    }

    setState(() => loadingSection = false);
  }

  Future<void> fetchFeeDue() async {
    setState(() => isLoading = true);

    final response = await ApiService.post(
      context,
      "/admin/student/due",
      body: {"Class": selectedClass ?? "", "Section": selectedSection ?? ""},
    );

    if (response != null && response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);

      setState(() {
        studentList = decoded.where((student) {
          final dueValue = student['Due'].toString();
          return dueValue != "0";
        }).toList();

        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F6F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: BackButton(),
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          'Student Fees Dues',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          /// FILTER SECTION
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _iconDropdownField(
                    icon: Icons.class_,
                    hint: "Select Class",
                    value: selectedClass,
                    items: classList,
                    labelKey: "Class",
                    onChanged: (value) {
                      setState(() {
                        selectedClass = value;
                        selectedSection = null;
                        sectionList = [];
                      });

                      fetchSections(int.parse(value));
                      fetchFeeDue();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _iconDropdownField(
                    icon: Icons.group,
                    hint: "Select Section",
                    value: selectedSection,
                    items: sectionList,
                    labelKey: "SectionName",

                    onChanged: (value) {
                      setState(() {
                        selectedSection = value;
                      });

                      fetchFeeDue();
                    },
                  ),
                ),
              ],
            ),
          ),

          /// LIST
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : studentList.isEmpty
                ? const Center(
                    child: Text(
                      "No Data Found",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: studentList.length,
                    itemBuilder: (context, index) {
                      final student = studentList[index];

                      return FeeCard(
                        name: student['StudentName'] ?? '',
                        father: student['FatherName'] ?? '',
                        classSec: "${student['Class']} / ${student['Section']}",
                        mobile: student['ContactNo'].toString(),
                        due: student['Due'].toString(),
                        photo: student['Photo'] ?? '',
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _iconDropdownField({
    required IconData icon,
    required String hint,
    required String? value,
    required List<Map<String, dynamic>> items,
    required String labelKey,
    required Function(String) onChanged,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: items.any((e) => e["id"].toString() == value)
                    ? value
                    : null,
                isExpanded: true,
                hint: Text(
                  hint,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                items: items.map((e) {
                  return DropdownMenuItem<String>(
                    value: e["id"].toString(),
                    child: Text(
                      e[labelKey].toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FeeCard extends StatelessWidget {
  final String name;
  final String father;
  final String classSec;
  final String mobile;
  final String due;
  final String photo;

  const FeeCard({
    super.key,

    required this.name,
    required this.father,
    required this.classSec,
    required this.mobile,
    required this.due,
    required this.photo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: photo.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(photo),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: Colors.grey.shade200,
            ),
            child: photo.isEmpty
                ? const Icon(Icons.person, size: 20, color: Colors.grey)
                : null,
          ),

          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.school, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(classSec, style: const TextStyle(fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.call, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(mobile, style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Due',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              const SizedBox(height: 2),
              Text(
                '₹$due',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
