import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sonia_public_school/Attendance_UI/stu_attendance_page.dart';
import 'package:sonia_public_school/Exam/exam_schedule.dart';
import 'package:sonia_public_school/Exam/stu_result.dart';
import 'package:sonia_public_school/Attendance_UI/attendance_pie_chart.dart';
import 'package:sonia_public_school/Notification/notification_list.dart';
import 'package:sonia_public_school/connect_teacher/connect_with_us.dart';
import 'package:sonia_public_school/dashboard/calendar.dart';
import 'package:sonia_public_school/dashboard/payment_screen.dart';
import 'package:sonia_public_school/homework/homework_model.dart';
import 'package:sonia_public_school/homework/homework_page.dart';
import 'package:sonia_public_school/dashboard/timetable_page.dart';
import 'package:sonia_public_school/main.dart';
import 'package:sonia_public_school/payment/fee_details_page.dart';
import 'package:sonia_public_school/payment/payment_page.dart';
import 'package:sonia_public_school/profile_page.dart';
import 'package:sonia_public_school/school_info_page.dart';
import 'package:sonia_public_school/complaint/view_complaints_page.dart';
import 'package:sonia_public_school/subjects_page.dart';
import 'package:sonia_public_school/syllabus/syllabus.dart';
import 'package:sonia_public_school/Attendance_UI/attendnce_box.dart';
import 'package:sonia_public_school/Attendance_UI/stu_attendance_report.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sonia_public_school/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with RouteAware {
  bool isLoading = true;
  bool isRefreshing = false;
  String studentName = '';
  String studentPhoto = '';
  String schoolName = '';
  String studentClass = '';
  String studentsection = '';
  int fine = 0;
  int dues = 0;
  int payments = 0;
  String lastPaymentDate = '';
  int subjects = 0;
  String status = '';
  Map<String, dynamic> attendance = {};
  List<Map<String, dynamic>> homeworks = [];
  List<dynamic> notices = [];
  List<dynamic> events = [];
  List<dynamic> siblings = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void didPopNext() {
    // jab kisi page se BACK aake dashboard dikhe
    _refreshDashboard();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _refreshDashboard(); // app open / login ke baad
  }

  Future<void> _refreshDashboard() async {
    if (!mounted) return;

    if (!isLoading) {
      setState(() => isRefreshing = true);
    }

    await loadProfileData();
    await fetchDashboardData(context);

    if (!mounted) return;

    setState(() {
      isLoading = false;
      isRefreshing = false;
    });
  }

  Future<void> loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    studentName = prefs.getString('student_name') ?? '';
    studentPhoto = prefs.getString('student_photo') ?? '';
    schoolName = prefs.getString('school_name') ?? '';
    studentClass = prefs.getString('class_name') ?? '';
    studentsection = prefs.getString('section') ?? '';
  }

  Widget buildStudentImage(String? photo) {
    if (photo == null || photo.isEmpty) {
      return CircleAvatar(radius: 40, child: Icon(Icons.person));
    }

    return Image.network(photo, width: 80, height: 80, fit: BoxFit.cover);
  }

  Future<void> fetchDashboardData(BuildContext context) async {
    final response = await ApiService.post(context, "/student/dashboard");

    if (response == null) return;

    debugPrint("🔵 DASHBOARD STATUS: ${response.statusCode}");
    debugPrint("🔵 DASHBOARD BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint("📢 RAW NOTICES: ${data['notices']}");
      fine = data['fine'] ?? 0;
      dues = data['dues'] ?? 0;
      payments = int.tryParse(data['payments'].toString()) ?? 0;

      final rawDate = data['payment_date'] ?? '';
      if (rawDate.isNotEmpty) {
        try {
          final dateObject = DateTime.parse(rawDate);
          lastPaymentDate =
              '${dateObject.day}/${dateObject.month}/${dateObject.year}';
        } catch (_) {
          lastPaymentDate = rawDate;
        }
      }

      status = data['today_status'] ?? '';
      subjects = data['subjects'] ?? 0;

      attendance = {
        'present': data['attendances']?['present'] ?? 0,
        'absent': data['attendances']?['absent'] ?? 0,
        'leave': data['attendances']?['leave'] ?? 0,
        'half_day': data['attendances']?['half_day'] ?? 0,
        'working_days': data['attendances']?['working_days'] ?? 0,
      };

      homeworks = List<Map<String, dynamic>>.from(data['homeworks'] ?? []);
      notices = data['notices'] ?? [];
      events = data['events'] ?? [];
      siblings = data['siblings'] ?? [];

      return;
    }
  }

  void _showSiblingPopup(BuildContext context) {
    if (siblings.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Siblings'),
          content: const Text('No siblings available for this student.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.people, color: AppColors.info),
            SizedBox(width: 8),
            Text(
              'Switch Sibling',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: siblings.length,
            itemBuilder: (context, index) {
              final sibling = siblings[index];
              final photoUrl =
                  sibling['Photo'] != null &&
                      sibling['Photo'].toString().isNotEmpty
                  ? sibling['Photo'].toString()
                  : ApiService.siblingUrl;

              final name = sibling['Name'] ?? 'Unknown';
              final className = sibling['Class'].toString();

              final studentId = sibling['id'].toString();

              print('🧠 Sibling Data: $sibling');

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey.shade200,
                    child: ClipOval(
                      child: Image.network(
                        photoUrl,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            size: 26,
                            color: Colors.grey,
                          );
                        },
                      ),
                    ),
                  ),

                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('Class: $className'),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                  ),
                  onTap: () {
                    // 🔹 Show confirmation dialog before switching
                    showDialog(
                      context: context,
                      builder: (BuildContext confirmContext) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          title: const Text(
                            'Confirm Switch',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          content: Text(
                            'Are you sure you want to switch to $name?',
                            style: const TextStyle(fontSize: 15),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(confirmContext),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                Navigator.pop(
                                  confirmContext,
                                ); // close confirm dialog
                                Navigator.pop(
                                  context,
                                ); // close sibling list dialog safely
                                if (!mounted) return;
                                await _shiftLogin(studentId);
                              },
                              icon: const Icon(Icons.check_circle, size: 18),
                              label: const Text('Yes, Switch'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.info,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shiftLogin(String studentId) async {
    if (!mounted) return;
    try {
      final response = await ApiService.post(
        context,
        "/student/shift_login",
        body: {'id': studentId},
      );

      if (response == null) return;

      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        await ApiService.saveSession(data);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        print('❌ Shift login failed: ${data['message']}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Login failed')),
        );
      }
    } catch (e) {
      print('🚨 Exception in _shiftLogin: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Something went wrong')));
    }
  }

  void _showPaymentConfirmationDialog(
    BuildContext dashboardContext,
    int dues,
    int fine,
  ) {
    final totalAmount = dues + fine;
    print('DEBUG: Dialog opened. Total amount: ₹$totalAmount');

    showDialog(
      context: dashboardContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Confirm Payment',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDialogRow(' Fee Amount:', '₹$dues'),
              _buildDialogRow(' Fine:', '₹$fine', color: Colors.red),
              const Divider(),
              _buildDialogRow('Total Payable:', '₹$totalAmount', isTotal: true),
            ],
          ),
          actions: [
            TextButton(
              child: const Text(
                "Cancel",
                style: TextStyle(color: AppColors.primary),
              ),
              onPressed: () {
                print('DEBUG: Payment cancelled by user from dialog.');
                Navigator.pop(dialogContext);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text("Proceed to Pay"),
              onPressed: () async {
                Navigator.pop(dialogContext);

                final totalDues = dues;
                final lateFine = fine;
                print('DEBUG: Proceed to Pay clicked. Starting API process...');

                ScaffoldMessenger.of(dashboardContext).showSnackBar(
                  const SnackBar(
                    content: Text('Initializing payment... Please wait.'),
                  ),
                );
                print('DEBUG: SnackBar shown. Calling initiatePayment...');

                final paymentData = await initiatePayment(
                  amount: totalDues,
                  fine: lateFine,
                );

                if (paymentData != null) {
                  final paymentUrl = paymentData['payment_url']!;
                  final refNo = paymentData['ref_no']!;

                  print('DEBUG: Init Success. RefNo: $refNo, URL received.');

                  final webViewResult = await Navigator.push(
                    dashboardContext,
                    MaterialPageRoute(
                      builder: (_) => PaymentWebView(
                        paymentUrl: paymentUrl,
                        successRedirectUrl: 'flutter://payment-success',
                        failureRedirectUrl: 'flutter://payment-failure',
                      ),
                    ),
                  );
                  print(
                    'DEBUG: WebView closed. Result received: $webViewResult',
                  );

                  if (webViewResult == 'PAYMENT_COMPLETE') {
                    print(
                      'DEBUG: WebView reports completion. Checking final status...',
                    );

                    final finalStatus = await checkPaymentStatus(refNo: refNo);
                    print('DEBUG: Final Status from API: $finalStatus');

                    if (finalStatus == 'success') {
                      ScaffoldMessenger.of(dashboardContext).showSnackBar(
                        const SnackBar(content: Text('Payment Successful! ✅')),
                      );
                      await fetchDashboardData(context);
                      print(
                        'DEBUG: Dashboard data fetched successfully before popping.',
                      );
                      Navigator.pop(dashboardContext, true);
                    } else if (finalStatus == 'pending') {
                      ScaffoldMessenger.of(dashboardContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Payment Pending. Check dashboard later.',
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(dashboardContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Payment Failed. Status Check Failed/Unknown. ❌',
                          ),
                        ),
                      );
                    }
                  } else if (webViewResult == 'PAYMENT_FAILED') {
                    print('DEBUG: WebView reports failure/cancellation.');
                    ScaffoldMessenger.of(dashboardContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Payment process failed or was cancelled. ❌',
                        ),
                      ),
                    );
                  } else {
                    print(
                      'DEBUG: Result not PAYMENT_COMPLETE/FAILED. Status check skipped.',
                    );
                    ScaffoldMessenger.of(dashboardContext).showSnackBar(
                      // ✅ dashboardContext
                      const SnackBar(
                        content: Text(
                          'Payment process abandoned. Status not confirmed.',
                        ),
                      ),
                    );
                  }
                } else {
                  // API Call failed
                  print('ERROR: initiatePayment failed (paymentData is null).');
                  ScaffoldMessenger.of(dashboardContext).showSnackBar(
                    // ✅ dashboardContext
                    const SnackBar(
                      content: Text(
                        'Could not initialize payment. Please try again.',
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, String>?> initiatePayment({
    required int amount,
    required int fine,
  }) async {
    try {
      final response = await ApiService.post(
        context,
        "/student/payment/initiate",
        body: {'amount': amount.toString(), 'fine': fine.toString()},
      );

      if (response == null) {
        debugPrint("❌ initiatePayment: response null");
        return null;
      }

      debugPrint("DEBUG: StatusCode → ${response.statusCode}");
      debugPrint("DEBUG: Body → ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.containsKey('payment_url') && data.containsKey('ref_no')) {
          return {
            'payment_url': data['payment_url'].toString(),
            'ref_no': data['ref_no'].toString(),
          };
        } else {
          debugPrint('❌ initiatePayment: payment_url / ref_no missing');
          return null;
        }
      } else {
        debugPrint('❌ initiatePayment failed → ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint("❌ initiatePayment exception: $e");
      return null;
    }
  }

  Future<String?> checkPaymentStatus({required String refNo}) async {
    try {
      final response = await ApiService.get(
        context,
        "/student/payment/status/$refNo",
      );

      if (response == null) {
        debugPrint("❌ checkPaymentStatus: response null");
        return 'error';
      }

      debugPrint("DEBUG: StatusCode → ${response.statusCode}");
      debugPrint("DEBUG: Body → ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.containsKey('status')) {
          return data['status'].toString();
        } else {
          debugPrint('❌ status key missing');
          return 'unknown';
        }
      } else {
        debugPrint('❌ checkPaymentStatus failed → ${response.statusCode}');
        return 'error';
      }
    } catch (e) {
      debugPrint("❌ checkPaymentStatus exception: $e");
      return 'error';
    }
  }

  Widget _buildDialogRow(
    String label,
    String value, {
    Color color = Colors.black87,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? AppColors.primary : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: isLoading
          ? null
          : LeftSidebarMenu(
              studentName: studentName,
              studentPhoto: studentPhoto,
              studentClass: studentClass,
              studentsection: studentsection,
            ),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '$schoolName',
                style: const TextStyle(color: Colors.white, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              child: Icon(Icons.calendar_month_rounded),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => StudentCalendarPage()),
              ),
            ),
            SizedBox(width: 5),
            GestureDetector(
              child: Icon(Icons.notifications),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NotificationListPage()),
              ),
            ),
            SizedBox(width: 5),
            GestureDetector(
              onTap: () => _showSiblingPopup(context),
              child: CircleAvatar(
                radius: 15,
                backgroundColor: Colors.grey.shade200,
                child: ClipOval(
                  child: Image.network(
                    studentPhoto,
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        AppAssets.defaultAvatar,
                        width: 30,
                        height: 30,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 5),
          ],
        ),
        backgroundColor: AppColors.primary,
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
                            FeePayCard(
                              dues: dues,
                              fine: fine,
                              onCardTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FeeDetailsPage(),
                                ),
                              ),
                              onPayNowTap: () => _showPaymentConfirmationDialog(
                                context,
                                dues,
                                fine,
                              ),
                            ),
                            GestureDetector(
                              child: DashboardCard(
                                title: 'Last Pay',
                                value: payments.toString(),
                                borderColor: AppColors.success,
                                backgroundColor: AppColors.success.shade50,
                                textColor: AppColors.success,
                                date: lastPaymentDate,
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PaymentPage(),
                                ),
                              ),
                            ),
                            GestureDetector(
                              child: DashboardCard(
                                title: 'Subjects',
                                value: subjects.toString(),
                                borderColor: AppColors.info,
                                backgroundColor: AppColors.info.shade50,
                                textColor: AppColors.info,
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SubjectsPage(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        GestureDetector(
                          child: AttendanceCard(
                            title: "Today's Attendance",
                            place: "School",
                            status: status,
                            icon: Icons.school,
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AttendanceAnalyticsPage(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 225,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.shade100,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade200,
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: AttendancePieChart(
                            present: attendance['present'] ?? 0,
                            absent: attendance['absent'] ?? 0,
                            leave: attendance['leave'] ?? 0,
                            halfDay: attendance['half_day'] ?? 0,
                            workingDays: attendance['working_days'] ?? 0,
                          ),
                        ),
                        const SizedBox(height: 10),
                        buildRecentHomeworks(context, homeworks),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 350,
                          child: NoticesEventsToggle(
                            initialNotices: notices,
                            initialEvents: events,
                          ),
                        ),
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
  final String? date;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.borderColor,
    required this.backgroundColor,
    required this.textColor,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 98,
      height: 88,
      margin: const EdgeInsets.only(right: 10),
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
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 5),
          if (date != null && date!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 0.0, bottom: 2.0),
              child: Text(
                date!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: textColor.withOpacity(0.8),
                ),
              ),
            )
          else
            const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isEvent;

  const InfoCard({super.key, required this.item, required this.isEvent});

  Future<void> _launchUrl(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open attachment link.')),
      );
    }
  }

  Future<void> _downloadFile(BuildContext context, String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Attachment not available")));
      return;
    }

    try {
      final fileName = url.split('/').last;
      late File file;

      // 🔽 DIRECT HTTP (S3 public file)
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw Exception("Download failed");
      }

      // ================= ANDROID =================
      if (Platform.isAndroid) {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        file = File('${downloadsDir.path}/$fileName');

        await file.writeAsBytes(response.bodyBytes, flush: true);

        // ✅ PREVIEW
        await OpenFile.open(file.path);

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("📥 Downloaded & Preview opened")),
        );
      }

      // ================= iOS =================
      if (Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        file = File('${dir.path}/$fileName');

        await file.writeAsBytes(response.bodyBytes, flush: true);

        // ✅ PREVIEW
        await OpenFile.open(file.path);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ Download failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleKey = isEvent ? "EventTitle" : "NoticeTitle";
    String formatDate(String? inputDate) {
      if (inputDate == null || inputDate.isEmpty) return '';
      try {
        final date = DateTime.parse(inputDate);
        return DateFormat('dd-MM-yyyy').format(date);
      } catch (e) {
        return inputDate;
      }
    }

    final Color primaryColor = isEvent
        ? Colors.orange.shade700
        : Colors.indigo.shade700;
    final Color lightColor = isEvent
        ? Colors.orange.shade50
        : Colors.indigo.shade50;

    final String? attachment = item["Attachment"];
    final String schoolId = item["SchoolId"]?.toString() ?? '';
    final bool hasAttachment =
        attachment != null && attachment.isNotEmpty && schoolId.isNotEmpty;
    final String folder = isEvent ? 'event' : 'notice';
    final String fullAttachmentUrl = hasAttachment
        ? ApiService.attachmentUrl(schoolId, folder, attachment)
        : '';

    debugPrint("📎 NOTICE ATTACHMENT URL: $fullAttachmentUrl");

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: primaryColor, width: 1.5),
      ),
      color: lightColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item[titleKey] ?? 'Untitled',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  formatDate(item["Date"] ?? 'N/A'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const Divider(height: 16),

            Text(
              item["Description"] ?? 'No description provided.',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            if (hasAttachment) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text("View Attachment"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),

                    onPressed: () => _launchUrl(context, fullAttachmentUrl),
                  ),

                  const SizedBox(width: 25),

                  IconButton(
                    onPressed: () => _downloadFile(context, fullAttachmentUrl),
                    icon: Icon(Icons.download, color: primaryColor, size: 24),
                    tooltip: 'Download Attachment',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NoticesEventsToggle extends StatelessWidget {
  final List<dynamic> initialNotices;
  final List<dynamic> initialEvents;

  const NoticesEventsToggle({
    super.key,
    required this.initialNotices,
    required this.initialEvents,
  });
  Widget _buildList(List<dynamic> data, {required bool isEvent}) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          isEvent ? 'No upcoming events.' : 'No new notices posted.',
          style: TextStyle(fontSize: 16, color: Colors.grey[500]),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index] as Map<String, dynamic>;
        return InfoCard(item: item, isEvent: isEvent);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary, width: 1),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.primary,
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.primary,
                splashBorderRadius: BorderRadius.circular(20),
                tabs: const [
                  Tab(text: 'Notices'),
                  Tab(text: 'Events'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                _buildList(initialNotices, isEvent: false),

                _buildList(initialEvents, isEvent: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
              color: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              height: 120,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.grey.shade300,
                    child: ClipOval(
                      child: Image.network(
                        studentPhoto,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            AppAssets.defaultAvatar,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          studentName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Class: $studentClass',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Section: ${studentsection.isNotEmpty ? studentsection : "-"}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            sidebarTile(
              context: context,
              icon: Icons.dashboard,
              title: 'Dashboard',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DashboardScreen()),
                );
              },
            ),
            sidebarTile(
              icon: Icons.person,
              context: context,
              title: 'Profile',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfilePage()),
                );
              },
            ),

            sidebarTile(
              icon: Icons.book,
              context: context,
              title: 'Homeworks',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => HomeworkPage()),
                );
              },
            ),
            sidebarTile(
              context: context,
              icon: Icons.calendar_month,
              title: 'Attendance',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StudentAttendanceScreen()),
                );
              },
            ),
            sidebarTile(
              context: context,
              icon: Icons.calendar_today,
              title: 'Time-Table',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TimeTablePage()),
                );
              },
            ),
            sidebarTile(
              context: context,
              icon: Icons.calendar_month,
              title: 'Calendar',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StudentCalendarPage()),
                );
              },
            ),

            sidebarTile(
              context: context,
              icon: Icons.subject,
              title: 'Subjects',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SubjectsPage()),
                );
              },
            ),
            sidebarTile(
              context: context,
              icon: Icons.book_sharp,
              title: 'Syllabus',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SyllabusPage()),
                );
              },
            ),
            sidebarTile(
              context: context,
              icon: Icons.receipt_long_outlined,
              title: 'Exam Schedule',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ExamSchedulePage()),
                );
              },
            ),
            sidebarTile(
              context: context,
              icon: Icons.report,
              title: 'Complaint',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ViewComplaintPage()),
                );
              },
            ),
            sidebarTile(
              context: context,
              icon: Icons.attach_money,
              title: 'Fees',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FeeDetailsPage()),
                );
              },
            ),
            sidebarTile(
              context: context,
              icon: Icons.payment,
              title: 'Payment',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PaymentPage()),
                );
              },
            ),
            sidebarTile(
              context: context,
              icon: Icons.list_alt_outlined,
              title: 'Result',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StudentResultPage()),
                );
              },
            ),
            sidebarTile(
              context: context,
              icon: Icons.school,
              title: 'School Info',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SchoolInfoPage()),
                );
              },
            ),

            sidebarTile(
              context: context,
              icon: Icons.support_agent,
              title: 'Contact & Support',
              onTap: () {
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
              },
            ),
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
                        onPressed: () {
                          Navigator.pop(context);
                          ApiService.post(context, "/logout");
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
}

Widget sidebarTile({
  required BuildContext context,
  required IconData icon,
  required String title,
  required VoidCallback onTap,
}) {
  return ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 0),
    visualDensity: VisualDensity(vertical: -2),

    leading: Icon(icon),
    title: Text(title),

    onTap: () {
      Navigator.pop(context);
      Future.microtask(onTap);
    },
  );
}

class FeePayCard extends StatelessWidget {
  final int dues;
  final int fine;
  final VoidCallback onPayNowTap;
  final VoidCallback onCardTap;

  const FeePayCard({
    super.key,
    required this.dues,
    required this.fine,
    required this.onPayNowTap,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.red.shade700;
    final Color lightColor = Colors.red.shade50;

    // 💡 Condition चेक करें: dues 0 से अधिक है या नहीं
    final bool showPayButton = dues > 0;

    return GestureDetector(
      onTap: onCardTap,
      child: Container(
        width: 98,
        height: 88,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: lightColor,
          border: Border.all(color: primaryColor, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Fee Amount',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryColor.withOpacity(0.9),
                fontSize: 13,
              ),
            ),

            Text(
              '₹$dues',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: primaryColor,
                fontSize: 18,
                height: 1.0,
              ),
            ),

            SizedBox(
              height: 20,
              width: double.infinity,
              child: showPayButton
                  ? ElevatedButton(
                      onPressed: onPayNowTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        textStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('PAY NOW'),
                    )
                  : Center(
                      child: Text(
                        'PAID',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
