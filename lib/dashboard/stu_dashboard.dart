// import 'dart:convert';
// import 'dart:io';
// import 'package:sonia_public_school/dashboard/dashboard_screen.dart';
// import 'package:sonia_public_school/profile_page.dart';
// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:open_file/open_file.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:sonia_public_school/Attendance_UI/stu_attendance_report.dart';
// import 'package:sonia_public_school/Exam/exam_schedule.dart';
// import 'package:sonia_public_school/Exam/stu_result.dart';
// import 'package:sonia_public_school/api_service.dart';
// import 'package:sonia_public_school/complaint/view_complaints_page.dart';
// import 'package:sonia_public_school/connect_teacher/connect_with_us.dart';
// import 'package:sonia_public_school/dashboard/calendar.dart';
// import 'package:sonia_public_school/dashboard/timetable_page.dart';
// import 'package:sonia_public_school/payment/payment_page.dart';
// import 'package:sonia_public_school/school_info_page.dart';
// import 'package:sonia_public_school/subjects_page.dart';
// import 'package:sonia_public_school/syllabus/syllabus.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class StudentDashboard extends StatefulWidget {
//   const StudentDashboard({super.key});

//   @override
//   State<StudentDashboard> createState() => _StudentDashboardState();
// }

// class _StudentDashboardState extends State<StudentDashboard> {
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

//   int fine = 0;
//   int dues = 0;
//   int payments = 0;
//   String lastPaymentDate = '';
//   String status = '';
//   int subjects = 0;
//   String studentName = '';
//   String studentPhoto = '';
//   String studentClass = '';
//   String studentSection = '';
//   String schoolName = '';
//   int _currentIndex = 0;

//   Map<String, dynamic> attendance = {};
//   List<Map<String, dynamic>> homeworks = [];
//   List notices = [];
//   List events = [];
//   List siblings = [];

//   bool loading = true;
//   @override
//   void initState() {
//     super.initState();

//     loadProfileData();
//     fetchDashboardData(context).then((_) {
//       setState(() => loading = false);
//     });
//   }

//   Future<void> loadProfileData() async {
//     final prefs = await SharedPreferences.getInstance();

//     setState(() {
//       studentName = prefs.getString('student_name') ?? '';
//       studentPhoto = prefs.getString('student_photo') ?? '';
//       schoolName = prefs.getString('school_name') ?? '';
//       studentClass = prefs.getString('class_name') ?? '';
//       studentSection = prefs.getString('section') ?? '';
//     });
//   }

//   Future<void> fetchDashboardData(BuildContext context) async {
//     final response = await ApiService.post(context, "/student/dashboard");

//     if (response == null) return;

//     debugPrint("🔵 DASHBOARD STATUS: ${response.statusCode}");
//     debugPrint("🔵 DASHBOARD BODY: ${response.body}");

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       debugPrint("📢 RAW NOTICES: ${data['notices']}");
//       fine = data['fine'] ?? 0;
//       dues = data['dues'] ?? 0;
//       payments = int.tryParse(data['payments'].toString()) ?? 0;

//       final rawDate = data['payment_date'] ?? '';
//       if (rawDate.isNotEmpty) {
//         try {
//           final dateObject = DateTime.parse(rawDate);
//           lastPaymentDate =
//               '${dateObject.day}/${dateObject.month}/${dateObject.year}';
//         } catch (_) {
//           lastPaymentDate = rawDate;
//         }
//       }

//       status = data['today_status'] ?? '';
//       subjects = data['subjects'] ?? 0;

//       attendance = {
//         'present': data['attendances']?['present'] ?? 0,
//         'absent': data['attendances']?['absent'] ?? 0,
//         'leave': data['attendances']?['leave'] ?? 0,
//         'half_day': data['attendances']?['half_day'] ?? 0,
//         'working_days': data['attendances']?['working_days'] ?? 0,
//       };

//       homeworks = List<Map<String, dynamic>>.from(data['homeworks'] ?? []);
//       notices = data['notices'] ?? [];
//       events = data['events'] ?? [];
//       siblings = data['siblings'] ?? [];

//       return;
//     }
//   }

//   // String _formatSchoolName(String name) {
//   //   final parts = name.split(' ');

//   //   if (parts.length <= 2) {
//   //     return name;
//   //   }
//   //   final mid = (parts.length / 2).ceil();
//   //   final firstLine = parts.sublist(0, mid).join(' ');
//   //   final secondLine = parts.sublist(mid).join(' ');

//   //   return '$firstLine\n$secondLine';
//   // }

//   // String _attendanceText() {
//   //   final present = attendance['present'] ?? 0;
//   //   final total = attendance['working_days'] ?? 0;

//   //   if (total == 0) return "N/A";
//   //   return "$present/$total";
//   // }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey,
//       backgroundColor: const Color(0xffF5F7FB),
//       drawer: LeftSidebarMenu(
//         studentName: studentName,
//         studentPhoto: studentPhoto,
//         studentClass: studentClass,
//         studentsection: studentSection,
//       ),

//       // 🔹 TOP PROFILE BAR
//       body: SafeArea(
//         child: Stack(
//           children: [
//             _HomeBody(
//               loading: loading,
//               studentName: studentName,
//               studentPhoto: studentPhoto,
//               studentClass: studentClass,
//               studentSection: studentSection,
//               schoolName: schoolName,
//               dues: dues,
//               fine: fine,
//               status: status,
//               attendance: attendance,
//               homeworks: homeworks,
//             ),

//             if (loading)
//               const Center(
//                 child: CircularProgressIndicator(color: AppColors.primary),
//               ),
//           ],
//         ),
//       ),

//       // ================= BOTTOM NAV =================
//       bottomNavigationBar: BottomNavigationBar(
//         type: BottomNavigationBarType.fixed,
//         currentIndex: _currentIndex,
//         selectedItemColor: AppColors.primary,
//         unselectedItemColor: Colors.grey,
//         onTap: (index) {
//           setState(() {
//             _currentIndex = index;
//           });

//           switch (index) {
//             case 0:
//               break;

//             case 1:
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => const ConnectWithUsPage(
//                     teacherId: 0,
//                     teacherName: '',
//                     teacherPhoto: '',
//                   ),
//                 ),
//               );
//               break;

//             case 2:
//               // Profile
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => ProfilePage()),
//               );

//               break;

//             case 3:
//               _scaffoldKey.currentState?.openDrawer();
//               break;
//           }
//         },
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
//           BottomNavigationBarItem(icon: Icon(Icons.chat), label: "chat"),
//           BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
//           BottomNavigationBarItem(icon: Icon(Icons.menu), label: "Menu"),
//         ],
//       ),
//     );
//   }
// }

// class _TopCard extends StatelessWidget {
//   final String title;
//   final String value;
//   final String subtitle;
//   final Color color;
//   final IconData icon;

//   const _TopCard({
//     required this.title,
//     required this.value,
//     required this.subtitle,
//     required this.color,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 54, // 🔥 minimum practical height
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//       decoration: BoxDecoration(
//         color: color,
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: [
//           BoxShadow(
//             color: color.withOpacity(0.35),
//             blurRadius: 6,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           // ROW 1: ICON + TITLE
//           Row(
//             children: [
//               Container(
//                 width: 22,
//                 height: 22,
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.28),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(icon, color: Colors.white, size: 13),
//               ),
//               const SizedBox(width: 6),
//               Expanded(
//                 child: Text(
//                   title,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 11,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           // DIVIDER LINE
//           Container(
//             height: 1,
//             width: double.infinity,
//             color: Colors.white.withOpacity(0.25),
//           ),

//           const SizedBox(height: 4),

//           // ROW 2: SUBTITLE + VALUE
//           Row(
//             children: [
//               if (subtitle.isNotEmpty)
//                 Text(
//                   subtitle,
//                   style: const TextStyle(color: Colors.white70, fontSize: 9.5),
//                 ),
//               Flexible(
//                 child: Text(
//                   value,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 10.5,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _QuickItem extends StatelessWidget {
//   final String title;
//   final IconData icon;
//   final Color color;

//   const _QuickItem(this.title, this.icon, this.color);
//   void _openPage(BuildContext context, String title) {
//     switch (title) {
//       case "Subjects":
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => SubjectsPage()),
//         );
//         break;

//       case "Time Table":
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => const TimeTablePage()),
//         );
//         break;

//       case "Calendar":
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => const StudentCalendarPage()),
//         );
//         break;

//       case "Syllabus":
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => const SyllabusPage()),
//         );
//         break;

//       case "Exam":
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => const ExamSchedulePage()),
//         );
//         break;

//       case "Payment":
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => const PaymentPage()),
//         );
//         break;

//       case "School Info":
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => SchoolInfoPage()),
//         );
//         break;

//       case "Notice":
//         // Navigator.push(
//         //   context,
//         //   MaterialPageRoute(builder: (_) => const NoticePage()),
//         // );
//         break;

//       case "Attendance":
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => StudentAttendanceScreen()),
//         );
//         break;

//       case "Result":
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => StudentResultPage()),
//         );
//         break;

//       case "Complaint":
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => const ViewComplaintPage()),
//         );
//         break;

//       case "Chat":
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => const ConnectWithUsPage(
//               teacherId: 0,
//               teacherName: '',
//               teacherPhoto: '',
//             ),
//           ),
//         );
//         break;

//       default:
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text("$title page coming soon")));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(14),
//       onTap: () {
//         _openPage(context, title); // 🔥 yahin navigation hoga
//       },
//       child: Container(
//         height: 80,
//         decoration: BoxDecoration(
//           color: color,
//           borderRadius: BorderRadius.circular(14),
//           boxShadow: [
//             BoxShadow(
//               color: color.withOpacity(0.30),
//               blurRadius: 8,
//               offset: const Offset(0, 3),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, color: Colors.white, size: 26),
//             const SizedBox(height: 8),
//             Text(
//               title,
//               maxLines: 2,
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 11,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _HomeBody extends StatelessWidget {
//   final bool loading;
//   final String studentName;
//   final String studentPhoto;
//   final String studentClass;
//   final String studentSection;
//   final String schoolName;
//   final int dues;
//   final int fine;
//   final String status;
//   final Map<String, dynamic> attendance;
//   final List<Map<String, dynamic>> homeworks;

//   const _HomeBody({
//     required this.loading,
//     required this.studentName,
//     required this.studentPhoto,
//     required this.studentClass,
//     required this.studentSection,
//     required this.schoolName,
//     required this.dues,
//     required this.fine,
//     required this.status,
//     required this.attendance,
//     required this.homeworks,
//   });

//   String _attendanceText() {
//     final present = attendance['present'] ?? 0;
//     final total = attendance['working_days'] ?? 0;
//     if (total == 0) return "N/A";
//     return "$present/$total";
//   }

//   String _formatSchoolName(String name) {
//     final parts = name.split(' ');
//     if (parts.length <= 2) return name;

//     final mid = (parts.length / 2).ceil();
//     return '${parts.sublist(0, mid).join(' ')}\n'
//         '${parts.sublist(mid).join(' ')}';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           // ================= HEADER =================
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(16),
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [AppColors.primary, AppColors.primary],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: BorderRadius.only(
//                 bottomLeft: Radius.circular(22),
//                 bottomRight: Radius.circular(22),
//               ),
//             ),
//             child: Row(
//               children: [
//                 CircleAvatar(
//                   radius: 28,
//                   backgroundImage: studentPhoto.isNotEmpty
//                       ? NetworkImage(studentPhoto)
//                       : const AssetImage("assets/images/logo.png")
//                             as ImageProvider,
//                 ),

//                 const SizedBox(width: 14),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       studentName.isNotEmpty ? studentName : "Student",
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),

//                     Text(
//                       "$studentClass - Section $studentSection",
//                       style: const TextStyle(
//                         color: Colors.white70,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const Spacer(),
//                 Column(
//                   children: [
//                     Icon(Icons.menu_book, color: Colors.white, size: 30),
//                     SizedBox(height: 4),
//                     Text(
//                       schoolName.isNotEmpty
//                           ? _formatSchoolName(schoolName)
//                           : "School",
//                       textAlign: TextAlign.center,
//                       maxLines: 2,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 05),

//           // ================= TOP STATUS CARDS =================
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: _TopCard(
//                     title: "Due Fee",
//                     subtitle: "Pending: ",
//                     value: "₹$dues",
//                     color: dues > 0
//                         ? const Color(0xFFEF4444)
//                         : const Color(0xFF22C55E),
//                     icon: Icons.currency_rupee,
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: _TopCard(
//                     title: "Late Pay",
//                     subtitle: "",
//                     value: fine > 0 ? "₹$fine Fine" : "No Fine",
//                     color: fine > 0
//                         ? const Color(0xFFF97316)
//                         : const Color(0xFF22C55E),
//                     icon: Icons.access_time,
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: _TopCard(
//                     title: "Today Attendance",
//                     subtitle: "",
//                     value: _attendanceText(),
//                     color: status == "Present"
//                         ? const Color(0xFF22C55E)
//                         : const Color(0xFFEF4444),
//                     icon: Icons.check_circle,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Text(
//                   "Quick Links",
//                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
//                 ),
//               ],
//             ),
//           ),

//           // ================= QUICK LINKS GRID =================
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: GridView.count(
//               crossAxisCount: 4,
//               childAspectRatio: 0.95,
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               mainAxisSpacing: 16,
//               crossAxisSpacing: 16,
//               children: const [
//                 _QuickItem("Subjects", Icons.menu_book, Color(0xff42A5F5)),
//                 _QuickItem("Time Table", Icons.access_time, Color(0xff7E57C2)),
//                 _QuickItem("Calendar", Icons.calendar_month, Color(0xff66BB6A)),
//                 _QuickItem("Syllabus", Icons.edit, Color(0xff26A69A)),

//                 _QuickItem("Exam", Icons.assignment, Color(0xffFFA726)),
//                 _QuickItem("Payment", Icons.currency_rupee, Color(0xffEF5350)),
//                 _QuickItem("School Info", Icons.home, Color(0xff5C6BC0)),
//                 _QuickItem("Notice", Icons.campaign, Color(0xffEC407A)),

//                 _QuickItem("Attendance", Icons.celebration, Color(0xffFFB300)),
//                 _QuickItem("Result", Icons.star, Color(0xffAB47BC)),
//                 _QuickItem(
//                   "Complaint",
//                   Icons.report_problem,
//                   Color(0xffFB8C00),
//                 ),
//                 _QuickItem("Chat", Icons.chat, Color(0xff43A047)),
//               ],
//             ),
//           ),

//           const SizedBox(height: 28),

//           // ================= HOMEWORK SECTION =================
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(14),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.06),
//                     blurRadius: 10,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // 🔹 HEADER ROW
//                   Row(
//                     children: const [
//                       Icon(Icons.assignment, color: AppColors.primary),
//                       SizedBox(width: 8),
//                       Text(
//                         "Homework",
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 12),
//                   Divider(color: Colors.grey.shade300),
//                   const SizedBox(height: 8),

//                   // 🔹 CONTENT
//                   if (homeworks.isEmpty)
//                     const Padding(
//                       padding: EdgeInsets.symmetric(vertical: 12),
//                       child: Center(
//                         child: Text(
//                           "No homework assigned",
//                           style: TextStyle(color: Colors.grey),
//                         ),
//                       ),
//                     )
//                   else
//                     Column(
//                       children: List.generate(homeworks.length, (i) {
//                         final hw = homeworks[i];

//                         return Padding(
//                           padding: const EdgeInsets.only(bottom: 10),
//                           child: _HomeworkCard(
//                             work: hw['HomeworkTitle'] ?? '',
//                             date: hw['WorkDate'] ?? '',
//                             attachment: hw['Attachment'],
//                           ),
//                         );
//                       }),
//                     ),
//                 ],
//               ),
//             ),
//           ),

//           const SizedBox(height: 80),
//         ],
//       ),
//     );
//   }
// }

// class _HomeworkCard extends StatefulWidget {
//   final String work;
//   final String date;
//   final String attachment;

//   const _HomeworkCard({
//     required this.work,
//     required this.date,
//     required this.attachment,
//   });

//   @override
//   State<_HomeworkCard> createState() => _HomeworkCardState();
// }

// bool _isDownloading = false;

// class _HomeworkCardState extends State<_HomeworkCard> {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 6,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.book, color: Colors.blue.shade700),
//           const SizedBox(width: 12),

//           // LEFT CONTENT
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   widget.work,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   "Due: ${widget.date}",
//                   style: const TextStyle(fontSize: 12, color: Colors.grey),
//                 ),
//               ],
//             ),
//           ),

//           // 🔥 RIGHT DOWNLOAD ICON (ONLY IF ATTACHMENT EXISTS)
//           if (widget.attachment.isNotEmpty)
//             InkWell(
//               onTap: () {
//                 _downloadAttachment(context, widget.attachment);
//               },
//               child: Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Colors.blue.withOpacity(0.12),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.download_rounded,
//                   color: Colors.blue,
//                   size: 22,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   // 🔹 DOWNLOAD FUNCTION
//   Future<void> _downloadAttachment(
//     BuildContext context,
//     String filePath,
//   ) async {
//     if (_isDownloading) return;
//     _isDownloading = true;

//     // ✅ URL now comes from ApiService
//     final fullUrl = filePath.startsWith('http')
//         ? filePath
//         : ApiService.homeworkAttachment(filePath);

//     try {
//       final fileName = fullUrl.split('/').last;
//       final dio = Dio();
//       late String savePath;

//       // ================= ANDROID =================
//       if (Platform.isAndroid) {
//         final downloadsDir = Directory('/storage/emulated/0/Download');
//         savePath = '${downloadsDir.path}/$fileName';

//         await dio.download(fullUrl, savePath);

//         // ✅ Preview open
//         await OpenFile.open(savePath);

//         if (context.mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("📥 Downloaded & Preview opened")),
//           );
//         }
//       }

//       // ================= iOS =================
//       if (Platform.isIOS) {
//         final dir = await getApplicationDocumentsDirectory();
//         savePath = '${dir.path}/$fileName';

//         await dio.download(fullUrl, savePath);

//         // ✅ Preview open
//         await OpenFile.open(savePath);
//       }
//     } catch (e) {
//       if (context.mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(const SnackBar(content: Text("❌ Download failed")));
//       }
//     } finally {
//       _isDownloading = false;
//     }
//   }
// }
