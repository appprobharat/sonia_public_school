import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';

class AlertPage extends StatefulWidget {
  const AlertPage({super.key});

  @override
  State<AlertPage> createState() => _AlertPageState();
}

class _AlertPageState extends State<AlertPage> {
  String? selectedClass;
  bool sending = false;
  String? selectedSection;
  bool selectAll = true;
  int? selectedClassId;
  bool loadingClass = false;
  bool loadingSection = false;
  int? selectedSectionId;
  final TextEditingController messageCtrl = TextEditingController();
  List<Map<String, dynamic>> classList = [];
  List<Map<String, dynamic>> sectionList = [];
  bool hasLoadedData = false;
  List<Map<String, dynamic>> students = [];
  bool loadingStudents = false;
  @override
  void initState() {
    super.initState();
    fetchClasses();
  }

  Future<void> fetchStudents() async {
    if (selectedClassId == null || selectedSectionId == null) return;

    setState(() => loadingStudents = true);

    final res = await ApiService.post(
      context,
      "/get_student",
      body: {"ClassId": selectedClassId, "SectionId": selectedSectionId},
    );

    if (res != null && res.statusCode == 200) {
      final List data = jsonDecode(res.body);

      students = data.map((e) {
        return {
          "id": e["id"],
          "name": e["StudentName"],
          "father": e["FatherName"],
          "mobile": e["ContactNo"].toString(),
          "class": "${e["Class"]} / ${e["Section"]}",
          "selected": true,
          "image": null,
        };
      }).toList();

      selectAll = true;
    }

    setState(() => loadingStudents = false);
  }

  Future<void> sendAlert(List<int> studentIds) async {
    setState(() => sending = true);

    final res = await ApiService.post(
      context,
      "/admin/student/alert",
      body: {"message": messageCtrl.text.trim(), "student_ids": studentIds},
    );

    setState(() => sending = false);

    if (res != null && res.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Alert sent successfully")));
      messageCtrl.clear();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to send alert")));
    }
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
      students.clear(); // 🔥 clear students immediately
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

        await fetchStudents();
      }
    }

    setState(() => loadingSection = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff3e5f5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: BackButton(),
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          "Student Alert",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _iconDropdownField(
                    icon: Icons.school,
                    hint: "Select Class",
                    value: selectedClass,
                    items: classList,

                    labelKey: "Class",
                    onChanged: (v) {
                      final cls = classList.firstWhere((e) => e['Class'] == v);

                      setState(() {
                        selectedClass = v;
                        selectedClassId = cls['id'];
                        selectedSection = null;
                        selectedSectionId = null;
                        students.clear();
                        selectAll = true;
                      });

                      fetchSections(selectedClassId!);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _iconDropdownField(
                    icon: Icons.layers,
                    hint: "Select Section",
                    value: selectedSection,
                    items: sectionList,
                    labelKey: "SectionName",
                    onChanged: (v) {
                      final sec = sectionList.firstWhere(
                        (e) => e['SectionName'] == v,
                      );
                      setState(() {
                        selectedSection = v;
                        selectedSectionId = sec['id'];
                      });

                      fetchStudents();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _messageBox(),
            _selectAll(),
            Expanded(child: _studentList()),
          ],
        ),
      ),
    );
  }

  Widget _messageBox() {
    return TextField(
      controller: messageCtrl,
      maxLines: 2,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: "Enter your message here...",
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _selectAll() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Checkbox(
                  value: selectAll,
                  onChanged: (v) {
                    setState(() {
                      selectAll = v ?? false;
                      for (var student in students) {
                        student['selected'] = selectAll;
                      }
                    });
                  },
                ),
                const Text("Select All", style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: sending ? Colors.green.shade300 : Colors.green,
                disabledBackgroundColor: Colors.green.shade300,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: sending
                  ? null
                  : () {
                      final selectedStudents = students
                          .where((s) => s['selected'] == true)
                          .toList();

                      if (selectedStudents.isEmpty ||
                          messageCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Select students & enter message"),
                          ),
                        );
                        return;
                      }

                      final selectedIds = selectedStudents
                          .map<int>((s) => s['id'] as int)
                          .toList();

                      sendAlert(selectedIds);
                    },
              child: sending
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.send, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          "Send",
                          style: TextStyle(fontSize: 13, color: Colors.white),
                        ),
                      ],
                    ),
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
                value: value,
                isExpanded: true,
                hint: Text(
                  hint,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                items: items.map((e) {
                  return DropdownMenuItem<String>(
                    value: e[labelKey].toString(),
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

  Widget _studentList() {
    if (loadingStudents) {
      return const Center(child: CircularProgressIndicator());
    }

    if (students.isEmpty) {
      return const Center(child: Text("No students found"));
    }

    return ListView.builder(
      itemCount: students.length,
      itemBuilder: (context, index) {
        final s = students[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: s['selected'],
                onChanged: (v) {
                  setState(() {
                    s['selected'] = v;
                    selectAll = students.every(
                      (stu) => stu['selected'] == true,
                    );
                  });
                },
              ),
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.grey.shade300,
                child: const Icon(Icons.person, size: 22),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      "Father Name: ${s['father']}",
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      "Mobile No.: ${s['mobile']}",
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Class / Section: ${s['class']}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
