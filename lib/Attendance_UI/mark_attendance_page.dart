import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sonia_public_school/api_service.dart';

class MarkAttendancePage extends StatefulWidget {
  const MarkAttendancePage({super.key});

  @override
  State<MarkAttendancePage> createState() => _MarkAttendancePageState();
}

class _MarkAttendancePageState extends State<MarkAttendancePage> {
  DateTime selectedDate = DateTime.now();
  TextEditingController searchController = TextEditingController();

  String selectedCommonStatus = "";
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> filteredStudents = [];

  bool isLoading = false;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ====================================================
  // 🔐 SAFE FETCH STUDENTS (iOS + Android)
  // ====================================================
  Future<void> fetchStudents() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final res = await ApiService.post(
        context,
        "/teacher/std_attendance",
        body: {'Date': DateFormat('yyyy-MM-dd').format(selectedDate)},
      );

      // AuthHelper already handles 401 + logout
      if (res == null) return;

      debugPrint("📥 ATTENDANCE STATUS: ${res.statusCode}");
      debugPrint("📥 ATTENDANCE BODY: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
          data,
        );

        for (final student in list) {
          if (student['Status'] == 'not_marked') {
            student['Status'] = null;
          }
        }

        if (!mounted) return;
        setState(() {
          students = list;
          filteredStudents = List.from(list);
          selectedCommonStatus = "";
        });
      } else {
        if (!mounted) return;
        setState(() {
          students.clear();
          filteredStudents.clear();
        });
      }
    } catch (e) {
      debugPrint("🚨 FETCH ATTENDANCE ERROR: $e");

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Something went wrong")));
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  // ====================================================
  // 🔎 SEARCH
  // ====================================================
  void filterSearch(String query) {
    if (!mounted) return;

    setState(() {
      filteredStudents = students
          .where(
            (s) =>
                s['StudentName'].toString().toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                s['RollNo'].toString().contains(query),
          )
          .toList();
    });
  }

  // ====================================================
  // 📅 DATE PICKER
  // ====================================================
  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
      fetchStudents();
    }
  }

  // ====================================================
  // 🟢 MARK ALL
  // ====================================================
  void markAll(String status) {
    if (!mounted) return;

    setState(() {
      selectedCommonStatus = status;
      for (final s in students) {
        s['Status'] = status;
      }
      filterSearch(searchController.text);
    });
  }

  // ====================================================
  // 👤 MARK SINGLE
  // ====================================================
  void markSingle(int index, String status) {
    if (!mounted) return;

    final id = filteredStudents[index]['id'];

    setState(() {
      filteredStudents[index]['Status'] = status;
      final idx = students.indexWhere((s) => s['id'] == id);
      if (idx != -1) {
        students[idx]['Status'] = status;
      }
    });
  }

  // ====================================================
  // 🚀 SUBMIT ATTENDANCE (SAFE)
  // ====================================================
  Future<void> submitAttendance() async {
    if (!mounted) return;

    setState(() => isSubmitting = true);

    try {
      final payload = {
        "AttendanceDate": DateFormat('yyyy-MM-dd').format(selectedDate),
        "Attendance": students
            .map((s) => {"StudentId": s['id'], "Status": s['Status']})
            .toList(),
      };

      debugPrint("📤 SUBMIT PAYLOAD: $payload");

      final res = await ApiService.post(
        context,
        "/teacher/std_attendance/store",
        body: payload,
      );

      if (res == null) return;

      debugPrint("📥 SUBMIT STATUS: ${res.statusCode}");
      debugPrint("📥 SUBMIT BODY: ${res.body}");

      final result = jsonDecode(res.body);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Attendance updated successfully'),
        ),
      );
    } catch (e) {
      debugPrint("🚨 SUBMIT ERROR: $e");

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Submission failed")));
    } finally {
      if (!mounted) return;
      setState(() => isSubmitting = false);
    }
  }

  // ====================================================
  // 🎨 UI HELPERS (UNCHANGED)
  // ====================================================
  Color getColor(String status) {
    switch (status) {
      case "A":
        return Colors.red;
      case "P":
        return Colors.green;
      case "L":
        return Colors.orange;
      case "H":
        return Colors.grey;
      case "HF":
        return Colors.blue;
      default:
        return Colors.black;
    }
  }

  Widget buildCircleButton(String label, String status) {
    final isSelected = selectedCommonStatus == status;
    return GestureDetector(
      onTap: () => markAll(status),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? getColor(status) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget buildStatusButton(
    String label,
    String status,
    VoidCallback onTap,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: getColor(status).withOpacity(isSelected ? 1 : 0.4),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mark Attendance"),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: AppColors.primary),
                const SizedBox(width: 10),
                Text("Date: ${DateFormat('dd-MM-yyyy').format(selectedDate)}"),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: pickDate,
                  icon: const Icon(Icons.edit_calendar, color: Colors.white),
                  label: const Text(
                    "Pick Date",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search student...",
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.primary.shade50,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
              onChanged: filterSearch,
            ),
          ),

          if (students.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.grey.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  buildCircleButton("Present", "P"),
                  buildCircleButton("Absent", "A"),
                  buildCircleButton("Holiday", "H"),
                ],
              ),
            ),

          if (isLoading) const Center(child: CircularProgressIndicator(color: AppColors.primary),),
          if (!isLoading && students.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = filteredStudents[index];

                  // final status = student['Status'];

                  return Card(
                    color:
                        (student['Status'] == null ||
                            student['Status'] == 'not_marked')
                        ? Colors.grey.shade200
                        : Colors.white,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Roll No: ${student['RollNo']}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Name: ${student['StudentName'] ?? 'Name Missing'}",
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Father: ${student['FatherName'] ?? ''}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          /// RIGHT SIDE - Status buttons
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  buildStatusButton(
                                    "P",
                                    "P",
                                    () => markSingle(index, "P"),
                                    student['Status'] == "P",
                                  ),
                                  buildStatusButton(
                                    "A",
                                    "A",
                                    () => markSingle(index, "A"),
                                    student['Status'] == "A",
                                  ),
                                  buildStatusButton(
                                    "L",
                                    "L",
                                    () => markSingle(index, "L"),
                                    student['Status'] == "L",
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  buildStatusButton(
                                    "HF",
                                    "HF",
                                    () => markSingle(index, "HF"),
                                    student['Status'] == "HF",
                                  ),
                                  buildStatusButton(
                                    "H",
                                    "H",
                                    () => markSingle(index, "H"),
                                    student['Status'] == "H",
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          if (!isLoading && students.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: double.infinity,
                child: isSubmitting
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary),)
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          bool? confirm = await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Confirm Submission'),
                              content: const Text(
                                'Are you sure you want to submit the attendance?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Submit'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            final unmarkedStudents = students
                                .where(
                                  (s) =>
                                      s['Status'] == null ||
                                      s['Status'].toString().trim().isEmpty ||
                                      s['Status'].toString().toLowerCase() ==
                                          'not_marked',
                                )
                                .toList();

                            if (unmarkedStudents.isNotEmpty) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Row(
                                    children: const [
                                      Icon(Icons.warning, color: Colors.red),
                                      SizedBox(width: 9),
                                      Text(
                                        "Incomplete Attendance",
                                        style: TextStyle(fontSize: 18),
                                      ),
                                    ],
                                  ),
                                  content: const Text(
                                    "⚠️ Please mark attendance for all students before submitting.",
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text(
                                        "OK",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              return; // stop submission
                            }

                            // If all students are marked
                            submitAttendance();
                          }
                        },
                        child: const Text(
                          "Update Attendance",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
