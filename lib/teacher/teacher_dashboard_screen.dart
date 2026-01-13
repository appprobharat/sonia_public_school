import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sonia_public_school/api_service.dart';
import 'package:sonia_public_school/main.dart';
import 'package:sonia_public_school/payment/payment_teacher_screen.dart';
import 'package:sonia_public_school/teacher/complaint_teacher/teacher_complaint_list_page.dart';
import 'package:sonia_public_school/teacher/student_list.dart';
import 'package:sonia_public_school/teacher/teacher_recent_homework.dart';
import 'package:sonia_public_school/teacher/teacher_sidebar_menu.dart';

import 'package:pie_chart/pie_chart.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen>
    with RouteAware {
  bool isLoading = true;
  bool isRefreshing = false;

  int students = 0;
  int complaints = 0;
  int payments = 0;

  String schoolName = '';
  String teacherPhoto = '';

  Map<String, dynamic> attendance = {};
  List<Map<String, dynamic>> homeworks = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _refreshDashboard();
  }

  @override
  void initState() {
    super.initState();
    _refreshDashboard(); // first time
  }

  Future<void> _refreshDashboard() async {
    if (!mounted) return;

    if (!isLoading) {
      // back / refresh case
      setState(() => isRefreshing = true);
    }

    await loadTeacherInfo();
    await fetchDashboardData();
    await fetchTeacherHomeworks();

    if (!mounted) return;

    setState(() {
      isLoading = false;
      isRefreshing = false;
    });
  }

  // ---------------- TEACHER INFO ----------------
  Future<void> loadTeacherInfo() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      schoolName = prefs.getString('school_name') ?? '';
      teacherPhoto = prefs.getString('teacher_photo') ?? '';
    });
  }

  // ---------------- DASHBOARD DATA ----------------
  Future<void> fetchDashboardData() async {
    try {
      final response = await ApiService.post(context, '/teacher/dashboard');

      if (response == null) return;

      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        students = data['students'] ?? 0;
        complaints = data['complaints'] ?? 0;
        payments = int.tryParse(data['payments'].toString()) ?? 0;
        attendance = {
          'present': data['attendances']?['present'] ?? 0,
          'absent': data['attendances']?['absent'] ?? 0,
          'leave': data['attendances']?['leave'] ?? 0,
          'half_day': data['attendances']?['half_day'] ?? 0,
          'working_days': data['attendances']?['working_days'] ?? 0,
        };
      });
    } catch (_) {
      // silent
    }
  }

  // ---------------- HOMEWORK ----------------
  Future<void> fetchTeacherHomeworks() async {
    try {
      final response = await ApiService.post(context, '/teacher/homework');

      if (response == null) return;

      final decoded = jsonDecode(response.body);
      if (decoded is List && mounted) {
        setState(() {
          homeworks = List<Map<String, dynamic>>.from(decoded);
        });
      }
    } catch (_) {
      // silent
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: TeacherSidebarMenu(),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: AppColors.primary,
        titleSpacing: 0,
        title: Row(
          children: [
            Expanded(
              child: Text(
                schoolName.isNotEmpty ? schoolName : 'Teacher Dashboard',
                style: const TextStyle(color: Colors.white, fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            teacherPhoto.isNotEmpty
                ? CircleAvatar(
                    backgroundImage: NetworkImage(teacherPhoto),
                    radius: 15,
                  )
                : const CircleAvatar(
                    backgroundImage: AssetImage(AppAssets.logo_new),
                    radius: 15,
                  ),
            const SizedBox(width: 15),
          ],
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              children: [
                if (isRefreshing)
                  const LinearProgressIndicator(
                    minHeight: 3,
                    color: AppColors.primary,
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StudentListPage(),
                                ),
                              ),
                              child: DashboardCard(
                                title: 'Students',
                                value: students.toString(),
                                borderColor: Colors.blue,
                                backgroundColor: const Color(0xFFE3F2FD),
                                textColor: Colors.blue,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PaymentTeacherScreen(),
                                ),
                              ),
                              child: DashboardCard(
                                title: 'Payments',
                                value: payments.toString(),
                                borderColor: Colors.green,
                                backgroundColor: const Color(0xFFE8F5E9),
                                textColor: Colors.green,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TeacherComplaintListPage(),
                                ),
                              ),
                              child: DashboardCard(
                                title: 'Complaints',
                                value: complaints.toString(),
                                borderColor: Colors.red,
                                backgroundColor: const Color(0xFFFFEBEE),
                                textColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        AttendancePieChart(
                          present: attendance['present'] ?? 0,
                          absent: attendance['absent'] ?? 0,
                          leave: attendance['leave'] ?? 0,
                          halfDay: attendance['half_day'] ?? 0,
                          workingDays: attendance['working_days'] ?? 0,
                        ),
                        const SizedBox(height: 20),
                        TeacherRecentHomeworks(homeworks: homeworks),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final Color borderColor;
  final Color backgroundColor;
  final Color textColor;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.borderColor,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 75,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class AttendancePieChart extends StatelessWidget {
  final int present;
  final int absent;
  final int leave;
  final int halfDay;
  final int workingDays;

  const AttendancePieChart({
    super.key,
    required this.present,
    required this.absent,
    required this.leave,
    required this.halfDay,
    required this.workingDays,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    // Base size that looks good on regular screens
    double baseChartRadius = 140;

    // Adjust for very small or very large screens
    double chartRadius = screenWidth < 360
        ? baseChartRadius * 0.85
        : screenWidth > 600
        ? baseChartRadius * 1.2
        : baseChartRadius;

    final Map<String, double> dataMap = {
      "Present": present.toDouble(),
      "Absent": absent.toDouble(),
      "Leave": leave.toDouble(),
      "Half Day": halfDay.toDouble(),
    };

    final List<Color> colorList = [
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.blue,
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: "📊 Today's Attendance ",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PieChart(
            dataMap: dataMap,
            chartType: ChartType.disc,
            chartRadius: chartRadius,
            colorList: colorList,
            chartValuesOptions: const ChartValuesOptions(
              showChartValueBackground: false,
              decimalPlaces: 0,
              showChartValuesInPercentage: false,
              chartValueStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            legendOptions: const LegendOptions(
              legendPosition: LegendPosition.right,
              showLegendsInRow: false,
              legendTextStyle: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
