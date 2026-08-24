import 'package:sonia_public_school/admin/AllDue/alldue.dart';
import 'package:sonia_public_school/admin/admin_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sonia_public_school/admin/Attendance/emp_attendance.dart';
import 'package:sonia_public_school/admin/Receipt/list_receipt.dart';
import 'package:sonia_public_school/admin/admissions/admission_list.dart';
// import 'package:sonia_public_school/admin/balance_sheet/balance_sheet.dart';
import 'package:sonia_public_school/admin/complaint/list_complaint.dart';
import 'package:sonia_public_school/admin/day%20book/day_book.dart';
import 'package:sonia_public_school/admin/employee/list_employee.dart';
import 'package:sonia_public_school/admin/homeworks/manage_homework.dart';
import 'package:sonia_public_school/admin/enquiry/list_enquiry.dart';
import 'package:sonia_public_school/admin/alert/alert.dart';
import 'package:sonia_public_school/admin/events/List_events.dart';
import 'package:sonia_public_school/admin/fees/fee_due.dart';
import 'package:sonia_public_school/admin/gatepass/list_gatepass.dart';
import 'package:sonia_public_school/admin/income/list_income.dart';
import 'package:sonia_public_school/admin/ledger/stu_ledger.dart';
import 'package:sonia_public_school/admin/ledger/teacher_ledger.dart';
import 'package:sonia_public_school/admin/notice/list_notice.dart';
import 'package:sonia_public_school/admin/payment/list_payment.dart';
import 'package:sonia_public_school/admin/result/stu_result.dart';
import 'package:sonia_public_school/admin/Attendance/stu_attendance.dart';
import 'package:sonia_public_school/api_service.dart';
import 'package:sonia_public_school/login_page.dart';

class Adminsidebar extends StatefulWidget {
  const Adminsidebar({super.key});

  @override
  State<Adminsidebar> createState() => _AdminsidebarState();
}

class _AdminsidebarState extends State<Adminsidebar> {
  String schoolName = '';
  String principalName = '';
  String adminPhoto = '';

  @override
  void initState() {
    super.initState();
    loadAdminInfo();
  }

  void _navigate(BuildContext context, Widget page) {
    Navigator.pop(context); // ✅ close drawer
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> loadAdminInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      schoolName = prefs.getString('school_name') ?? '';
      principalName = prefs.getString('admin_name') ?? '';
      adminPhoto = prefs.getString('admin_photo') ?? '';
    });
  }

  String getPhotoUrl(String photo) {
    if (photo.isEmpty) return '';
    return photo.startsWith('http') ? photo : '${ApiService.Url}/$photo';
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
            color: AppColors.primary,
            height: 100,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage: adminPhoto.isNotEmpty
                      ? NetworkImage(getPhotoUrl(adminPhoto))
                      : const AssetImage('assets/images/logo.png')
                            as ImageProvider,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schoolName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),

                      Text(
                        principalName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),

                      const Text(
                        'Admin',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          sidebarItem(
            context,
            Icons.dashboard,
            'Dashboard',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AdminDashboardPage()),
            ),
          ),
          sidebarItem(
            context,
            Icons.how_to_reg,
            'Admission',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AdmissionListPage()),
            ),
          ),

          sidebarItem(
            context,
            Icons.badge,
            'Employee',
            () => _navigate(context, EmployeeListPage()),
          ),

          sidebarItem(
            context,
            Icons.payments,
            'Payment',
            () => _navigate(context, PaymentListPage()),
          ),

          sidebarItem(
            context,
            Icons.receipt_long,
            'Receipt',
            () => _navigate(context, AdminReceiptPage()),
          ),

          sidebarItem(
            context,
            Icons.fact_check,
            'Student Attendance',
            () => _navigate(context, StudentAttendancePage()),
          ),

          sidebarItem(
            context,
            Icons.rule,
            'Employee Attendance',
            () => _navigate(context, EmployeeAttendancePage()),
          ),

          sidebarItem(
            context,
            Icons.exit_to_app,
            'Gate Pass',
            () => _navigate(context, GatePassListPage()),
          ),

          sidebarItem(
            context,
            Icons.menu_book,
            'Student Ledger',
            () => _navigate(context, StudentLedgerPage()),
          ),

          sidebarItem(
            context,
            Icons.account_balance_wallet,
            'Employee Ledger',
            () => _navigate(context, TeacherLedgerPage()),
          ),

          sidebarItem(
            context,
            Icons.report_problem,
            'Complaint',
            () => _navigate(context, AdminComplaintList()),
          ),

          // sidebarItem(
          //   context,
          //   Icons.account_balance,
          //   'Balance',
          //   () => _navigate(context, BalanceSheet()),
          // ),
          sidebarItem(
            context,
            Icons.money_off_csred,
            'Fee Due',
            () => _navigate(context, FeeDuePage()),
          ),

          sidebarItem(
            context,
            Icons.assessment,
            'Result',
            () => _navigate(context, AdminResultPage()),
          ),

          sidebarItem(
            context,
            Icons.support_agent,
            'Admission Enquiry',
            () => _navigate(context, AdmissionEnquiryPage()),
          ),

          sidebarItem(
            context,
            Icons.trending_up,
            'Income/Expense',
            () => _navigate(context, IncomeExpenseList()),
          ),

          // sidebarItem(
          //   context,
          //   Icons.event_busy,
          //   'Leave',
          //   () => _navigate(context, EmployeeLeave()),
          // ),
          sidebarItem(
            context,
            Icons.book,
            'Day Book Report',
            () => _navigate(context, DayBook()),
          ),

          sidebarItem(
            context,
            Icons.payments_outlined,
            'All-Due',
            () => _navigate(context, AllDuePage()),
          ),
          sidebarItem(
            context,
            Icons.menu_book_outlined,
            'Homework',
            () => _navigate(context, AdminHomework()),
          ),
          sidebarItem(
            context,
            Icons.campaign_outlined,
            'Notice',
            () => _navigate(context, NoticeListPage()),
          ),
          sidebarItem(
            context,
            Icons.event_available_outlined,
            'Events',
            () => _navigate(context, ListEventPage()),
          ),
          sidebarItem(
            context,
            Icons.notifications_active_outlined,
            'Alert',
            () => _navigate(context, AlertPage()),
          ),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon(icon, size: 20),
          title: Text(title, style: const TextStyle(fontSize: 14)),
          visualDensity: const VisualDensity(vertical: -3),
          dense: true,
          onTap: onTap,
        ),

        // 👇 thin divider
        const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16),
      ],
    );
  }
}
