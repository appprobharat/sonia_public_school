import 'dart:convert';
import 'package:sonia_public_school/api_service.dart';
import 'package:flutter/material.dart';

class AllDuePage extends StatefulWidget {
  const AllDuePage({super.key});

  @override
  State<AllDuePage> createState() => _AllDuePageState();
}

class _AllDuePageState extends State<AllDuePage> {
  List<dynamic> dueList = [];
  bool isLoading = false;

  late DateTime selectedMonth;

  @override
  void initState() {
    super.initState();
    selectedMonth = DateTime.now();
    fetchAllDue();
  }

  String get formattedMonth {
    return "${selectedMonth.year}-${selectedMonth.month.toString().padLeft(2, '0')}";
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

  Future<void> fetchAllDue() async {
    setState(() => isLoading = true);

    final response = await ApiService.post(
      context,
      "/admin/all_due",
      body: {"month": formattedMonth},
    );

    if (response != null && response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        dueList = data;
      });
    }

    setState(() => isLoading = false);
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
      backgroundColor: const Color(0xffF6F1FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: BackButton(),
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          'All Due',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          /// 🔹 MONTH PICKER CARD
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

          /// 🔹 LIST
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: dueList.length,
                    itemBuilder: (context, index) {
                      final item = dueList[index];
                      return AllDueCard(
                        className: item['class'],
                        section: item['section'],
                        totalStudent: item['students'] ?? 0,
                        opening: (item['opening'] as num).toDouble(),
                        credit: (item['credit'] as num).toDouble(),
                        debit: (item['debit'] as num).toDouble(),
                        due: (item['balance'] as num).toDouble(),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class AllDueCard extends StatelessWidget {
  final String className;
  final String section;
  final int totalStudent;
  final double opening;
  final double credit;
  final double debit;
  final double due;

  const AllDueCard({
    super.key,
    required this.className,
    required this.section,
    required this.totalStudent,
    required this.opening,
    required this.credit,
    required this.debit,
    required this.due,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 3),
        ],
      ),
      child: Column(
        children: [
          /// HEADER
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  "$className / $section",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.people_outline, size: 13, color: AppColors.primary),
              const SizedBox(width: 3),
              Text("$totalStudent", style: const TextStyle(fontSize: 10)),
            ],
          ),

          const SizedBox(height: 8),

          /// TABLE CONTAINER (Light Background)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                /// LABEL ROW
                Row(
                  children: [
                    Expanded(
                      child: _TableHeading(
                        icon: Icons.account_balance_wallet_outlined,
                        text: "Opening",
                      ),
                    ),
                    Expanded(
                      child: _TableHeading(
                        icon: Icons.arrow_downward,
                        text: "Credit",
                      ),
                    ),
                    Expanded(
                      child: _TableHeading(
                        icon: Icons.arrow_upward,
                        text: "Debit",
                      ),
                    ),
                    Expanded(
                      child: _TableHeading(
                        icon: Icons.warning_amber_rounded,
                        text: "Due",
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                /// VALUE ROW
                Row(
                  children: [
                    Expanded(child: _TableValue(opening, Colors.black87)),
                    Expanded(child: _TableValue(credit, Colors.green)),
                    Expanded(child: _TableValue(debit, Colors.orange)),
                    Expanded(child: _TableValue(due, Colors.red, isBold: true)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _TableHeading({required IconData icon, required String text}) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.primary),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _TableValue(double value, Color color, {bool isBold = false}) {
    return Center(
      child: Text(
        "₹ ${value.toStringAsFixed(0)}",
        style: TextStyle(
          fontSize: isBold ? 11 : 10,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
