import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sonia_public_school/Attendance_UI/mark_attendance_page.dart';
import 'package:sonia_public_school/alert/stu_alert.dart';
import 'package:sonia_public_school/api_service.dart';
import 'package:sonia_public_school/homework/teacher_add_homework_page.dart';
import 'package:sonia_public_school/leave/list_leaveApproval.dart';
import 'package:sonia_public_school/main.dart';
import 'package:sonia_public_school/payment/payment_teacher_screen.dart';
import 'package:sonia_public_school/teacher/complaint_teacher/teacher_complaint_list_page.dart';
import 'package:sonia_public_school/teacher/student_list.dart';
import 'package:sonia_public_school/teacher/teacher_recent_homework.dart';
import 'package:sonia_public_school/teacher/teacher_sidebar_menu.dart';

import 'package:pie_chart/pie_chart.dart';
import 'package:sonia_public_school/teacher/teacher_timetable.dart';

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
  List<Map<String, dynamic>> todayPeriods = [];
  int getTodayDayCode() {
    switch (DateTime.now().weekday) {
      case DateTime.monday:
        return 1;
      case DateTime.tuesday:
        return 2;
      case DateTime.wednesday:
        return 3;
      case DateTime.thursday:
        return 4;
      case DateTime.friday:
        return 5;
      case DateTime.saturday:
        return 6;
      default:
        return 1;
    }
  }

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
    await fetchTodayTimetable();

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

  Future<void> fetchTodayTimetable() async {
    try {
      final response = await ApiService.post(
        context,
        '/teacher/timetable',
        body: {'Day': getTodayDayCode()},
      );

      if (response == null) return;

      final decoded = jsonDecode(response.body);

      if (decoded is List && mounted) {
        setState(() {
          todayPeriods = List<Map<String, dynamic>>.from(decoded);
        });
      }
    } catch (_) {}
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
      backgroundColor: const Color(0xFFF4F8FF),
      drawer: TeacherSidebarMenu(),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.appBarGradient),
        ),
        title: Row(
          children: [
            Builder(
              builder: (context) => InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Scaffold.of(context).openDrawer();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.menu, color: Colors.white),
                ),
              ),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Welcome Back 👋",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    schoolName.isEmpty ? "Teacher Dashboard" : schoolName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                backgroundImage: teacherPhoto.isNotEmpty
                    ? NetworkImage(teacherPhoto)
                    : const AssetImage(AppAssets.logo_new) as ImageProvider,
              ),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (isRefreshing) const LinearProgressIndicator(minHeight: 3),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DashboardSummaryCard(
                          students: students,
                          payments: payments,
                          complaints: complaints,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.flash_on_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Quick Actions",
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  QuickAction(
                                    icon: Icons.playlist_add_check,
                                    title: "Attendance",
                                    color: Colors.blue,
                                    page: const MarkAttendancePage(),
                                  ),
                                  QuickAction(
                                    icon: Icons.book,
                                    title: "Homework",
                                    color: Colors.orange,
                                    page: const TeacherAddHomeworkPage(),
                                  ),
                                  QuickAction(
                                    icon: Icons.assignment,
                                    title: "Leave ",
                                    color: Colors.green,
                                    page: const LeaveApprovalListPage(),
                                  ),
                                  QuickAction(
                                    icon: Icons.people,
                                    title: "Students",
                                    color: Colors.purple,
                                    page: const StudentListPage(),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  QuickAction(
                                    icon: Icons.report,
                                    title: "Complaint",
                                    color: Colors.red,
                                    page: TeacherComplaintListPage(),
                                  ),
                                  QuickAction(
                                    icon: Icons.payment,
                                    title: "Payments",
                                    color: Colors.teal,
                                    page: const PaymentTeacherScreen(),
                                  ),
                                  QuickAction(
                                    icon: Icons.schedule,
                                    title: "Timetable",
                                    color: Colors.indigo,
                                    page: const TeacherTimeTablePage(),
                                  ),
                                  QuickAction(
                                    icon: Icons.notification_important,
                                    title: "Alerts",
                                    color: Colors.deepOrange,
                                    page: const StudentAlertPage(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        _buildTodayTimetable(),

                        const SizedBox(height: 14),

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

  Widget _buildTodayTimetable() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 20,
                color: AppColors.primary,
              ),

              const SizedBox(width: 8),

              const Expanded(
                child: Text(
                  "Today's Timetable",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TeacherTimeTablePage(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text("View All"),
              ),
            ],
          ),

          const SizedBox(height: 8),

          if (todayPeriods.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                children: [
                  Icon(Icons.event_available, size: 42, color: Colors.grey),

                  SizedBox(height: 8),

                  Text(
                    "No Classes Scheduled Today",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          else
            ...todayPeriods.take(3).map((e) => _periodTile(e)),
        ],
      ),
    );
  }

  Widget _periodTile(Map<String, dynamic> period) {
    final bool isLunch = period["Slot"] == "2" || period["Period"] == "LUNCH";

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isLunch
                  ? Colors.orange.shade100
                  : AppColors.primary.withOpacity(.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isLunch ? Icons.restaurant : Icons.menu_book,
              size: 20,
              color: isLunch ? Colors.orange : AppColors.primary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLunch ? "Lunch Break" : (period["Subject"] ?? "-"),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 3),

                if (!isLunch)
                  Text(
                    "${period["Class"] ?? ""}"
                    "${period["Section"] != null ? " (${period["Section"]})" : ""}",
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),

                const SizedBox(height: 3),

                Text(
                  "${period["FromTime"]} - ${period["ToTime"]}",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardSummaryCard extends StatelessWidget {
  final int students;
  final int payments;
  final int complaints;

  const DashboardSummaryCard({
    super.key,
    required this.students,
    required this.payments,
    required this.complaints,
  });

  String get greeting {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return "Good Morning";
    } else if (hour < 17) {
      return "Good Afternoon";
    } else {
      return "Good Evening";
    }
  }

  Widget _item({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required Widget page,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),

              const SizedBox(height: 6),

              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat("dd MMM, yyyy").format(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.info],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -35,
            right: -35,
            child: Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.08),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            bottom: -25,
            left: -25,
            child: Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.05),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "$greeting 👋",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            today,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      _item(
                        context: context,
                        icon: Icons.school_rounded,
                        color: Colors.blue,
                        title: "Students",
                        value: students.toString(),
                        page: StudentListPage(),
                      ),

                      Container(
                        height: 48,
                        width: 1,
                        color: Colors.grey.shade300,
                      ),

                      _item(
                        context: context,
                        icon: Icons.payments_rounded,
                        color: Colors.green,
                        title: "Payments",
                        value: payments.toString(),
                        page: const PaymentTeacherScreen(),
                      ),

                      Container(
                        height: 48,
                        width: 1,
                        color: Colors.grey.shade300,
                      ),

                      _item(
                        context: context,
                        icon: Icons.report_problem_rounded,
                        color: Colors.red,
                        title: "Complaints",
                        value: complaints.toString(),
                        page: TeacherComplaintListPage(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget page;

  const QuickAction({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
      child: SizedBox(
        child: Column(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
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
    double baseChartRadius = 120;

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
            chartType: ChartType.ring,
            ringStrokeWidth: 25,
            centerText:
                "${((present + halfDay * .5) / workingDays * 100).toStringAsFixed(0)}%",
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
