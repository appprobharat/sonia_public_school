import 'package:sonia_public_school/homework/holiday/list_holiday_homework.dart';
// import 'package:sonia_public_school/leave/list_leaveApproval.dart';
import 'package:sonia_public_school/teacher/geo_attendance_mark.dart';
import 'package:sonia_public_school/teacher/roll_no.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sonia_public_school/api_service.dart';
import 'package:sonia_public_school/login_page.dart';
import 'package:sonia_public_school/alert/stu_alert.dart';
import 'package:sonia_public_school/connect_teacher/teacher_chat_list.dart';
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
import 'package:sonia_public_school/Exam/exam_schedule.dart';

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
  // String selectedSession = "2024-25";

  // List<String> sessionList = ["2022-23", "2023-24", "2024-25"];
  @override
  void initState() {
    super.initState();
    loadTeacherInfo();
  }

  Future<void> loadTeacherInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      teacherName = prefs.getString('teacher_name') ?? '';
      teacherPhoto = prefs.getString('teacher_photo') ?? '';
      teacherClass = prefs.getString('teacher_class') ?? '';
      teacherSection = prefs.getString('teacher_section') ?? '';
    });
  }

  String getPhotoUrl(String photo) {
    if (photo.isEmpty) return '';
    return photo.startsWith('http') ? photo : '${ApiService.Url}/$photo';
  }

  void _navigate(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    try {
      if (token.isNotEmpty) {
        await http.post(
          Uri.parse('${ApiService.Url}/api/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
      }
    } catch (_) {}

    await prefs.clear();
    await prefs.setBool('is_logged_in', false);

    await _secureStorage.deleteAll();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          Container(
            height: 95,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
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
                  color: AppColors.primary.withOpacity(.22),
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
                      color: Colors.white.withOpacity(.05),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: teacherPhoto.isNotEmpty
                                ? NetworkImage(getPhotoUrl(teacherPhoto))
                                : const AssetImage(AppAssets.defaultAvatar)
                                      as ImageProvider,
                          ),
                        ),

                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
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
                              color: Colors.white.withOpacity(.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "👨‍🏫 Teacher",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            teacherName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 2),

                          Text(
                            "$teacherClass • ${teacherSection.isEmpty ? "-" : teacherSection}",
                            style: TextStyle(
                              color: Colors.white.withOpacity(.85),
                              fontSize: 11,
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
          sidebarItem(
            context,
            Icons.dashboard,
            'Dashboard',
            () => _navigate(context, const TeacherDashboardScreen()),
          ),
          sidebarItem(
            context,
            Icons.person,
            'Mark Geo Attd.',
            () => _navigate(context, const GeoAttendanceTeacher()),
          ),
          sidebarItem(
            context,
            Icons.format_list_numbered,
            'Update Roll no',
            () => _navigate(context, const UpdateRollNoPage()),
          ),
          // sidebarItem(
          //   context,
          //   Icons.leave_bags_at_home_rounded,
          //   'Approve Leave',
          //   () => _navigate(context, const LeaveApprovalListPage()),
          // ),
          sidebarItem(
            context,
            Icons.person,
            'Profile',
            () => _navigate(context, const TeacherProfilePage()),
          ),
          sidebarItem(
            context,
            Icons.playlist_add_check_circle,
            'Mark Attendance',
            () => _navigate(context, MarkAttendancePage()),
          ),
          sidebarItem(
            context,
            Icons.add_chart,
            'Attendance Report',
            () => _navigate(context, const AttendanceScreen()),
          ),
          sidebarItem(
            context,
            Icons.book,
            'Homeworks',
            () => _navigate(context, const TeacherHomeworkPage()),
          ),
          sidebarItem(
            context,
            Icons.collections_bookmark,
            'Holiday-Homeworks',
            () => _navigate(context, const ListHolidayHomework()),
          ),
          sidebarItem(
            context,
            Icons.add_alert,
            'Student Alert',
            () => _navigate(context, StudentAlertPage()),
          ),
          sidebarItem(
            context,
            Icons.assignment,
            'Assign Marks',
            () => _navigate(context, const AssignMarksPage()),
          ),
          sidebarItem(
            context,
            Icons.book_sharp,
            'Syllabus',
            () => _navigate(context, const SyllabusPage()),
          ),
          sidebarItem(
            context,
            Icons.receipt,
            'Exam Schedule',
            () => _navigate(context, const ExamSchedulePage()),
          ),
          sidebarItem(
            context,
            Icons.star,
            'Assign Skills',
            () => _navigate(context, const AssignSkillsPage()),
          ),
          sidebarItem(
            context,
            Icons.list_alt,
            'Result',
            () => _navigate(context, const ResultCardPage()),
          ),
          sidebarItem(
            context,
            Icons.schedule,
            'Timetable',
            () => _navigate(context, const TeacherTimeTablePage()),
          ),
          sidebarItem(
            context,
            Icons.report,
            'Complaint',
            () => _navigate(context, const TeacherComplaintListPage()),
          ),
          sidebarItem(
            context,
            Icons.payment,
            'Payments',
            () => _navigate(context, const PaymentTeacherScreen()),
          ),
          sidebarItem(
            context,
            Icons.calendar_month,
            'My Attendance',
            () => _navigate(context, const TeacherAttendanceScreen()),
          ),
          sidebarItem(
            context,
            Icons.school,
            'School Info',
            () => _navigate(context, SchoolInfoPage()),
          ),
          sidebarItem(
            context,
            Icons.message,
            'Chat With Students',
            () => _navigate(context, const TeacherChatStudentListPage()),
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Logout"),
                  content: const Text("Are you sure you want to logout?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _logout(context);
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
    );
  }

  Widget sidebarItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    final colors = {
      "Dashboard": Colors.indigo,
      "Profile": Colors.deepPurple,
      "Update Roll no": Colors.blue,
      // "Approve Leave": Colors.orange,
      "Mark Attendance": Colors.green,
      "Attendance Report": Colors.teal,
      "Homeworks": Colors.amber,
      "Student Alert": Colors.red,
      "Assign Marks": Colors.purple,
      "Syllabus": Colors.cyan,
      "Exam Schedule": Colors.deepOrange,
      "Assign Skills": Colors.pink,
      "Result": Colors.lightBlue,
      "Timetable": Colors.indigo,
      "Complaint": Colors.red,
      "Payments": Colors.green,
      "My Attendance": Colors.blueGrey,
      "School Info": Colors.brown,
      "Chat With Students": Colors.blue,
    };
    final Color iconColor = colors[title] ?? AppColors.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon(icon, size: 20, color: iconColor),
          title: Text(title, style: const TextStyle(fontSize: 14)),
          visualDensity: const VisualDensity(vertical: -3),
          dense: true,
          onTap: onTap,
          trailing: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 15,
            color: Colors.grey,
          ),
        ),

        // 👇 thin divider
        const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16),
      ],
    );
  }
}
