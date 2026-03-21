import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sonia_public_school/admin/Attendance/emp_attendance_report.dart';
import 'package:sonia_public_school/api_service.dart';

class EmployeeAttendancePage extends StatefulWidget {
  const EmployeeAttendancePage({super.key});

  @override
  State<EmployeeAttendancePage> createState() => _EmployeeAttendancePageState();
}

class EmployeeModel {
  final int id;
  final String name;
  final String relativeName;
  final String contact;
  final String status;
  final String designation;

  EmployeeModel({
    required this.id,
    required this.name,
    required this.relativeName,
    required this.contact,
    required this.status,
    required this.designation,
  });
}

class _EmployeeAttendancePageState extends State<EmployeeAttendancePage> {
  DateTime selectedDate = DateTime.now();
  String? selectedType;
  bool isLoading = false;
  bool isSaving = false;

  final TextEditingController searchCtrl = TextEditingController();

  List<EmployeeModel> allEmployees = [];
  List<EmployeeModel> filteredEmployees = [];

  Map<int, String> attendance = {};

  @override
  void initState() {
    super.initState();

    selectedType = "create";
    fetchAttendanceList();
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
      if (selectedType != null) {
        fetchAttendanceList();
      }
    }
  }

  void _confirmSaveAttendance() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Attendance"),
          content: const Text(
            "Are you sure you want to submit employee attendance?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                saveAttendance();
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  Future<void> saveAttendance() async {
    if (selectedType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select Type")));
      return;
    }

    if (attendance.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please mark attendance first")),
      );
      return;
    }

    setState(() => isSaving = true);

    final attendanceList = filteredEmployees.map((e) {
      return {"EmployeeId": e.id, "Status": attendance[e.id] ?? "A"};
    }).toList();

    final body = {
      "AttendanceDate": selectedDate.toIso8601String().split('T').first,
      "Type": selectedType,
      "Attendance": attendanceList,
    };

    final res = await ApiService.post(
      context,
      "/admin/employee/attendance/store",
      body: body,
    );

    setState(() => isSaving = false);

    if (res != null && res.statusCode == 200) {
      final decoded = jsonDecode(res.body);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(decoded['message'] ?? "Attendance Saved")),
      );

      // Optional: Refresh list after save
      fetchAttendanceList();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save attendance")),
      );
    }
  }

  Future<void> fetchAttendanceList() async {
    if (selectedType == null) return;

    setState(() => isLoading = true);

    final res = await ApiService.post(
      context,
      "/admin/employee/attendance",
      body: {
        "Date": selectedDate.toIso8601String().split('T').first,
        "Type": selectedType,
      },
    );

    if (res != null && res.statusCode == 200) {
      final List data = jsonDecode(res.body);

      attendance.clear();

      allEmployees = data.map<EmployeeModel>((e) {
        final int empId = e['id'] is int
            ? e['id']
            : int.tryParse(e['id'].toString()) ?? 0;

        final String status = e['Status']?.toString() ?? "not_marked";

        if (status != "not_marked") {
          attendance[empId] = status;
        }

        return EmployeeModel(
          id: empId,
          name: e['EmployeeName']?.toString() ?? "",
          relativeName: e['RelativeName']?.toString() ?? "-",
          contact: e['ContactNo']?.toString() ?? "-",
          status: status,
          designation: e['designation']?.toString() ?? "",
        );
      }).toList();

      filteredEmployees = List.from(allEmployees);
    }

    setState(() => isLoading = false);
  }

  void _searchEmployee(String value) {
    if (value.isEmpty) {
      filteredEmployees = List.from(allEmployees);
    } else {
      filteredEmployees = allEmployees
          .where(
            (e) =>
                e.name.toLowerCase().contains(value.toLowerCase()) ||
                e.designation.toLowerCase().contains(value.toLowerCase()),
          )
          .toList();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: const BackButton(),
        title: const Text(
          "Employee Attendance",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.format_list_bulleted_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EmployeeAttendanceReport()),
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
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectDate,
                      child: _dateField(
                        "${selectedDate.day}-${selectedDate.month}-${selectedDate.year}",
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  /// TYPE DROPDOWN
                  Expanded(
                    child: PopupMenuButton<String>(
                      onSelected: (v) {
                        setState(() {
                          selectedType = v;
                          attendance.clear();
                        });
                        fetchAttendanceList();
                      },

                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: "create",
                          child: Text("Create"),
                        ),
                        const PopupMenuItem(
                          value: "update",
                          child: Text("Update"),
                        ),
                      ],
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 10),
                            const Icon(Icons.filter_list, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                selectedType ?? "Select Type",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (selectedType != null) ...[
                const SizedBox(height: 12),

                /// SEARCH
                SizedBox(
                  height: 38,
                  child: TextField(
                    controller: searchCtrl,
                    onChanged: _searchEmployee,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, size: 18),
                      hintText: "Search employee",
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

                /// BULK BUTTONS
                Row(
                  children: [
                    _bulkBtn("Present", Colors.green, "P"),
                    _bulkBtn("Absent", Colors.red, "A"),
                    _bulkBtn("Holiday", Colors.grey, "H"),
                  ],
                ),

                const SizedBox(height: 10),

                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (filteredEmployees.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(
                        "No employees found",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...filteredEmployees.map(_employeeCard),

                const SizedBox(height: 20),

                if (filteredEmployees.isNotEmpty)
                  InkWell(
                    onTap: isSaving ? null : _confirmSaveAttendance,
                    child: Container(
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                selectedType == "create"
                                    ? "Create Attendance"
                                    : "Update Attendance",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
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
        onTap: () {
          for (var e in filteredEmployees) {
            attendance[e.id] = status;
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

  Widget _employeeCard(EmployeeModel e) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),

                Text(
                  "Relative: ${e.relativeName}",
                  style: const TextStyle(fontSize: 12),
                ),

                const SizedBox(height: 2),
                Text(
                  "Designation: ${e.designation}",
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text("📞 ${e.contact}", style: const TextStyle(fontSize: 12)),

                const SizedBox(height: 4),
              ],
            ),
          ),

          Column(
            children: [
              Row(
                children: [
                  _statusBtn("P", Colors.green, e.id),
                  _statusBtn("A", Colors.red, e.id),
                  _statusBtn("L", Colors.orange, e.id),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _statusBtn("HF", Colors.lightBlue, e.id),
                  _statusBtn("H", Colors.grey, e.id),
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
        setState(() => attendance[id] = text);
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
          const Icon(Icons.calendar_today, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(date, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
