import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sonia_public_school/Exam/exam_schedule.dart';

import 'package:sonia_public_school/alert/stu_alert.dart';
import 'package:sonia_public_school/connect_teacher/teacher_chat_list.dart';
import 'package:sonia_public_school/login_page.dart';
import 'package:sonia_public_school/payment/payment_teacher_screen.dart';
import 'package:sonia_public_school/school_info_page.dart';
import 'package:sonia_public_school/syllabus/syllabus.dart';
import 'package:sonia_public_school/teacher/AssignMarksPage.dart';
import 'package:sonia_public_school/teacher/AssignSkillsPage.dart';
import 'package:sonia_public_school/teacher/ResultcardPage.dart';
import 'package:sonia_public_school/Attendance_UI/mark_attendance_page.dart';
import 'package:sonia_public_school/teacher/complaint_teacher/teacher_complaint_list_page.dart';
import 'package:sonia_public_school/Attendance_UI/teacher_attendance_screen.dart';
import 'package:sonia_public_school/teacher/teacher_dashboard_screen.dart';
import 'package:sonia_public_school/teacher/teacher_homework_page.dart';
import 'package:sonia_public_school/teacher/teacher_profile_page.dart';
import 'package:sonia_public_school/Attendance_UI/attendance_screen.dart';
import 'package:sonia_public_school/teacher/teacher_timetable.dart';

class TeacherSidebarMenu extends StatefulWidget {
  const TeacherSidebarMenu({super.key});

  @override
  State<TeacherSidebarMenu> createState() => _TeacherSidebarMenuState();
}

class _TeacherSidebarMenuState extends State<TeacherSidebarMenu> {
  String teacherName = '';
  String teacherPhoto = '';
  String teacherClass = '';
  String teacherSection = '';

  @override
  void initState() {
    super.initState();
    loadTeacherInfo();
   
  }

  Future<void> loadTeacherInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      teacherName = prefs.getString('teacher_name') ?? 'name';
      teacherPhoto = prefs.getString('teacher_photo') ?? 'photo';
      teacherClass = prefs.getString('teacher_class') ?? 'class';
      teacherSection = prefs.getString('teacher_section') ?? 'section';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          Container(
            color: Colors.deepPurple,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            height: 130,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage: teacherPhoto.isNotEmpty
                      ? NetworkImage(
                          teacherPhoto.startsWith('http')
                              ? teacherPhoto
                              : 'https://school.edusathi.in/$teacherPhoto',
                        )
                      : const AssetImage('assets/images/logo.png')
                            as ImageProvider,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        teacherName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Class Teacher',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        '$teacherClass - $teacherSection',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          sidebarItem(context, Icons.dashboard, 'Dashboard', () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const TeacherDashboardScreen()),
            );
          }),
          // sidebarItem(context, Icons.person, 'Admin', () {
          //   Navigator.push(
          //     context,
          //     MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
          //   );
          // }),
          sidebarItem(context, Icons.person, 'Profile', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TeacherProfilePage()),
            );
          }),

          sidebarItem(
            context,
            Icons.playlist_add_check_circle_outlined,
            'Mark Attendance',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MarkAttendancePage()),
              );
            },
          ),

          sidebarItem(
            context,
            Icons.add_chart_outlined,
            'Attendance Report',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AttendanceScreen()),
              );
            },
          ),
          sidebarItem(context, Icons.book, 'Homeworks', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TeacherHomeworkPage()),
            );
          }),
          sidebarItem(context, Icons.add_alert, 'Student Alert', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => StudentAlertPage()),
            );
          }),
          sidebarItem(context, Icons.assignment, 'Assign Marks', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AssignMarksPage()),
            );
          }),
          sidebarItem(context, Icons.book_sharp, 'Syllabus', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SyllabusPage()),
            );
          }),
          sidebarItem(
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
          sidebarItem(context, Icons.star_rate, 'Assign Skills', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AssignSkillsPage()),
            );
          }),
          sidebarItem(context, Icons.list_alt, 'Result ', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ResultCardPage()),
            );
          }),
          sidebarItem(context, Icons.schedule, 'Timetable', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TeacherTimeTablePage()),
            );
          }),

          sidebarItem(context, Icons.report, 'Complaint', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TeacherComplaintListPage()),
            );
          }),

          sidebarItem(context, Icons.payment, 'Payments', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PaymentTeacherScreen()),
            );
          }),
          sidebarItem(context, Icons.calendar_month, 'My Attendance', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TeacherAttendanceScreen()),
            );
          }),

          sidebarItem(context, Icons.school, 'School Info', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SchoolInfoPage()),
            );
          }),
          sidebarItem(context, Icons.message, 'Chat With Students', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TeacherChatStudentListPage(),
              ),
            );
          }),
          Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Logout"),
                  content: const Text("Are you sure you want to logout?"),
                  actions: [
                    TextButton(
                      child: const Text("Cancel"),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: const Text("Logout"),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final token = prefs.getString('token') ?? '';

                        final response = await http.post(
                          Uri.parse('https://school.edusathi.in/api/logout'),
                          headers: {
                            'Authorization': 'Bearer $token',
                            'Accept': 'application/json',
                          },
                        );

                        if (response.statusCode == 200) {
                          final data = jsonDecode(response.body);
                          if (data['status'] == true ||
                              data['message'] == 'Logged out') {
                            await prefs.clear();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => LoginPage()),
                              (route) => false,
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Logout failed: ${data['message']}",
                                ),
                              ),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Logout failed. Please try again."),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  ListTile sidebarItem(
    BuildContext context,
    IconData icon,
    String title,

    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      visualDensity: VisualDensity(vertical: -4),
      title: Text(title),
      onTap: onTap,
    );
  }
}
