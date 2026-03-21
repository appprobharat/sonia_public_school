import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';

class AttendanceEmployee {
  final int id;
  final String name;
  final String relative;
  final String designation;
  final String contact;
  final String status;

  AttendanceEmployee({
    required this.id,
    required this.name,
    required this.relative,
    required this.designation,
    required this.contact,
    required this.status,
  });
}

class EmployeeAttendanceReport extends StatefulWidget {
  const EmployeeAttendanceReport({super.key});

  @override
  State<EmployeeAttendanceReport> createState() =>
      _EmployeeAttendanceReportState();
}

class _EmployeeAttendanceReportState extends State<EmployeeAttendanceReport> {
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;

  String selectedFilter = "ALL";
  String searchQuery = "";

  Map<String, dynamic> counts = {};
  List<AttendanceEmployee> allEmployees = [];

  List<AttendanceEmployee> get filteredList {
    List<AttendanceEmployee> temp = allEmployees;

    if (selectedFilter != "ALL") {
      temp = temp.where((e) {
        final status = e.status.trim().toLowerCase().replaceAll(" ", "");
        return status == selectedFilter.toLowerCase().replaceAll(" ", "");
      }).toList();
    }

    if (searchQuery.isNotEmpty) {
      temp = temp.where((e) {
        return e.name.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    return temp;
  }

  @override
  void initState() {
    super.initState();
    fetchReport();
  }

  // 🔹 STATUS COLOR
  Color getStatusColor(String status) {
    switch (status.toLowerCase().replaceAll(" ", "")) {
      case "present":
        return const Color(0xff6CC04A);
      case "absent":
        return Colors.redAccent;
      case "leave":
        return Colors.orange;
      case "halfday":
        return Colors.purple;
      case "holiday":
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  // 🔹 FETCH REPORT
  Future<void> fetchReport() async {
    setState(() => isLoading = true);

    final res = await ApiService.post(
      context,
      "/admin/employee/attendance/report",
      body: {"Date": selectedDate.toIso8601String().split('T').first},
    );

    if (res != null && res.statusCode == 200) {
      final decoded = jsonDecode(res.body);

      counts = decoded['counts'] ?? {};

      final List data = decoded['data'] ?? [];

      allEmployees = data.map((e) {
        return AttendanceEmployee(
          id: e['EmployeeId'],
          name: e['EmployeeName'] ?? "",
          relative: e['RelativeName'] ?? "-",
          designation: e['Designation'] ?? "-",
          contact: e['ContactNo']?.toString() ?? "-",
          status: e['Status'] ?? "Not Marked",
        );
      }).toList();
    }

    setState(() => isLoading = false);
  }

  // 🔹 DATE PICKER
  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
      fetchReport();
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
          "Employee Attendance Report",
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
                MaterialPageRoute(builder: (_) => EmployeeAttendanceReport()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 📅 DATE
          Padding(
            padding: const EdgeInsets.all(12),
            child: GestureDetector(
              onTap: pickDate,
              child: _dateField(
                "${selectedDate.day}-${selectedDate.month}-${selectedDate.year}",
              ),
            ),
          ),

          // 🔢 COUNTS (STUDENT JAISE)
          if (counts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
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

          // 🔍 SEARCH
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => searchQuery = v),
              decoration: const InputDecoration(
                hintText: "Search employee name",
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
            ),
          ),

          // 📋 LIST
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredList.isEmpty
                ? const Center(child: Text("No Data Found"))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final e = filteredList[index];
                      final color = getStatusColor(e.status);

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
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 34,
                              width: 34,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 18,
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
                                        e.name,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        "(${e.relative})",
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "Designation: ${e.designation}",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  Text(
                                    "Contact: ${e.contact}",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black54,
                                    ),
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
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                e.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: color,
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

  Widget _dateField(String date) {
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
          const Icon(Icons.calendar_today, size: 16),
          const SizedBox(width: 8),
          Text(date, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
