import 'dart:convert';

import 'package:sonia_public_school/admin/Attendance/stu_attendance.dart';
import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';

// MODEL (API se map kar sakte ho)
class AttendanceStudent {
  final int id;
  final String name;
  final String father;
  final String roll;
  final String studentClass;
  final String section;
  final String status;

  AttendanceStudent({
    required this.id,
    required this.name,
    required this.father,
    required this.roll,
    required this.studentClass,
    required this.section,
    required this.status,
  });

  factory AttendanceStudent.fromJson(Map<String, dynamic> json) {
    return AttendanceStudent(
      id: json['StudentId'],
      name: json['StudentName'] ?? '',
      father: json['FatherName'] ?? '',
      roll: json['RollNo'].toString(),
      studentClass: json['Class'] ?? '',
      section: json['Section'] ?? '',
      status: json['Status'] ?? '',
    );
  }
}

class AttendanceReportPage extends StatefulWidget {
  const AttendanceReportPage({super.key});

  @override
  State<AttendanceReportPage> createState() => _AttendanceReportPageState();
}

class _AttendanceReportPageState extends State<AttendanceReportPage> {
  DateTime selectedDate = DateTime.now();

  int? selectedClassId;
  int? selectedSectionId;

  String? selectedClass;
  String? selectedSection;

  Map<String, dynamic> counts = {};

  List<Map<String, dynamic>> classList = [];
  List<Map<String, dynamic>> sectionList = [];

  List<AttendanceStudent> students = [];
  String selectedFilter = "ALL";

  bool loadingClass = false;
  bool loadingSection = false;
  final TextEditingController searchCtrl = TextEditingController();
  String searchQuery = "";

  List<AttendanceStudent> get filteredList {
    List<AttendanceStudent> tempList = students;

    // 🔎 Status Filter
    if (selectedFilter != "ALL") {
      tempList = tempList.where((e) {
        final status = e.status.trim().toLowerCase().replaceAll(" ", "");

        switch (selectedFilter) {
          case "PRESENT":
            return status == "present";
          case "ABSENT":
            return status == "absent";
          case "LEAVE":
            return status == "leave";
          case "HALFDAY":
            return status == "halfday";
          case "HOLIDAY":
            return status == "holiday";
          case "NOTMARKED":
            return status == "notmarked";
          default:
            return true;
        }
      }).toList();
    }

    // 🔎 Name Search Filter
    if (searchQuery.isNotEmpty) {
      tempList = tempList.where((e) {
        return e.name.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    return tempList;
  }

  bool isLoading = false;
  @override
  void initState() {
    super.initState();
    fetchClasses();
    loadReport();
  }

  Future<void> loadReport() async {
    setState(() => isLoading = true);

    final res = await ApiService.post(
      context,
      "/admin/student/attendance/report",
      body: {
        "Date": selectedDate.toIso8601String().split('T').first,
        if (selectedClassId != null) "Class": selectedClassId,
        if (selectedSectionId != null) "Section": selectedSectionId,
      },
    );

    if (res != null && res.statusCode == 200) {
      final data = jsonDecode(res.body);
      debugPrint("📌 FULL RESPONSE: ${res.body}");

      counts = data['counts'] ?? {};

      students = (data['data'] as List).map((e) {
        debugPrint("🟢 Student Status Raw: ${e['Status']}");
        return AttendanceStudent.fromJson(e);
      }).toList();
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

      if (classList.isNotEmpty) {
        selectedClassId = classList.first['id'];
        selectedClass = classList.first['Class'];
        fetchSections(selectedClassId!);
      }
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
      loadReport();
    }

    setState(() => loadingSection = false);
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
      loadReport();
    }
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
          "Attendance Report",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => StudentAttendancePage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // FILTER BUTTONS
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                /// DATE
                GestureDetector(
                  onTap: pickDate,
                  child: _dateField(
                    "${selectedDate.day}-${selectedDate.month}-${selectedDate.year}",
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _iconDropdownField(
                        icon: Icons.school,
                        hint: "Class",
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
                          });

                          loadReport();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _iconDropdownField(
                        icon: Icons.layers,
                        hint: "Section",
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
                          loadReport();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (counts.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _countBox("Total", counts['total'], Colors.blue, "ALL"),
                      _countBox(
                        "Present",
                        counts['present'],
                        Colors.green,
                        "PRESENT",
                      ),
                      _countBox(
                        "Absent",
                        counts['absent'],
                        Colors.red,
                        "ABSENT",
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _countBox(
                        "Leave",
                        counts['leave'],
                        Colors.orange,
                        "LEAVE",
                      ),
                      _countBox(
                        "Half Day",
                        counts['half_day'],
                        Colors.purple,
                        "HALFDAY",
                      ),
                      _countBox(
                        "Holiday",
                        counts['holiday'],
                        Colors.grey,
                        "HOLIDAY",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black12),
              ),
              child: TextField(
                controller: searchCtrl,
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: "Search by student name",
                  hintStyle: TextStyle(fontSize: 15),
                  prefixIcon: Icon(Icons.search, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          // LIST
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredList.isEmpty
                ? const Center(child: Text("No Data Found"))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filteredList.length,

                    itemBuilder: (context, index) {
                      final s = filteredList[index];
                      Color statusColor;
                      IconData statusIcon;

                      final normalizedStatus = s.status
                          .trim()
                          .toLowerCase()
                          .replaceAll(" ", "");

                      switch (normalizedStatus) {
                        case "present":
                          statusColor = const Color(0xff6CC04A);
                          statusIcon = Icons.check;
                          break;

                        case "absent":
                          statusColor = Colors.redAccent;
                          statusIcon = Icons.close;
                          break;

                        case "leave":
                          statusColor = Colors.orange;
                          statusIcon = Icons.time_to_leave;
                          break;

                        case "halfday":
                          statusColor = Colors.purple;
                          statusIcon = Icons.hourglass_bottom;
                          break;

                        case "holiday":
                          statusColor = Colors.grey;
                          statusIcon = Icons.beach_access;
                          break;

                        case "notmarked":
                          statusColor = Colors.blueGrey;
                          statusIcon = Icons.help_outline;
                          break;

                        default:
                          statusColor = Colors.blueGrey;
                          statusIcon = Icons.help_outline;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 34,
                              width: 34,
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                statusIcon,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        s.name,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        '(${s.father})',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        'Class: ${s.studentClass} (${s.section})',

                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Roll No: ${s.roll}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                s.status.isEmpty
                                    ? "NOT MARKED"
                                    : s.status.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
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

  Widget _countBox(String title, dynamic value, Color color, String filterKey) {
    final isSelected = selectedFilter == filterKey;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedFilter = filterKey;
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(
                value?.toString() ?? "0",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
