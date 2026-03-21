import 'package:sonia_public_school/api_service.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class UpcomingBirthdayWidget extends StatelessWidget {
  final List birthdays;

  const UpcomingBirthdayWidget({super.key, required this.birthdays});

  @override
  Widget build(BuildContext context) {
    if (birthdays.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(child: Text("No Upcoming Birthdays")),
      );
    }

    return Card(
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            const Row(
              children: [
                Icon(Icons.cake_outlined, color: Colors.pink, size: 20),
                SizedBox(width: 6),
                Text(
                  "Upcoming Birthday",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// STUDENT LIST
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: birthdays.length,
              itemBuilder: (context, index) {
                final student = birthdays[index];

                final rawDob = student["dob"] ?? "";

                DateTime dob;

                try {
                  dob = DateFormat("dd-MM-yyyy").parse(rawDob);
                } catch (e) {
                  dob = DateTime.now();
                }

                final formattedDate = DateFormat("d MMM").format(dob);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _birthdayTile(
                    name: student["name"] ?? "",
                    date: formattedDate,
                    studentClass: student["class"] ?? "",
                    section: student["section"] ?? "",
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _birthdayTile({
    required String name,
    required String date,
    required String studentClass,
    required String section,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          /// Avatar
          const CircleAvatar(
            radius: 20,
            backgroundColor: Colors.pinkAccent,
            child: Icon(Icons.person, color: Colors.white),
          ),

          const SizedBox(width: 10),

          /// Student Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Name
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 2),

                /// Class + Section
                Text(
                  "Class: $studentClass - $section",
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),

          /// Date
          Text(
            date,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.pink,
            ),
          ),
        ],
      ),
    );
  }
}

class CircleGraphWidget extends StatelessWidget {
  final int maleCount;
  final int femaleCount;

  const CircleGraphWidget({
    super.key,
    required this.maleCount,
    required this.femaleCount,
  });

  int get total => maleCount + femaleCount;
  double get malePercent => total == 0 ? 0 : (maleCount / total) * 100;
  double get femalePercent => total == 0 ? 0 : (femaleCount / total) * 100;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Card(
        color: Colors.white,
        elevation: 3,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            children: [
              /// TITLE
              Row(
                children: [
                  Icon(
                    Icons.pie_chart_outline,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "Student Graph",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// GRAPH
              SizedBox(
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        centerSpaceRadius: 55,
                        sectionsSpace: 0,
                        sections: _pieSections(),
                      ),
                    ),

                    /// CENTER TOTAL
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "$total",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "Students",
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              /// LEGEND WITH COUNT + %
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _legendItem(Colors.blue, "Male", maleCount, malePercent),
                  _legendItem(Colors.red, "Female", femaleCount, femalePercent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _pieSections() {
    return [
      PieChartSectionData(
        color: Colors.blue,
        value: malePercent,
        showTitle: false,
        radius: 40,
      ),
      PieChartSectionData(
        color: Colors.red,
        value: femalePercent,
        showTitle: false,
        radius: 40,
      ),
    ];
  }

  Widget _legendItem(Color color, String text, int count, double percent) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Text(
              "$count (${percent.toStringAsFixed(1)}%)",
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}
