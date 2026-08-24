import 'dart:convert';

import 'package:sonia_public_school/Attendance_UI/attendance_report_pdf.dart';
import 'package:sonia_public_school/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendanceReportListPage extends StatefulWidget {
  const AttendanceReportListPage({super.key});

  @override
  State<AttendanceReportListPage> createState() =>
      _AttendanceReportListPageState();
}

class _AttendanceReportListPageState extends State<AttendanceReportListPage> {
  final TextEditingController searchController = TextEditingController();

  String selectedFilter = "All";
  DateTime selectedDate = DateTime.now();

  List<dynamic> students = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchAttendanceReport();
  }

  Future<void> fetchAttendanceReport() async {
    try {
      print("======================================");
      print("Attendance API Called");

      setState(() {
        isLoading = true;
      });

      final body = {
        "Date": DateFormat("yyyy-MM-dd").format(selectedDate),
        "AttendanceType": selectedFilter,
      };

      print("Request Body : $body");

      final response = await ApiService.post(
        context,
        "/teacher/std_attendance/report_list",
        body: body,
      );

      if (response == null) {
        print("❌ Response is NULL");

        setState(() {
          isLoading = false;
        });
        return;
      }

      print("Status Code : ${response.statusCode}");
      print("Raw Response : ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        print("Decoded Response : $data");
        print("Response Type : ${data.runtimeType}");

        // If response is List
        if (data is List) {
          print("✅ API returned LIST");
          print("Total Records : ${data.length}");

          if (data.isNotEmpty) {
            print("First Record : ${data.first}");
          }

          setState(() {
            students = data;
            isLoading = false;
          });
        }
        // If response is Map
        else if (data is Map<String, dynamic>) {
          print("✅ API returned MAP");
          print("Keys : ${data.keys}");

          if (data.containsKey("data")) {
            print("Data Length : ${(data["data"] as List).length}");

            setState(() {
              students = data["data"] ?? [];
              isLoading = false;
            });
          } else {
            print("⚠️ 'data' key not found.");

            setState(() {
              students = [];
              isLoading = false;
            });
          }
        } else {
          print("❌ Unknown Response Format");

          setState(() {
            students = [];
            isLoading = false;
          });
        }

        print("Students Count : ${students.length}");
      } else {
        print("❌ API Error");
        print("Status Code : ${response.statusCode}");
        print("Body : ${response.body}");

        setState(() {
          students = [];
          isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print("❌ Exception : $e");
      print("StackTrace :");
      print(stackTrace);

      setState(() {
        students = [];
        isLoading = false;
      });
    }

    print("======================================");
  }

  @override
  Widget build(BuildContext context) {
    final filtered = students.where((e) {
      return (e["StudentName"] ?? "").toString().toLowerCase().contains(
        searchController.text.toLowerCase(),
      );
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FC),

      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "Attendance Report",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AttendancePdfPage(
                    students: filtered,
                    filter: selectedFilter,
                    date: selectedDate,
                  ),
                ),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff2563EB), Color(0xff3B82F6)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Attendance Date",
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy').format(selectedDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.edit_calendar_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );

                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });

                      fetchAttendanceReport();
                    }
                  },
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: "Search student...",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xff2563EB).withOpacity(.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: Color(0xff2563EB),
                      size: 20,
                    ),
                  ),
                  suffixIcon: searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            searchController.clear();
                            setState(() {});
                          },
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xff2563EB),
                      width: 1.4,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          SizedBox(
            height: 38,

            child: ListView(
              scrollDirection: Axis.horizontal,

              padding: const EdgeInsets.symmetric(horizontal: 12),

              children: [
                chip("All"),
                chip("Present"),
                chip("Absent"),
                chip("Leave"),
                chip("HalfDay"),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_turned_in_outlined,
                          size: 70,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          "No Attendance Found",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,

                    itemBuilder: (context, index) {
                      final s = filtered[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
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
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(
                                0xff2563EB,
                              ).withOpacity(.12),
                              child: Text(
                                ((s["StudentName"] ?? "").toString().isNotEmpty)
                                    ? (s["StudentName"] as String)[0]
                                          .toUpperCase()
                                    : "?",
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s["StudentName"],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Roll: ${s["RollNo"] ?? "N/A"}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    (s["FatherName"] ?? "-").toString(),

                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              s["AttendanceDate"] == null
                                  ? "-"
                                  : DateFormat("dd-MM-yyyy").format(
                                      DateTime.parse(
                                        s["AttendanceDate"].toString(),
                                      ),
                                    ),

                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 8),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor(
                                  (s["AttendanceType"] ?? "").toString(),
                                ).withOpacity(.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                (s["AttendanceType"] ?? "-").toString(),

                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor(
                                    (s["AttendanceType"] ?? "").toString(),
                                  ),
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

  Widget summary(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        Text(title, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget chip(String value) {
    final selected = selectedFilter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(value == "HalfDay" ? "Half Day" : value),
        selected: selected,
        onSelected: (_) {
          setState(() {
            selectedFilter = value;
          });
          fetchAttendanceReport();
        },
      ),
    );
  }

  Color statusColor(String status) {
    switch (status) {
      case "Present":
        return Colors.green;

      case "Absent":
        return Colors.red;

      case "Leave":
        return Colors.orange;

      case "HalfDay":
        return Colors.blue;

      default:
        return Colors.grey;
    }
  }
}
