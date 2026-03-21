// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:sonia_public_school/Attendance_UI/stu_attendance_page.dart';
// import 'package:sonia_public_school/Exam/exam_schedule.dart';
// import 'package:sonia_public_school/Exam/stu_result.dart';
// import 'package:sonia_public_school/Notification/notification_list.dart';
// import 'package:sonia_public_school/api_service.dart';
// import 'package:sonia_public_school/complaint/view_complaints_page.dart';
// import 'package:sonia_public_school/connect_teacher/connect_with_us.dart';
// import 'package:sonia_public_school/dashboard/calendar.dart';
// import 'package:sonia_public_school/dashboard/dashboard_screen.dart';
// import 'package:sonia_public_school/dashboard/payment_screen.dart';
// import 'package:sonia_public_school/dashboard/timetable_page.dart';
// import 'package:sonia_public_school/homework/homework_page.dart';
// import 'package:sonia_public_school/payment/fee_details_page.dart';
// import 'package:sonia_public_school/payment/payment_page.dart';
// import 'package:sonia_public_school/profile_page.dart';
// import 'package:sonia_public_school/subjects_page.dart';
// import 'package:sonia_public_school/syllabus/syllabus.dart';

// class DashboardNew extends StatefulWidget {
//   DashboardNew({super.key});

//   @override
//   State<DashboardNew> createState() => _DashboardNewState();
// }

// class _DashboardNewState extends State<DashboardNew> {
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

//   int _currentIndex = 0;
//   bool isLoading = true;
//   int fine = 0;
//   int dues = 0;
//   int payments = 0;
//   int subjects = 0;
//   String lastPaymentDate = '';
//   String todayStatus = '';
//   List<dynamic> siblings = [];
//   String studentPhoto = '';
//   String studentName = '';
//   String schoolName = '';
//   String studentClass = '';
//   String studentsection = '';

//   @override
//   void initState() {
//     super.initState();
//     fetchDashboardData();
//   }

//   void _showSiblingPopup(BuildContext context) {
//     if (siblings.isEmpty) {
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text('Siblings'),
//           content: const Text('No siblings available for this student.'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('OK'),
//             ),
//           ],
//         ),
//       );
//       return;
//     }

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: const Row(
//           children: [
//             Icon(Icons.people, color: AppColors.info),
//             SizedBox(width: 8),
//             Text(
//               'Switch Sibling',
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ],
//         ),
//         content: SizedBox(
//           width: double.maxFinite,
//           child: ListView.builder(
//             shrinkWrap: true,
//             itemCount: siblings.length,
//             itemBuilder: (context, index) {
//               final sibling = siblings[index];
//               final photoUrl =
//                   sibling['Photo'] != null &&
//                       sibling['Photo'].toString().isNotEmpty
//                   ? sibling['Photo'].toString()
//                   : ApiService.siblingUrl;

//               final name = sibling['Name'] ?? 'Unknown';
//               final className = sibling['Class'].toString();

//               final studentId = sibling['id'].toString();

//               print('🧠 Sibling Data: $sibling');

//               return Card(
//                 margin: const EdgeInsets.symmetric(vertical: 6),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 elevation: 2,
//                 child: ListTile(
//                   leading: CircleAvatar(
//                     radius: 22,
//                     backgroundColor: Colors.grey.shade200,
//                     child: ClipOval(
//                       child: Image.network(
//                         photoUrl,
//                         width: 44,
//                         height: 44,
//                         fit: BoxFit.cover,
//                         errorBuilder: (context, error, stackTrace) {
//                           return Icon(
//                             Icons.person,
//                             size: 26,
//                             color: Colors.grey,
//                           );
//                         },
//                       ),
//                     ),
//                   ),

//                   title: Text(
//                     name,
//                     style: const TextStyle(fontWeight: FontWeight.w600),
//                   ),
//                   subtitle: Text('Class: $className'),
//                   trailing: const Icon(
//                     Icons.arrow_forward_ios_rounded,
//                     size: 16,
//                   ),
//                   onTap: () {
//                     // 🔹 Show confirmation dialog before switching
//                     showDialog(
//                       context: context,
//                       builder: (BuildContext confirmContext) {
//                         return AlertDialog(
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(15),
//                           ),
//                           title: const Text(
//                             'Confirm Switch',
//                             style: TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           content: Text(
//                             'Are you sure you want to switch to $name?',
//                             style: const TextStyle(fontSize: 15),
//                           ),
//                           actions: [
//                             TextButton(
//                               onPressed: () => Navigator.pop(confirmContext),
//                               child: const Text(
//                                 'Cancel',
//                                 style: TextStyle(color: AppColors.primary),
//                               ),
//                             ),
//                             ElevatedButton.icon(
//                               onPressed: () async {
//                                 Navigator.pop(
//                                   confirmContext,
//                                 ); // close confirm dialog
//                                 Navigator.pop(
//                                   context,
//                                 ); // close sibling list dialog safely
//                                 if (!mounted) return;
//                                 await _shiftLogin(studentId);
//                               },
//                               icon: const Icon(Icons.check_circle, size: 18),
//                               label: const Text('Yes, Switch'),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: AppColors.info,
//                                 foregroundColor: Colors.white,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         );
//                       },
//                     );
//                   },
//                 ),
//               );
//             },
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text(
//               'Close',
//               style: TextStyle(color: AppColors.primary),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _shiftLogin(String studentId) async {
//     if (!mounted) return;
//     try {
//       final response = await ApiService.post(
//         context,
//         "/student/shift_login",
//         body: {'id': studentId},
//       );

//       if (response == null) return;

//       final data = jsonDecode(response.body);

//       if (data['status'] == true) {
//         await ApiService.saveSession(data);

//         if (!mounted) return;

//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => DashboardNew()),
//         );
//       } else {
//         print('❌ Shift login failed: ${data['message']}');
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(data['message'] ?? 'Login failed')),
//         );
//       }
//     } catch (e) {
//       print('🚨 Exception in _shiftLogin: $e');
//       if (!mounted) return;
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Something went wrong')));
//     }
//   }

//   Future<void> fetchDashboardData() async {
//     final response = await ApiService.post(context, "/student/dashboard");

//     if (response == null) return;

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);

//       setState(() {
//         fine = data['fine'] ?? 0;

//         dues = data['dues'] ?? 0;
//         payments = int.tryParse(data['payments'].toString()) ?? 0;
//         subjects = data['subjects'] ?? 0;
//         todayStatus = data['today_status'] ?? '';

//         final rawDate = data['payment_date'] ?? '';
//         if (rawDate.isNotEmpty) {
//           try {
//             final d = DateTime.parse(rawDate);
//             lastPaymentDate = '${d.day}-${d.month}-${d.year}';
//           } catch (_) {
//             lastPaymentDate = rawDate;
//           }
//         }

//         isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey,
//       backgroundColor: const Color(0xffF6F8FC),

//       drawer: LeftSidebarMenu(
//         studentName: studentName,
//         studentPhoto: studentPhoto,
//         studentClass: studentClass,
//         studentsection: studentsection,
//       ),
//       // ================= BODY =================
//       body: isLoading
//           ? const Center(
//               child: CircularProgressIndicator(color: AppColors.primary),
//             )
//           : IndexedStack(
//               index: _currentIndex,
//               children: [
//                 HomePageWrapper(
//                   dues: dues,
//                   fine: fine,
//                   payments: payments,
//                   subjects: subjects,
//                   lastPaymentDate: lastPaymentDate,
//                   todayStatus: todayStatus,
//                   schoolName: schoolName,
//                   studentPhoto: studentPhoto,
//                   studentName: studentName,
//                   studentClass: studentClass,
//                   studentsection: studentsection,
//                   onSiblingTap: () => _showSiblingPopup(context),
//                   onMenuTap: () {
//                     _scaffoldKey.currentState?.openDrawer();
//                   },
//                 ),
//                 SubjectsPageWrapper(),
//                 AttendancePageWrapper(),
//                 ContactPageWrapper(),
//                 ProfilePageWrapper(),
//               ],
//             ),

//       // ================= BOTTOM NAV =================
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _currentIndex,
//         type: BottomNavigationBarType.fixed,
//         selectedItemColor: AppColors.primary,
//         unselectedItemColor: Colors.grey,
//         onTap: (index) {
//           setState(() {
//             _currentIndex = index;
//           });
//         },
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
//           BottomNavigationBarItem(icon: Icon(Icons.school), label: "Academics"),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.check_circle),
//             label: "Attendance",
//           ),
//           BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Contact"),
//           BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
//         ],
//       ),
//     );
//   }
// }

// class SubjectsPageWrapper extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xffF6F8FC),

//       body: SubjectsPage(), // tera existing list UI
//     );
//   }
// }

// class AttendancePageWrapper extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(body: AttendanceAnalyticsPage());
//   }
// }

// class ContactPageWrapper extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: ConnectWithUsPage(teacherId: 0, teacherName: '', teacherPhoto: ''),
//     );
//   }
// }

// class ProfilePageWrapper extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(body: ProfilePage());
//   }
// }

// class HomePageWrapper extends StatelessWidget {
//   final int dues, fine, payments, subjects;
//   final String lastPaymentDate, todayStatus, schoolName, studentPhoto;
//   final String studentName, studentClass, studentsection;
//   final VoidCallback onSiblingTap;
//   final VoidCallback onMenuTap;

//   const HomePageWrapper({
//     super.key,
//     required this.dues,
//     required this.fine,
//     required this.payments,
//     required this.subjects,
//     required this.lastPaymentDate,
//     required this.todayStatus,
//     required this.schoolName,
//     required this.studentPhoto,
//     required this.studentName,
//     required this.studentClass,
//     required this.studentsection,
//     required this.onSiblingTap,
//     required this.onMenuTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xffF6F8FC),
//       appBar: AppBar(
//         iconTheme: const IconThemeData(color: Colors.white),
//         leading: IconButton(
//           icon: const Icon(Icons.menu, color: Colors.white),
//           onPressed: onMenuTap,
//         ),

//         titleSpacing: 0,
//         title: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Expanded(
//               child: Text(
//                 '$schoolName',
//                 style: const TextStyle(color: Colors.white, fontSize: 13),
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//             GestureDetector(
//               child: Icon(Icons.calendar_month_rounded),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => StudentCalendarPage()),
//               ),
//             ),
//             SizedBox(width: 5),
//             GestureDetector(
//               child: Icon(Icons.notifications),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => NotificationListPage()),
//               ),
//             ),
//             SizedBox(width: 5),
//             GestureDetector(
//               onTap: onSiblingTap,
//               child: CircleAvatar(
//                 radius: 15,
//                 backgroundColor: Colors.grey.shade200,
//                 child: ClipOval(
//                   child: Image.network(
//                     studentPhoto,
//                     width: 30,
//                     height: 30,
//                     fit: BoxFit.cover,
//                     errorBuilder: (context, error, stackTrace) {
//                       return Image.asset(
//                         AppAssets.defaultAvatar,
//                         width: 30,
//                         height: 30,
//                         fit: BoxFit.cover,
//                       );
//                     },
//                   ),
//                 ),
//               ),
//             ),

//             const SizedBox(width: 5),
//           ],
//         ),
//         backgroundColor: AppColors.primary,
//       ),
//       body: DashboardHomeBody(
//         dues: dues,
//         fine: fine,
//         payments: payments,
//         subjects: subjects,
//         lastPaymentDate: lastPaymentDate,
//         todayStatus: todayStatus,
//       ),
//     );
//   }
// }

// /// 🔹 DASHBOARD HOME BODY (SCROLLABLE)

// class DashboardHomeBody extends StatefulWidget {
//   final int dues;
//   final int payments;
//   final int subjects;
//   final String lastPaymentDate;
//   final String todayStatus;
//   final int fine;

//   const DashboardHomeBody({
//     super.key,
//     required this.dues,
//     required this.payments,
//     required this.subjects,
//     required this.lastPaymentDate,
//     required this.todayStatus,
//     required this.fine,
//   });

//   @override
//   State<DashboardHomeBody> createState() => _DashboardHomeBodyState();
// }

// class _DashboardHomeBodyState extends State<DashboardHomeBody> {
//   void _showPaymentConfirmationDialog(
//     BuildContext dashboardContext,
//     int dues,
//     int fine,
//   ) {
//     final totalAmount = dues + fine;
//     print('DEBUG: Dialog opened. Total amount: ₹$totalAmount');
//     showDialog(
//       context: dashboardContext,
//       builder: (dialogContext) {
//         return AlertDialog(
//           title: const Text(
//             'Confirm Payment',
//             style: TextStyle(
//               color: AppColors.primary,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildDialogRow(' Fee Amount:', '₹$dues'),
//               _buildDialogRow(' Fine:', '₹$fine', color: Colors.red),
//               const Divider(),
//               _buildDialogRow('Total Payable:', '₹$totalAmount', isTotal: true),
//             ],
//           ),
//           actions: [
//             TextButton(
//               child: const Text(
//                 "Cancel",
//                 style: TextStyle(color: AppColors.primary),
//               ),
//               onPressed: () {
//                 print('DEBUG: Payment cancelled by user from dialog.');
//                 Navigator.pop(dialogContext);
//               },
//             ),
//             TextButton(
//               style: TextButton.styleFrom(
//                 foregroundColor: AppColors.primary,
//                 textStyle: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//               child: const Text("Proceed to Pay"),
//               onPressed: () async {
//                 Navigator.pop(dialogContext);

//                 final totalDues = dues;
//                 final lateFine = fine;
//                 print('DEBUG: Proceed to Pay clicked. Starting API process...');

//                 ScaffoldMessenger.of(dashboardContext).showSnackBar(
//                   const SnackBar(
//                     content: Text('Initializing payment... Please wait.'),
//                   ),
//                 );
//                 print('DEBUG: SnackBar shown. Calling initiatePayment...');

//                 final paymentData = await initiatePayment(
//                   amount: totalDues,
//                   fine: lateFine,
//                 );

//                 if (paymentData != null) {
//                   final paymentUrl = paymentData['payment_url']!;
//                   final refNo = paymentData['ref_no']!;

//                   print('DEBUG: Init Success. RefNo: $refNo, URL received.');

//                   final webViewResult = await Navigator.push(
//                     dashboardContext,
//                     MaterialPageRoute(
//                       builder: (_) => PaymentWebView(
//                         paymentUrl: paymentUrl,
//                         successRedirectUrl: 'flutter://payment-success',
//                         failureRedirectUrl: 'flutter://payment-failure',
//                       ),
//                     ),
//                   );
//                   print(
//                     'DEBUG: WebView closed. Result received: $webViewResult',
//                   );

//                   if (webViewResult == 'PAYMENT_COMPLETE') {
//                     print(
//                       'DEBUG: WebView reports completion. Checking final status...',
//                     );

//                     final finalStatus = await checkPaymentStatus(refNo: refNo);
//                     print('DEBUG: Final Status from API: $finalStatus');

//                     if (finalStatus == 'success') {
//                       ScaffoldMessenger.of(dashboardContext).showSnackBar(
//                         const SnackBar(content: Text('Payment Successful! ✅')),
//                       );
//                       Navigator.pop(dashboardContext, true);

//                       print(
//                         'DEBUG: Dashboard data fetched successfully before popping.',
//                       );
//                       Navigator.pop(dashboardContext, true);
//                     } else if (finalStatus == 'pending') {
//                       ScaffoldMessenger.of(dashboardContext).showSnackBar(
//                         const SnackBar(
//                           content: Text(
//                             'Payment Pending. Check dashboard later.',
//                           ),
//                         ),
//                       );
//                     } else {
//                       ScaffoldMessenger.of(dashboardContext).showSnackBar(
//                         const SnackBar(
//                           content: Text(
//                             'Payment Failed. Status Check Failed/Unknown. ❌',
//                           ),
//                         ),
//                       );
//                     }
//                   } else if (webViewResult == 'PAYMENT_FAILED') {
//                     print('DEBUG: WebView reports failure/cancellation.');
//                     ScaffoldMessenger.of(dashboardContext).showSnackBar(
//                       const SnackBar(
//                         content: Text(
//                           'Payment process failed or was cancelled. ❌',
//                         ),
//                       ),
//                     );
//                   } else {
//                     print(
//                       'DEBUG: Result not PAYMENT_COMPLETE/FAILED. Status check skipped.',
//                     );
//                     ScaffoldMessenger.of(dashboardContext).showSnackBar(
//                       // ✅ dashboardContext
//                       const SnackBar(
//                         content: Text(
//                           'Payment process abandoned. Status not confirmed.',
//                         ),
//                       ),
//                     );
//                   }
//                 } else {
//                   // API Call failed
//                   print('ERROR: initiatePayment failed (paymentData is null).');
//                   ScaffoldMessenger.of(dashboardContext).showSnackBar(
//                     // ✅ dashboardContext
//                     const SnackBar(
//                       content: Text(
//                         'Could not initialize payment. Please try again.',
//                       ),
//                     ),
//                   );
//                 }
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<Map<String, String>?> initiatePayment({
//     required int amount,
//     required int fine,
//   }) async {
//     try {
//       final response = await ApiService.post(
//         context,
//         "/student/payment/initiate",
//         body: {'amount': amount.toString(), 'fine': fine.toString()},
//       );

//       if (response == null) {
//         debugPrint("❌ initiatePayment: response null");
//         return null;
//       }

//       debugPrint("DEBUG: StatusCode → ${response.statusCode}");
//       debugPrint("DEBUG: Body → ${response.body}");

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);

//         if (data.containsKey('payment_url') && data.containsKey('ref_no')) {
//           return {
//             'payment_url': data['payment_url'].toString(),
//             'ref_no': data['ref_no'].toString(),
//           };
//         } else {
//           debugPrint('❌ initiatePayment: payment_url / ref_no missing');
//           return null;
//         }
//       } else {
//         debugPrint('❌ initiatePayment failed → ${response.statusCode}');
//         return null;
//       }
//     } catch (e) {
//       debugPrint("❌ initiatePayment exception: $e");
//       return null;
//     }
//   }

//   Future<String?> checkPaymentStatus({required String refNo}) async {
//     try {
//       final response = await ApiService.get(
//         context,
//         "/student/payment/status/$refNo",
//       );

//       if (response == null) {
//         debugPrint("❌ checkPaymentStatus: response null");
//         return 'error';
//       }

//       debugPrint("DEBUG: StatusCode → ${response.statusCode}");
//       debugPrint("DEBUG: Body → ${response.body}");

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);

//         if (data.containsKey('status')) {
//           return data['status'].toString();
//         } else {
//           debugPrint('❌ status key missing');
//           return 'unknown';
//         }
//       } else {
//         debugPrint('❌ checkPaymentStatus failed → ${response.statusCode}');
//         return 'error';
//       }
//     } catch (e) {
//       debugPrint("❌ checkPaymentStatus exception: $e");
//       return 'error';
//     }
//   }

//   Widget _buildDialogRow(
//     String label,
//     String value, {
//     Color color = Colors.black87,
//     bool isTotal = false,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 2.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: isTotal ? 16 : 14,
//               fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
//               color: isTotal ? AppColors.primary : Colors.grey[700],
//             ),
//           ),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: isTotal ? 16 : 14,
//               fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
//               color: color,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               FeePayCard(
//                 dues: widget.dues,
//                 fine: widget.fine,
//                 onCardTap: () => Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => FeeDetailsPage()),
//                 ),
//                 onPayNowTap: () => _showPaymentConfirmationDialog(
//                   context,
//                   widget.dues,
//                   widget.fine,
//                 ),
//               ),
//               GestureDetector(
//                 child: DashboardCard(
//                   title: 'Last Pay',
//                   value: widget.payments.toString(),

//                   borderColor: AppColors.success,
//                   backgroundColor: AppColors.success.shade50,
//                   textColor: AppColors.success,
//                   date: widget.lastPaymentDate,
//                 ),

//                 onTap: () => Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => PaymentPage()),
//                 ),
//               ),
//               GestureDetector(
//                 child: DashboardCard(
//                   title: 'Subjects',
//                   value: widget.subjects.toString(),

//                   borderColor: AppColors.info,
//                   backgroundColor: AppColors.info.shade50,
//                   textColor: AppColors.info,
//                 ),

//                 onTap: () => Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (_) => SubjectsPage()),
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 10),

//           // -------- Today Attendance ----------
//           Container(
//             padding: const EdgeInsets.all(14),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(14),
//             ),
//             child: Row(
//               children: [
//                 const Icon(Icons.school, color: AppColors.primary),
//                 const SizedBox(width: 10),
//                 const Text("School", style: TextStyle(fontSize: 16)),
//                 const Spacer(),
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 14,
//                     vertical: 6,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade300,
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     widget.todayStatus.isEmpty
//                         ? "Not Marked"
//                         : widget.todayStatus,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 24),

//           const Text(
//             "Quick Links",
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),

//           const SizedBox(height: 16),

//           GridView.count(
//             crossAxisCount: 4,
//             childAspectRatio: 0.78,
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             mainAxisSpacing: 18,
//             crossAxisSpacing: 20,
//             children: [
//               DashboardItem(
//                 Icons.menu_book,
//                 "Homeworks",
//                 color: Colors.blue,
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => HomeworkPage()),
//                   );
//                 },
//               ),

//               DashboardItem(
//                 Icons.library_books,
//                 "Syllabus",
//                 color: Colors.deepPurple,
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => SyllabusPage()),
//                   );
//                 },
//               ),

//               DashboardItem(
//                 Icons.bar_chart,
//                 "Results",
//                 color: Colors.green,
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => StudentResultPage()),
//                   );
//                 },
//               ),

//               DashboardItem(
//                 Icons.calendar_month,
//                 "Calendar",
//                 color: Colors.orange,
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => StudentCalendarPage()),
//                   );
//                 },
//               ),

//               DashboardItem(
//                 Icons.receipt_long,
//                 "Fee Details",
//                 color: Colors.red,
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => FeeDetailsPage()),
//                   );
//                 },
//               ),

//               DashboardItem(
//                 Icons.celebration,
//                 "Schedule",
//                 color: Colors.pink,
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => ExamSchedulePage()),
//                   );
//                 },
//               ),

//               DashboardItem(
//                 Icons.campaign,
//                 "Notification",
//                 color: Colors.teal,
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => NotificationListPage()),
//                   );
//                 },
//               ),
//               DashboardItem(
//                 Icons.calendar_view_month_rounded,
//                 "Time-Table",
//                 color: Colors.indigo,
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => TimeTablePage()),
//                   );
//                 },
//               ),
//               DashboardItem(
//                 Icons.compass_calibration,
//                 "Complaints",
//                 color: Colors.indigo,
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => ViewComplaintPage()),
//                   );
//                 },
//               ),

//               DashboardItem(
//                 Icons.support_agent,
//                 "Support",
//                 color: Colors.brown,
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => ConnectWithUsPage(
//                         teacherId: 0,
//                         teacherName: '',
//                         teacherPhoto: '',
//                       ),
//                     ),
//                   );
//                 },
//               ),

//               DashboardItem(
//                 Icons.calendar_month,
//                 "Attendance",
//                 color: Colors.green.shade700,
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => AttendanceAnalyticsPage(),
//                     ),
//                   );
//                 },
//               ),

//               DashboardItem(
//                 Icons.account_balance_wallet,
//                 "Payments",
//                 color: Colors.blueGrey,
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => PaymentPage()),
//                   );
//                 },
//               ),
//             ],
//           ),

//           const SizedBox(height: 30),
//         ],
//       ),
//     );
//   }
// }

// /// 🔹 SINGLE DASHBOARD ITEM
// class DashboardItem extends StatelessWidget {
//   final IconData icon;
//   final String title;
//   final VoidCallback? onTap;
//   final Color color;

//   const DashboardItem(
//     this.icon,
//     this.title, {
//     super.key,
//     this.onTap,
//     required this.color,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(40),
//       onTap: onTap,
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.15), // light background
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               icon,
//               color: color, // main icon color
//               size: 26,
//             ),
//           ),
//           const SizedBox(height: 10),
//           Text(
//             title,
//             textAlign: TextAlign.center,
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//             style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class DashboardCard extends StatelessWidget {
//   final String title;
//   final String value;
//   final Color borderColor;
//   final Color backgroundColor;
//   final Color textColor;
//   final String? date;

//   const DashboardCard({
//     super.key,
//     required this.title,
//     required this.value,
//     required this.borderColor,
//     required this.backgroundColor,
//     required this.textColor,
//     this.date,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 98,
//       height: 88,
//       margin: const EdgeInsets.only(right: 10),
//       padding: const EdgeInsets.all(6),
//       decoration: BoxDecoration(
//         color: backgroundColor,
//         border: Border.all(color: borderColor, width: 1.5),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(
//             title,
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: textColor,
//               fontSize: 13,
//             ),
//           ),
//           const SizedBox(height: 5),
//           if (date != null && date!.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.only(top: 0.0, bottom: 2.0),
//               child: Text(
//                 date!,
//                 style: TextStyle(
//                   fontSize: 10,
//                   fontWeight: FontWeight.w500,
//                   color: textColor.withOpacity(0.8),
//                 ),
//               ),
//             )
//           else
//             const SizedBox(height: 10),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: textColor,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class FeePayCard extends StatelessWidget {
//   final int dues;
//   final int fine;
//   final VoidCallback onPayNowTap;
//   final VoidCallback onCardTap;

//   const FeePayCard({
//     super.key,
//     required this.dues,
//     required this.fine,
//     required this.onPayNowTap,
//     required this.onCardTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final Color primaryColor = Colors.red.shade700;
//     final Color lightColor = Colors.red.shade50;

//     // 💡 Condition चेक करें: dues 0 से अधिक है या नहीं
//     final bool showPayButton = dues > 0;

//     return GestureDetector(
//       onTap: onCardTap,
//       child: Container(
//         width: 98,
//         height: 88,
//         margin: const EdgeInsets.only(right: 10),
//         padding: const EdgeInsets.all(4),
//         decoration: BoxDecoration(
//           color: lightColor,
//           border: Border.all(color: primaryColor, width: 1.5),
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               'Fee Amount',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: primaryColor.withOpacity(0.9),
//                 fontSize: 13,
//               ),
//             ),

//             Text(
//               '₹$dues',
//               style: TextStyle(
//                 fontWeight: FontWeight.w900,
//                 color: primaryColor,
//                 fontSize: 18,
//                 height: 1.0,
//               ),
//             ),

//             SizedBox(
//               height: 20,
//               width: double.infinity,
//               child: showPayButton
//                   ? ElevatedButton(
//                       onPressed: onPayNowTap,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: primaryColor,
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(horizontal: 2),
//                         textStyle: const TextStyle(
//                           fontSize: 10,
//                           fontWeight: FontWeight.bold,
//                         ),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(6),
//                         ),
//                         minimumSize: Size.zero,
//                       ),
//                       child: const Text('PAY NOW'),
//                     )
//                   : Center(
//                       child: Text(
//                         'PAID',
//                         style: TextStyle(
//                           color: Colors.green.shade700,
//                           fontWeight: FontWeight.w900,
//                           fontSize: 15,
//                         ),
//                       ),
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
