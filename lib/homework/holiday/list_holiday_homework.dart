import 'dart:convert';
import 'package:sonia_public_school/api_service.dart';
import 'package:sonia_public_school/homework/holiday/add_holiday_homework.dart';
import 'package:sonia_public_school/homework/holiday/holiday_homework_detail.dart';
import 'package:sonia_public_school/homework/homework_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ListHolidayHomework extends StatefulWidget {
  const ListHolidayHomework({super.key});

  @override
  State<ListHolidayHomework> createState() => _ListHolidayHomeworkState();
}

class _ListHolidayHomeworkState extends State<ListHolidayHomework> {
  bool isLoading = true;

  List holidayHomeworkList = [];

  final List<String> holidayTypes = [
    "All",
    "Summer",
    "Winter",
    "Festival",
    "National",
    "Weekly",
  ];
  DateTime? selectedFromDate;
  DateTime? selectedToDate;
  String selectedType = "All";

  @override
  void initState() {
    super.initState();

    selectedToDate = DateTime.now();

    selectedFromDate = DateTime(
      selectedToDate!.year,
      selectedToDate!.month - 1,
      selectedToDate!.day,
    );

    fetchHolidayHomework();
  }

  Future<void> pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          selectedFromDate = picked;
        } else {
          selectedToDate = picked;
        }
      });

      fetchHolidayHomework();
    }
  }

  Future<void> fetchHolidayHomework() async {
    setState(() => isLoading = true);

    try {
      final body = <String, dynamic>{};
      if (selectedFromDate != null) {
        body['FromDate'] = DateFormat('yyyy-MM-dd').format(selectedFromDate!);
      }

      if (selectedToDate != null) {
        body['ToDate'] = DateFormat('yyyy-MM-dd').format(selectedToDate!);
      }
      if (selectedType != "All") {
        body['type'] = selectedType;
      }

      final response = await ApiService.post(
        context,
        "/teacher/holiday/homework",
        body: body,
      );

      if (response == null) return;

      debugPrint("📥 STATUS => ${response.statusCode}");
      debugPrint("📥 RESPONSE => ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        setState(() {
          holidayHomeworkList = decoded;
        });
      }
    } catch (e) {
      debugPrint("❌ ERROR => $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Color getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case "summer":
        return Colors.orange;

      case "winter":
        return Colors.blue;

      case "festival":
        return Colors.purple;

      case "national":
        return Colors.green;

      default:
        return Colors.teal;
    }
  }

  String formatDate(String? date) {
    if (date == null || date.isEmpty) return '';

    try {
      final parsedDate = DateTime.parse(date);

      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  Future<void> openAttachment(String url) async {
    try {
      final Uri uri = Uri.parse(url);

      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("❌ OPEN FILE ERROR => $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to open attachment")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      appBar: AppBar(
        title: const Text(
          "Holiday Homework",
          style: TextStyle(color: Colors.white),
        ),

        backgroundColor: AppColors.primary,

        iconTheme: const IconThemeData(color: Colors.white),

        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HolidayHomeworkPage(),
                ),
              );
            },

            icon: const Icon(Icons.add),
          ),
        ],
      ),

      body: Column(
        children: [
          /// DATE FILTER
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),

            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => pickDate(true),

                    child: Container(
                      height: 38,

                      padding: const EdgeInsets.symmetric(horizontal: 10),

                      decoration: BoxDecoration(
                        color: Colors.white,

                        borderRadius: BorderRadius.circular(10),

                        border: Border.all(color: Colors.grey.shade300),
                      ),

                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),

                          const SizedBox(width: 8),

                          Expanded(
                            child: Text(
                              selectedFromDate == null
                                  ? "From Date"
                                  : DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(selectedFromDate!),

                              style: TextStyle(
                                fontSize: 11.5,
                                color: selectedFromDate == null
                                    ? Colors.grey.shade600
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: InkWell(
                    onTap: () => pickDate(false),

                    child: Container(
                      height: 38,

                      padding: const EdgeInsets.symmetric(horizontal: 10),

                      decoration: BoxDecoration(
                        color: Colors.white,

                        borderRadius: BorderRadius.circular(10),

                        border: Border.all(color: Colors.grey.shade300),
                      ),

                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),

                          const SizedBox(width: 8),

                          Expanded(
                            child: Text(
                              selectedToDate == null
                                  ? "To Date"
                                  : DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(selectedToDate!),

                              style: TextStyle(
                                fontSize: 11.5,
                                color: selectedToDate == null
                                    ? Colors.grey.shade600
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// FILTER
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

                        fetchHolidayHomework();
                      },

                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),

                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),

                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,

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

                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          /// LIST
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : holidayHomeworkList.isEmpty
                ? const Center(child: Text("No Holiday Homework Found"))
                : RefreshIndicator(
                    onRefresh: fetchHolidayHomework,

                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),

                      itemCount: holidayHomeworkList.length,

                      itemBuilder: (context, index) {
                        final item = holidayHomeworkList[index];

                        final attachment = item['Attachment']?.toString() ?? '';

                        final hasAttachment = attachment.isNotEmpty;

                        return InkWell(
                          borderRadius: BorderRadius.circular(14),

                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HolidayHomeworkDetailPage(
                                  homeworkData: item,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),

                            padding: const EdgeInsets.all(12),

                            decoration: BoxDecoration(
                              color: Colors.white,

                              borderRadius: BorderRadius.circular(14),

                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.08),

                                  blurRadius: 6,

                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                /// TITLE + TYPE
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [
                                    Expanded(
                                      child: Text(
                                        item['Title']?.toString() ?? '',

                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),

                                      decoration: BoxDecoration(
                                        color: getTypeColor(
                                          item['Type']?.toString() ?? '',
                                        ).withOpacity(0.12),

                                        borderRadius: BorderRadius.circular(20),
                                      ),

                                      child: Text(
                                        item['Type']?.toString() ?? '',

                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,

                                          color: getTypeColor(
                                            item['Type']?.toString() ?? '',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                /// CLASS + DATE
                                Row(
                                  children: [
                                    Icon(
                                      Icons.school_rounded,
                                      size: 15,
                                      color: Colors.grey.shade600,
                                    ),

                                    const SizedBox(width: 5),

                                    Expanded(
                                      child: Text(
                                        item['Class']?.toString() ?? '',

                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),

                                    Icon(
                                      Icons.calendar_month_rounded,
                                      size: 15,
                                      color: Colors.grey.shade600,
                                    ),

                                    const SizedBox(width: 5),

                                    Text(
                                      formatDate(item['Date']?.toString()),

                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                /// DESCRIPTION + ATTACHMENT ICONS
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [
                                    /// DESCRIPTION
                                    Expanded(
                                      child: Text(
                                        item['Description']?.toString() ?? '',

                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,

                                        style: TextStyle(
                                          fontSize: 12,
                                          height: 1.45,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ),

                                    /// ICONS
                                    /// ICONS
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),

                                      child: Wrap(
                                        spacing: 2,
                                        runSpacing: 2,

                                        children: [
                                          /// VIEW
                                          if (hasAttachment)
                                            IconButton(
                                              constraints:
                                                  const BoxConstraints(),
                                              padding: EdgeInsets.zero,

                                              onPressed: () {
                                                openAttachment(attachment);
                                              },

                                              icon: const Icon(
                                                Icons.visibility_rounded,
                                                size: 20,
                                                color: AppColors.primary,
                                              ),
                                            ),

                                          /// DOWNLOAD
                                          if (hasAttachment)
                                            IconButton(
                                              constraints:
                                                  const BoxConstraints(),
                                              padding: EdgeInsets.zero,

                                              onPressed: () {
                                                downloadFile(
                                                  context,
                                                  attachment,
                                                );
                                              },

                                              icon: const Icon(
                                                Icons.download_rounded,
                                                size: 20,
                                                color: AppColors.primary,
                                              ),
                                            ),

                                          /// EDIT
                                          IconButton(
                                            constraints: const BoxConstraints(),
                                            padding: EdgeInsets.zero,

                                            onPressed: () async {
                                              final result =
                                                  await Navigator.push(
                                                    context,

                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          HolidayHomeworkPage(
                                                            homeworkData: {
                                                              "HomeworkId":
                                                                  item['id'],
                                                            },
                                                          ),
                                                    ),
                                                  );

                                              if (result == true) {
                                                fetchHolidayHomework();
                                              }
                                            },

                                            icon: const Icon(
                                              Icons.edit_rounded,
                                              size: 20,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
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
          ),
        ],
      ),
    );
  }
}
