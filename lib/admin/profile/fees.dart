import 'dart:convert';

import 'package:sonia_public_school/api_service.dart';
import 'package:flutter/material.dart';

class ClassFeesModel {
  final String className;
  final String section;
  final int totalStudents;
  final double totalFees;
  final double collectedFees;
  final double pendingFees;

  ClassFeesModel({
    required this.className,
    required this.section,
    required this.totalStudents,
    required this.totalFees,
    required this.collectedFees,
    required this.pendingFees,
  });
}

class AdminFeesPage extends StatefulWidget {
  const AdminFeesPage({super.key});

  @override
  State<AdminFeesPage> createState() => _AdminFeesPageState();
}

class _AdminFeesPageState extends State<AdminFeesPage> {
  /// Dummy data (replace with API later)
  List<ClassFeesModel> list = [];
  bool isLoading = true;
  late DateTime selectedMonth;
  @override
  void initState() {
    super.initState();
    selectedMonth = DateTime.now();
    fetchAllDue();
  }

  Future<void> fetchAllDue() async {
    setState(() => isLoading = true);

    final month =
        "${selectedMonth.year}-${selectedMonth.month.toString().padLeft(2, '0')}";

    final res = await ApiService.post(
      context,
      "/admin/all_due",
      body: {"month": month},
    );

    if (res != null && res.statusCode == 200) {
      final List data = jsonDecode(res.body);

      list = data.map<ClassFeesModel>((e) {
        return ClassFeesModel(
          className: e["class"] ?? "",
          section: e["section"] ?? "",
          totalStudents: e["students"] ?? 0,
          totalFees: (e["credit"] ?? 0).toDouble(),
          collectedFees: (e["debit"] ?? 0).toDouble(),
          pendingFees: (e["balance"] ?? 0).toDouble(),
        );
      }).toList();
    } else {
      list = [];
    }

    setState(() => isLoading = false);
  }

  Widget _statTile(IconData icon, String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(ClassFeesModel e) {
    double percent = 0.0;

    if (e.totalFees > 0) {
      percent = e.collectedFees / e.totalFees;
      if (percent < 0) percent = 0;
      if (percent > 1) percent = 1;
    }

    final percentText = (percent * 100).toStringAsFixed(0);
    Color performanceColor;

    if (e.totalFees == 0) {
      performanceColor = Colors.grey;
    } else if (percent >= 0.8) {
      performanceColor = Colors.green;
    } else if (percent >= 0.5) {
      performanceColor = Colors.orange;
    } else {
      performanceColor = Colors.red;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ===== GRADIENT HEADER =====
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [performanceColor.withOpacity(.15), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: performanceColor.withOpacity(.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.school, color: performanceColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "${e.className} - ${e.section}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: performanceColor.withOpacity(.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$percentText%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: performanceColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                /// ===== TOTAL ROW =====
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total Fees",
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      "₹${e.totalFees.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                /// ===== PROGRESS =====
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: percent),
                        duration: const Duration(milliseconds: 600),
                        builder: (context, value, _) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: value,
                              minHeight: 18,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                performanceColor,
                              ),
                            ),
                          );
                        },
                      ),
                      Text(
                        "${(percent * 100).toStringAsFixed(0)}%",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                /// ===== STATS =====
                Row(
                  children: [
                    _statTile(
                      Icons.people,
                      "Students",
                      e.totalStudents.toString(),
                      Colors.blue,
                    ),
                    const SizedBox(width: 6),
                    _statTile(
                      Icons.check_circle,
                      "Collected",
                      "₹${e.collectedFees.toStringAsFixed(0)}",
                      Colors.green,
                    ),
                    const SizedBox(width: 6),
                    _statTile(
                      Icons.pending,
                      "Pending",
                      "₹${e.pendingFees.toStringAsFixed(0)}",
                      Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month - 1];
  }

  Future<void> pickMonth() async {
    int tempYear = selectedMonth.year;
    int tempMonth = selectedMonth.month;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text(
                "Select Month & Year",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 260,
                child: Column(
                  children: [
                    /// YEAR DROPDOWN
                    DropdownButton<int>(
                      value: tempYear,
                      isExpanded: true,
                      items: List.generate(20, (index) {
                        int year = DateTime.now().year - 10 + index;
                        return DropdownMenuItem(
                          value: year,
                          child: Text(year.toString()),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() {
                            tempYear = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 10),

                    /// MONTH GRID
                    Expanded(
                      child: GridView.builder(
                        itemCount: 12,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 2.4,
                            ),
                        itemBuilder: (context, index) {
                          int month = index + 1;

                          bool isSelected =
                              month == tempMonth &&
                              tempYear == selectedMonth.year;

                          return InkWell(
                            onTap: () {
                              tempMonth = month;

                              setState(() {
                                selectedMonth = DateTime(tempYear, tempMonth);
                              });

                              Navigator.pop(context);
                              fetchAllDue();
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _monthName(month),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: GestureDetector(
                    onTap: pickMonth,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${selectedMonth.month.toString().padLeft(2, '0')}-${selectedMonth.year}",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.keyboard_arrow_down),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _card(list[i]),
                  ),
                ),
              ],
            ),
    );
  }
}
