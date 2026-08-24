import 'dart:convert';
import 'dart:io';
import 'package:sonia_public_school/dashboard/student_sidebar.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sonia_public_school/Attendance_UI/stu_attendance_page.dart';
import 'package:sonia_public_school/Attendance_UI/attendance_pie_chart.dart';
import 'package:sonia_public_school/Notification/notification_list.dart';
import 'package:sonia_public_school/dashboard/calendar.dart';
import 'package:sonia_public_school/dashboard/payment_screen.dart';
import 'package:sonia_public_school/homework/homework_model.dart';
import 'package:sonia_public_school/main.dart';
import 'package:sonia_public_school/payment/fee_details_page.dart';
import 'package:sonia_public_school/payment/payment_page.dart';
import 'package:sonia_public_school/subjects_page.dart';
import 'package:sonia_public_school/Attendance_UI/attendnce_box.dart';
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
    _refreshDashboard();
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
                                Navigator.pop(confirmContext);
                                Navigator.pop(context);
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
    TextEditingController amountController = TextEditingController();

    showDialog(
      context: dashboardContext,
      builder: (dialogContext) {
        int balanceAmount = totalAmount;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
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
                  _buildDialogRow(' Due Amount:', '₹$dues'),
                  _buildDialogRow(' Fine:', '₹$fine', color: Colors.red),

                  /// 🔥 FIXED INPUT
                  _buildInputRow('Pay Amount:', amountController, (value) {
                    int entered = int.tryParse(value) ?? 0;

                    setStateDialog(() {
                      balanceAmount = totalAmount - entered;
                      if (balanceAmount < 0) balanceAmount = 0;
                    });
                  }),

                  const Divider(),
                  _buildDialogRow(
                    'Total Payable:',
                    '₹$totalAmount',
                    isTotal: true,
                  ),

                  /// 🔥 LIVE BALANCE UPDATE
                  _buildBalanceRow('Balance:', balanceAmount),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: AppColors.primary),
                  ),
                  onPressed: () {
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
                    int enteredAmount =
                        int.tryParse(amountController.text) ?? totalAmount;

                    /// Validation
                    if (enteredAmount <= 0 || enteredAmount > totalAmount) {
                      ScaffoldMessenger.of(dashboardContext).showSnackBar(
                        const SnackBar(content: Text("Enter valid amount")),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext);

                    final paymentData = await initiatePayment(
                      beforePay: dues,
                      fine: fine,
                      amount: enteredAmount,
                    );

                    if (paymentData != null) {
                      final paymentUrl = paymentData['payment_url']!;
                      final refNo = paymentData['ref_no']!;

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

                      if (webViewResult == 'PAYMENT_COMPLETE') {
                        final finalStatus = await checkPaymentStatus(
                          refNo: refNo,
                        );

                        if (finalStatus == 'success') {
                          ScaffoldMessenger.of(dashboardContext).showSnackBar(
                            const SnackBar(
                              content: Text('Payment Successful! ✅'),
                            ),
                          );
                          await fetchDashboardData(context);
                          Navigator.pop(dashboardContext, true);
                        } else {
                          ScaffoldMessenger.of(dashboardContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Payment Failed. Status Check Failed/Unknown. ❌',
                              ),
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(dashboardContext).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Payment process failed or was cancelled. ❌',
                            ),
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(dashboardContext).showSnackBar(
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
      },
    );
  }

  Widget _buildBalanceRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Text(
            "₹$value",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, String>?> initiatePayment({
    required int beforePay,
    required int fine,
    required int amount,
  }) async {
    try {
      final response = await ApiService.post(
        context,
        "/student/payment/initiate",
        body: {
          'beforepay': beforePay.toString(),
          'fine': fine.toString(),
          'amount': amount.toString(),
        },
      );

      if (response == null) {
        debugPrint("❌ initiatePayment: response null");
        return null;
      }
      debugPrint("📤 SENDING DATA:");
      debugPrint("beforepay: $beforePay");
      debugPrint("fine: $fine");
      debugPrint("amount: $amount");
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

  Widget _buildInputRow(
    String label,
    TextEditingController controller,
    Function(String) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// 🔹 Label
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),

          /// 🔹 Only numbers input
          SizedBox(
            width: 90,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,

              /// 🔥 MAIN VALIDATION HERE
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],

              decoration: const InputDecoration(
                isDense: true,
                hintText: "0",
                contentPadding: EdgeInsets.symmetric(vertical: 6),
                border: UnderlineInputBorder(),
              ),

              onChanged: (value) {
                /// Extra safety (optional)
                if (value.isEmpty) {
                  controller.text = '';
                }
                onChanged(value);
              },
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
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.appBarGradient),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        toolbarHeight: 68,
        titleSpacing: 0,
        title: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome back,",
                    style: TextStyle(
                      color: Colors.white.withOpacity(.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    studentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.school_outlined,
                        color: Colors.white70,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          schoolName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(.85),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _appBarIcon(
              icon: Icons.calendar_month_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StudentCalendarPage()),
                );
              },
            ),

            const SizedBox(width: 8),

            Stack(
              clipBehavior: Clip.none,
              children: [
                _appBarIcon(
                  icon: Icons.notifications_none_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => NotificationListPage()),
                    );
                  },
                ),

                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    height: 16,
                    width: 16,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      "3",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 10),

            GestureDetector(
              onTap: () => _showSiblingPopup(context),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey.shade200,
                  child: ClipOval(
                    child: studentPhoto.isNotEmpty
                        ? Image.network(
                            studentPhoto,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Image.asset(
                              AppAssets.defaultAvatar,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            AppAssets.defaultAvatar,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),
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
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DashboardSummaryCard(
                          feeDue: dues,
                          siblingDue: fine,
                          payments: payments,
                          subjects: subjects,
                          lastPaymentDate: lastPaymentDate,
                          onPayNowTap: () {
                            _showPaymentConfirmationDialog(context, dues, fine);
                          },
                        ),
                        const SizedBox(height: 10),
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
                        AttendancePieChart(
                          present: attendance['present'] ?? 0,
                          absent: attendance['absent'] ?? 0,
                          leave: attendance['leave'] ?? 0,
                          halfDay: attendance['half_day'] ?? 0,
                          workingDays: attendance['working_days'] ?? 0,
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

Widget _appBarIcon({required IconData icon, required VoidCallback onTap}) {
  return Material(
    color: Colors.white.withOpacity(.15),
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: SizedBox(
        height: 38,
        width: 38,
        child: Icon(icon, color: Colors.white, size: 21),
      ),
    ),
  );
}

class DashboardSummaryCard extends StatelessWidget {
  final int feeDue;
  final int siblingDue;
  final int payments;
  final int subjects;
  final String lastPaymentDate;

  final VoidCallback onPayNowTap;

  const DashboardSummaryCard({
    super.key,
    required this.feeDue,
    required this.siblingDue,
    required this.payments,
    required this.subjects,
    required this.lastPaymentDate,
    required this.onPayNowTap,
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
    String? subtitle,
    required Widget page,

    bool showPayButton = false,
    VoidCallback? onPayNow,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
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
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
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

              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              if (showPayButton) ...[
                const SizedBox(height: 6),

                SizedBox(
                  height: 24,
                  width: 70,
                  child: ElevatedButton(
                    onPressed: onPayNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      "PAY",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
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
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.info],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$greeting 👋",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: Colors.white,
                        size: 13,
                      ),

                      const SizedBox(width: 5),

                      Text(
                        today,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _item(
                    context: context,
                    icon: Icons.account_balance_wallet_rounded,
                    color: Colors.red,
                    title: "Fee Due",
                    value: "₹$feeDue",
                    subtitle: "Sibling ₹$siblingDue",
                    page: const FeeDetailsPage(),

                    showPayButton: feeDue > 0,
                    onPayNow: onPayNowTap,
                  ),

                  Container(height: 55, width: 1, color: Colors.grey.shade300),

                  _item(
                    context: context,
                    icon: Icons.payments_rounded,
                    color: Colors.green,
                    title: "Payments",
                    value: payments.toString(),
                    subtitle: lastPaymentDate,
                    page: PaymentPage(),
                  ),

                  Container(height: 55, width: 1, color: Colors.grey.shade300),

                  _item(
                    context: context,
                    icon: Icons.menu_book_rounded,
                    color: Colors.blue,
                    title: "Subjects",
                    value: subjects.toString(),
                    page: SubjectsPage(),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    final String fullAttachmentUrl = hasAttachment ? attachment.toString() : '';

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
