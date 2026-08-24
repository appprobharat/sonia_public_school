// import 'package:sonia_public_school/bus_tracking/bus_tracking.dart';
import 'package:sonia_public_school/homework/holiday/stu_holiday_homework.dart';
import 'package:sonia_public_school/login_page.dart';
import 'package:flutter/material.dart';
import 'package:sonia_public_school/Exam/exam_schedule.dart';
import 'package:sonia_public_school/Exam/stu_result.dart';
import 'package:sonia_public_school/api_service.dart';
import 'package:sonia_public_school/connect_teacher/connect_with_us.dart';
import 'package:sonia_public_school/dashboard/calendar.dart';
import 'package:sonia_public_school/dashboard/dashboard_screen.dart';
import 'package:sonia_public_school/homework/homework_page.dart';
import 'package:sonia_public_school/dashboard/timetable_page.dart';
import 'package:sonia_public_school/payment/fee_details_page.dart';
import 'package:sonia_public_school/payment/payment_page.dart';
import 'package:sonia_public_school/profile_page.dart';
import 'package:sonia_public_school/school_info_page.dart';
import 'package:sonia_public_school/complaint/view_complaints_page.dart';

import 'package:sonia_public_school/Attendance_UI/stu_attendance_report.dart';
import 'package:sonia_public_school/subjects_page.dart';
import 'package:sonia_public_school/syllabus/syllabus.dart';
// import 'package:sonia_public_school/leave/leave_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeftSidebarMenu extends StatelessWidget {
  final String studentName;
  final String studentPhoto;
  final String studentClass;
  final String studentsection;

  const LeftSidebarMenu({
    super.key,
    required this.studentName,
    required this.studentPhoto,
    required this.studentClass,
    required this.studentsection,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      child: Drawer(
        child: ListView(
          children: [
            Container(
              height: 105,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.info],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -25,
                    right: -20,

                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: -20,
                    left: -20,
                    child: Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.06),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(.15),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey.shade200,
                              child: ClipOval(
                                child: studentPhoto.isNotEmpty
                                    ? Image.network(
                                        studentPhoto,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Image.asset(
                                                AppAssets.defaultAvatar,
                                                width: 48,
                                                height: 48,
                                                fit: BoxFit.cover,
                                              );
                                            },
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;

                                              return Image.asset(
                                                AppAssets.defaultAvatar,
                                                width: 48,
                                                height: 48,
                                                fit: BoxFit.cover,
                                              );
                                            },
                                      )
                                    : Image.asset(
                                        AppAssets.defaultAvatar,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              height: 10,
                              width: 10,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.18),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                "🎓 Student",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              studentName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              "Class $studentClass | Section ${studentsection.isEmpty ? "-" : studentsection}",
                              style: TextStyle(
                                color: Colors.white.withOpacity(.85),
                                fontSize: 12,
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

            sidebarTile(context, Icons.dashboard, 'Dashboard', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DashboardScreen()),
              );
            }),

            sidebarTile(context, Icons.person, 'Profile', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfilePage()),
              );
            }),

            sidebarTile(context, Icons.book, 'Homeworks', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HomeworkPage()),
              );
            }),
            sidebarTile(context, Icons.home_work, 'Holiday-Homeworks', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => StudentHolidayHomeworkPage()),
              );
            }),
            sidebarTile(context, Icons.calendar_month, 'Attendance', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => StudentAttendanceScreen()),
              );
            }),
            sidebarTile(context, Icons.calendar_today, 'Time-Table', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TimeTablePage()),
              );
            }),
            // sidebarTile(context, Icons.bus_alert, 'Bus Tracking', () {
            //   Navigator.push(
            //     context,
            //     MaterialPageRoute(builder: (_) => ParentBusTrackingPage()),
            //   );
            // }),
            sidebarTile(context, Icons.calendar_month, 'Calendar', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => StudentCalendarPage()),
              );
            }),

            sidebarTile(context, Icons.subject, 'Subjects', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SubjectsPage()),
              );
            }),
            sidebarTile(context, Icons.book_sharp, 'Syllabus', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SyllabusPage()),
              );
            }),
            // sidebarTile(context, Icons.leave_bags_at_home, 'Leave', () {
            //   Navigator.push(
            //     context,
            //     MaterialPageRoute(builder: (_) => LeaveListPage()),
            //   );
            // }),
            sidebarTile(
              context,
              Icons.receipt_long_outlined,
              'Exam Schedule',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ExamSchedulePage()),
                );
              },
            ),
            sidebarTile(context, Icons.report, 'Complaint', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ViewComplaintPage()),
              );
            }),
            sidebarTile(context, Icons.attach_money, 'Fees', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FeeDetailsPage()),
              );
            }),
            sidebarTile(context, Icons.payment, 'Payment', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PaymentPage()),
              );
            }),
            sidebarTile(context, Icons.list_alt_outlined, 'Result', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => StudentResultPage()),
              );
            }),
            sidebarTile(context, Icons.school, 'School Info', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SchoolInfoPage()),
              );
            }),

            sidebarTile(context, Icons.support_agent, 'Contact & Support', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConnectWithUsPage(
                    teacherId: 0,
                    teacherName: '',
                    teacherPhoto: '',
                  ),
                ),
              );
            }),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.danger),
              title: const Text(
                'Logout',
                style: TextStyle(color: AppColors.danger),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Logout"),
                    content: const Text("Are you sure you want to logout?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear();
                          if (!context.mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => LoginPage()),
                            (route) => false,
                          );
                        },
                        child: const Text("Logout"),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget sidebarTile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    final Map<String, Color> colors = {
      "Dashboard": const Color(0xff3F51B5),
      "Profile": const Color(0xff8E44AD),
      "Homeworks": const Color(0xffF39C12),
      "Holiday-Homeworks": const Color(0xffFF9800),
      "Attendance": const Color(0xff27AE60),
      "Time-Table": const Color(0xff2196F3),
      "Calendar": const Color(0xff009688),
      "Subjects": const Color(0xffE91E63),
      "Syllabus": const Color(0xff00ACC1),
      // "Leave": const Color(0xffFFB300),
      "Exam Schedule": const Color(0xffFF7043),
      "Complaint": const Color(0xffE53935),
      "Fees": const Color(0xff9C27B0),
      "Payment": const Color(0xff43A047),
      "Result": const Color(0xff03A9F4),
      "School Info": const Color(0xff795548),
      "Contact & Support": const Color(0xff5C6BC0),
    };
    final Color iconColor = colors[title] ?? AppColors.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: ListTile(
            leading: Icon(icon, size: 20, color: iconColor),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: Colors.grey,
            ),
            visualDensity: const VisualDensity(vertical: -3),
            dense: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onTap: onTap,
          ),
        ),

        const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16),
      ],
    );
  }
}
