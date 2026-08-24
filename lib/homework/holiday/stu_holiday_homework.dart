import 'dart:convert';

import 'package:sonia_public_school/api_service.dart';
import 'package:sonia_public_school/homework/holiday/stu_holiday_homework_details.dart';
import 'package:sonia_public_school/homework/homework_model.dart';
import 'package:flutter/material.dart';

class StudentHolidayHomeworkPage extends StatefulWidget {
  const StudentHolidayHomeworkPage({super.key});

  @override
  State<StudentHolidayHomeworkPage> createState() =>
      _StudentHolidayHomeworkPageState();
}

class _StudentHolidayHomeworkPageState
    extends State<StudentHolidayHomeworkPage> {
  List homeworkData = [];
  String selectedType = "All";
  final List<String> holidayTypes = [
    "All",
    "Summer",
    "Winter",
    "Festival",
    "National",
    "Weekly",
  ];

  bool isLoading = true;
  @override
  void initState() {
    super.initState();

    fetchHolidayHomework();
  }

  Future<void> fetchHolidayHomework() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.post(
        context,
        "/student/holiday/homework",
      );

      if (response == null) return;

      debugPrint("STATUS => ${response.statusCode}");
      debugPrint("RESPONSE => ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        setState(() {
          homeworkData = decoded;
        });
      }
    } catch (e) {
      debugPrint("ERROR => $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  List get filteredHomework {
    if (selectedType == "All") {
      return homeworkData;
    }

    return homeworkData.where((item) {
      return item["Type"]?.toString().toLowerCase() ==
          selectedType.toLowerCase();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Holiday Homeworks"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : homeworkData.isEmpty
          ? const Center(child: Text("No Holiday Homework Found"))
          : Column(
              children: [
                SizedBox(
                  height: 42,

                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,

                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),

                    child: Row(
                      children: holidayTypes.map((type) {
                        final isSelected = selectedType == type;

                        return Padding(
                          padding: const EdgeInsets.only(right: 6),

                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedType = type;
                              });
                            },

                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),

                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),

                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.white,

                                borderRadius: BorderRadius.circular(18),

                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.grey.shade300,
                                ),
                              ),

                              child: Text(
                                type,

                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,

                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),

                    itemCount: filteredHomework.length,

                    itemBuilder: (context, index) {
                      final hw = filteredHomework[index];

                      return _homeworkCard(hw);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  /// 🔹 Homework Card
  Widget _homeworkCard(Map<String, dynamic> hw) {
    final attachment = hw["Attachment"]?.toString() ?? "";

    final hasAttachment = attachment.isNotEmpty;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                StudentHolidayHomeworkDetailPage(homeworkData: hw),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),

        padding: const EdgeInsets.all(12),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(14),

          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.06),

              blurRadius: 5,

              offset: const Offset(0, 2),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            /// ROW 1
            Row(
              children: [
                /// TITLE
                Expanded(
                  child: Text(
                    hw["Title"] ?? "",

                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                /// TYPE
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),

                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.10),

                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: Text(
                    hw["Type"] ?? "",

                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                /// DATE
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: Colors.grey.shade600,
                    ),

                    const SizedBox(width: 3),

                    Text(
                      hw["Date"] ?? "",

                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// DESCRIPTION
            Text(
              hw["Description"] ?? "",

              maxLines: 3,
              overflow: TextOverflow.ellipsis,

              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Colors.grey.shade800,
              ),
            ),

            /// BUTTON ROW
            if (hasAttachment) ...[
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,

                children: [
                  _actionButton(
                    icon: Icons.download_rounded,
                    label: "Download",
                    isPrimary: true,

                    onTap: () {
                      downloadFile(context, attachment);
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isPrimary ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isPrimary ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
