import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sonia_public_school/admin/Attendance/attendance_report.dart';
import 'package:sonia_public_school/api_service.dart';

class StudentAttendancePage extends StatefulWidget {
  const StudentAttendancePage({super.key});

  @override
  State<StudentAttendancePage> createState() => _StudentAttendancePageState();
}

class StudentModel {
  final int id;
  final String name;
  final String father;
  final String roll;
  final String status;

  StudentModel({
    required this.id,
    required this.name,
    required this.father,
    required this.roll,
    required this.status,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'],
      name: json['StudentName'] ?? '',
      father: json['FatherName'] ?? '',
      roll: json['RollNo']?.toString() ?? '',

      status: json['Status'] ?? 'not_marked',
    );
  }
}

class _StudentAttendancePageState extends State<StudentAttendancePage> {
  int? selectedClassId;
  int? selectedSectionId;
  bool isSubmitting = false;

  String? selectedClass;
  String? selectedSection;
  DateTime selectedDate = DateTime.now();
  final TextEditingController searchCtrl = TextEditingController();
  String attendanceType = "create";

  bool loadingClass = false;
  bool loadingSection = false;
  List<StudentModel> allStudents = [];
  List<StudentModel> filteredStudents = [];
  Map<int, String> attendance = {};
  List<Map<String, dynamic>> classList = [];
  List<Map<String, dynamic>> sectionList = [];
  bool isLoading = false;
  bool hasLoadedData = false;

  @override
  void initState() {
    super.initState();
    fetchClasses();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
      fetchAttendanceStudents();
    }
  }

  Future<void> fetchAttendanceStudents() async {
    if (selectedClassId == null || selectedSectionId == null) return;

    setState(() {
      isLoading = true;
      hasLoadedData = false;
      allStudents.clear();
      filteredStudents.clear();
      attendance.clear();
    });

    final res = await ApiService.post(
      context,
      "/admin/student/attendance",
      body: {
        "Class": selectedClassId,
        "Section": selectedSectionId,
        "Date": selectedDate.toIso8601String().split('T').first,
        "Type": attendanceType,
      },
    );

    if (res != null && res.statusCode == 200) {
      final List data = jsonDecode(res.body);

      allStudents = data.map((e) => StudentModel.fromJson(e)).toList();
      filteredStudents = allStudents;

      for (var s in allStudents) {
        if (s.status != 'not_marked') {
          attendance[s.id] = s.status;
        }
      }

      hasLoadedData = true;
    }

    setState(() => isLoading = false);
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

  Future<void> submitAttendance() async {
    if (attendance.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please mark attendance")));
      return;
    }

    setState(() => isSubmitting = true);

    final payload = {
      "AttendanceDate": selectedDate.toIso8601String().split('T').first,
      "Type": attendanceType,
      "Attendance": attendance.entries.map((e) {
        return {"StudentId": e.key, "Status": e.value};
      }).toList(),
    };

    final res = await ApiService.post(
      context,
      "/admin/student/attendance/store",
      body: payload,
    );

    setState(() => isSubmitting = false);

    if (res != null && res.statusCode == 200) {
      final data = jsonDecode(res.body);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Attendance saved')),
      );
    }
  }

  void _confirmSubmitAttendance() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Attendance"),
          content: const Text("Are you sure you want to submit attendance?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text("Submit"),
              onPressed: () {
                Navigator.pop(context);
                submitAttendance();
              },
            ),
          ],
        );
      },
    );
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
      fetchAttendanceStudents();
    }

    setState(() => loadingSection = false);
  }

  void _searchStudent(String value) {
    if (value.isEmpty) {
      filteredStudents = allStudents;
      setState(() {});
      return;
    }

    final q = value.toLowerCase();

    filteredStudents = allStudents.where((s) {
      return s.name.toLowerCase().contains(q) ||
          s.roll.toLowerCase().contains(q);
    }).toList();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: BackButton(),
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          "Student Attendance",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.format_list_bulleted_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AttendanceReportPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xffF8F9FD),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Date & Type *'),
              Row(
                children: [
                  // DATE
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _selectDate,
                      child: _dateField(
                        "${selectedDate.day}-${selectedDate.month}-${selectedDate.year}",
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // TYPE DROPDOWN
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: attendanceType,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: "create",
                              child: Text("Create"),
                            ),
                            DropdownMenuItem(
                              value: "update",
                              child: Text("Update"),
                            ),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() {
                              attendanceType = v;
                            });
                            fetchAttendanceStudents(); // 🔥 type change par list reload
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),
              Text(
                "Selected Date: ${selectedDate.day}-${selectedDate.month}-${selectedDate.year}",
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),

              const SizedBox(height: 9),
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
                        final cls = classList.firstWhere(
                          (e) => e['Class'] == v,
                        );
                        setState(() {
                          selectedClass = v;
                          selectedClassId = cls['id'];
                          selectedSection = null;
                          selectedSectionId = null;
                          hasLoadedData = false;
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
                        fetchAttendanceStudents();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (hasLoadedData) ...[
                SizedBox(
                  height: 38,
                  child: TextField(
                    controller: searchCtrl,
                    onChanged: _searchStudent,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, size: 18),
                      hintText: "Search student / roll",
                      hintStyle: const TextStyle(fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xffEEF2FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _bulkBtn("Present", Colors.green, "P"),
                    _bulkBtn("Absent", Colors.red, "A"),
                    _bulkBtn("Holiday", Colors.grey, "H"),
                  ],
                ),
              ],

              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (hasLoadedData && filteredStudents.isEmpty) ...[
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    "No students found in this class",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ] else if (hasLoadedData) ...[
                const SizedBox(height: 10),
                ...filteredStudents.map(_studentCard),

                if (filteredStudents.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: InkWell(
                      onTap: isSubmitting ? null : _confirmSubmitAttendance,
                      child: Container(
                        margin: const EdgeInsets.only(top: 20),
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child: isSubmitting
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Update Attendance",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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

  Widget _bulkBtn(String text, Color color, String status) {
    return Expanded(
      child: InkWell(
        onTap: filteredStudents.isEmpty
            ? null
            : () {
                for (var s in filteredStudents) {
                  attendance[s.id] = status;
                }
                setState(() {});
              },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _studentCard(StudentModel s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF2F2F2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Roll No: ${s.roll}",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Name: ${s.name.toUpperCase()}",
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  "Father: ${s.father.toUpperCase()}",
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),

          // RIGHT BUTTONS
          Column(
            children: [
              Row(
                children: [
                  _statusBtn("P", Colors.green, s.id),
                  _statusBtn("A", Colors.red, s.id),
                  _statusBtn("L", Colors.orange, s.id),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _statusBtn("HF", Colors.lightBlue, s.id),
                  _statusBtn("H", Colors.grey, s.id),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBtn(String text, Color color, int id) {
    final isSelected = attendance[id] == text;

    return InkWell(
      onTap: () {
        setState(() {
          attendance[id] = text;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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

  Widget _dateField(String date) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(date, style: const TextStyle(fontSize: 12))),
          Container(
            height: double.infinity,
            width: 38,
            decoration: const BoxDecoration(
              color: Color(0xffEAF6EF),
              borderRadius: BorderRadius.horizontal(right: Radius.circular(8)),
            ),
            child: const Icon(
              Icons.calendar_month,
              size: 16,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
