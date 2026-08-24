import 'dart:convert';
import 'package:sonia_public_school/admin/AllDue/alldue.dart';
import 'package:sonia_public_school/admin/alert/alert.dart';
import 'package:sonia_public_school/admin/bar_garph.dart';
import 'package:sonia_public_school/admin/birthday.dart';
import 'package:sonia_public_school/admin/profile/fees.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sonia_public_school/admin/Attendance/emp_attendance.dart';
import 'package:sonia_public_school/admin/Receipt/list_receipt.dart';
import 'package:sonia_public_school/admin/admin_sidebar.dart';
import 'package:sonia_public_school/admin/admissions/admission_list.dart';
import 'package:sonia_public_school/admin/admissions/quick_admission.dart';
import 'package:sonia_public_school/admin/profile/admin_profile.dart';
import 'package:sonia_public_school/admin/complaint/list_complaint.dart';
import 'package:sonia_public_school/admin/day%20book/day_book.dart';
import 'package:sonia_public_school/admin/employee/list_employee.dart';
import 'package:sonia_public_school/admin/enquiry/list_enquiry.dart';
import 'package:sonia_public_school/admin/fees/fee_due.dart';
import 'package:sonia_public_school/admin/income/list_income.dart';
import 'package:sonia_public_school/admin/ledger/stu_ledger.dart';
import 'package:sonia_public_school/admin/ledger/teacher_ledger.dart';
import 'package:sonia_public_school/admin/payment/list_payment.dart';
import 'package:sonia_public_school/admin/result/stu_result.dart';
import 'package:sonia_public_school/admin/Attendance/stu_attendance.dart';
import 'package:sonia_public_school/api_service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _currentIndex = 0;
  String schoolName = '';
  String schoolLogo = '';
  // String selectedSession = "2024-25";

  // List<String> sessionList = ["2022-23", "2023-24", "2024-25"];
  @override
  void initState() {
    super.initState();
    _loadSchoolInfo();
  }

  final List<Widget> _pages = [
    _DashboardBody(),
    DashboardPage(),
    AdminFeesPage(),
    EarningExpenseChart(),
    AdminProfilePage(),
  ];
  Future<void> _loadSchoolInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      schoolName = prefs.getString('school_name') ?? '';
      schoolLogo = prefs.getString('admin_photo') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Adminsidebar(),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        titleSpacing: 0,
        iconTheme: IconThemeData(color: Colors.white),

        /// ✅ MENU BUTTON YAHAN
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),

        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              backgroundImage: schoolLogo.isNotEmpty
                  ? NetworkImage(schoolLogo)
                  : const AssetImage('assets/images/logo.png') as ImageProvider,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                schoolName.isNotEmpty ? schoolName : "Admin Dashboard",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            // Align(
            //   alignment: Alignment.topRight,
            //   child: PopupMenuButton<String>(
            //     padding: EdgeInsets.zero,
            //     onSelected: (value) async {
            //       setState(() => selectedSession = value);

            //       final prefs = await SharedPreferences.getInstance();
            //       await prefs.setString("selected_session", value);

            //       print("Session: $value");
            //     },
            //     itemBuilder: (context) {
            //       return sessionList.map((session) {
            //         return PopupMenuItem<String>(
            //           value: session,
            //           child: Text(
            //             session,
            //             style: const TextStyle(fontSize: 14),
            //           ),
            //         );
            //       }).toList();
            //     },

            //     child: Container(
            //       padding: const EdgeInsets.symmetric(
            //         horizontal: 12,
            //         vertical: 6,
            //       ),
            //       margin: const EdgeInsets.only(right: 8),
            //       decoration: BoxDecoration(
            //         color: Colors.white.withOpacity(0.18),
            //         borderRadius: BorderRadius.circular(8),
            //       ),
            //       child: Row(
            //         children: [
            //           Text(
            //             selectedSession,
            //             style: const TextStyle(
            //               color: Colors.white,
            //               fontSize: 13,
            //               fontWeight: FontWeight.w500,
            //             ),
            //           ),
            //           const SizedBox(width: 2),
            //           const Icon(
            //             Icons.arrow_drop_down,
            //             color: Colors.white,
            //             size: 20,
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),

      /// 🔥 BODY WITH INDEX
      body: _pages[_currentIndex],

      /// 🔥 BOTTOM NAV BAR
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: "Students"),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_tree),
            label: "Fees",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Reports",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

class _DashboardBody extends StatefulWidget {
  const _DashboardBody();

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  bool isLoading = true;
  Map<String, dynamic> dashboard = {};

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  String getPreviousMonthName() {
    final now = DateTime.now();
    final prevMonth = DateTime(now.year, now.month - 1);

    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];

    return months[prevMonth.month - 1];
  }

  Future<void> _loadDashboard() async {
    final response = await ApiService.post(context, "/admin/dashboard");

    if (response != null) {
      setState(() {
        dashboard = jsonDecode(response.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double collection =
        double.tryParse(dashboard['collection']?.toString() ?? '0') ?? 0;

    final double fees =
        double.tryParse(dashboard['fee']?.toString() ?? '0') ?? 0;

    // progress = collection / fees
    final double progress = fees == 0 ? 0 : (collection / fees).clamp(0.0, 1.0);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// --- Dashboard Cards ---
          Row(
            children: [
              _statCard(
                title: "Collection",
                titleIcon: Icons.payments,
                value1Title: "Today",
                value1: dashboard['today_collection']?.toString() ?? "0",
                value1Icon: Icons.today,
                value2Title: getPreviousMonthName(),
                value2: dashboard['last_month_collection']?.toString() ?? "0",
                value2Icon: Icons.calendar_month,
                bgColor: Colors.blue.shade600,
              ),

              _statCard(
                title: "Students",
                titleIcon: Icons.school,
                value1Title: "Student",
                value1: dashboard['students']?.toString() ?? "0",
                value1Icon: Icons.person,
                value2Title: "Parents",
                value2: dashboard['parents'].toString(),
                value2Icon: Icons.group,
                bgColor: Colors.green.shade600,
              ),

              _statCard(
                title: "Employee",
                titleIcon: Icons.badge,
                value1Title: "Male",
                value1: dashboard['male_employees'].toString(),
                value1Icon: Icons.man,
                value2Title: "Female",
                value2: dashboard['female_employees'].toString(),
                value2Icon: Icons.woman,
                bgColor: Colors.orange.shade600,
              ),
            ],
          ),
          const SizedBox(height: 20),

          /// --- Fees Progress ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "Collection",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "Fees",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "Fees",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                /// 🔹 Dynamic Progress Bar
                LinearProgressIndicator(
                  value: progress, // 🔥 dynamic
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.green,
                  backgroundColor: Colors.grey.shade300,
                ),

                const SizedBox(height: 5),

                /// 🔹 Dynamic values
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(collection.toStringAsFixed(0)), // 🔥 collection
                    Text(fees.toStringAsFixed(0)), // 🔥 fees
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// ================= STUDENTS =================
          _sectionCard(
            title: "Students",
            items: [
              _menuTile(
                Icons.people,
                "Students",
                [Colors.blue, Colors.lightBlueAccent],
                Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdmissionListPage()),
                  );
                },
              ),

              _menuTile(
                Icons.fact_check,
                "St.Attd",
                [Colors.green, Colors.teal],
                Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => StudentAttendancePage()),
                  );
                },
              ),
              _menuTile(
                Icons.menu_book,
                "St.Ledger",
                [Colors.red, Colors.redAccent],
                Colors.red,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => StudentLedgerPage()),
                  );
                },
              ),
              _menuTile(
                Icons.money_off_csred,
                "Fee Due",
                [Colors.brown, Colors.orangeAccent],
                Colors.brown,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => FeeDuePage()),
                  );
                },
              ),
              _menuTile(
                Icons.assessment,
                "Result",
                [Colors.cyan, Colors.tealAccent],
                Colors.cyan,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdminResultPage()),
                  );
                },
              ),
              _menuTile(
                Icons.support_agent,
                "Adm.Enquiry",
                [Colors.pink, Colors.pinkAccent],
                Colors.pink,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdmissionEnquiryPage()),
                  );
                },
              ),
            ],
          ),

          /// ================= TEACHERS / STAFF =================
          _sectionCard(
            title: "TEACHERS / STAFF",
            items: [
              _menuTile(
                Icons.badge,
                "Employee",
                [Colors.blue, Colors.lightBlueAccent],
                Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EmployeeListPage()),
                  );
                },
              ),
              _menuTile(
                Icons.rule,
                "Emp Attd",
                [Colors.indigo, Colors.indigoAccent],
                Colors.indigo,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EmployeeAttendancePage()),
                  );
                },
              ),
              _menuTile(
                Icons.account_balance_wallet,
                "Emp.Ledger",
                [Colors.green, Colors.teal],
                Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TeacherLedgerPage()),
                  );
                },
              ),
              // _menuTile(
              //   Icons.event_busy,
              //   "Leave",
              //   [Colors.lightGreen, Colors.green],
              //   Colors.green,
              //   onTap: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (_) => EmployeeLeave()),
              //     );
              //   },
              // ),
              _menuTile(
                Icons.report_problem,
                "Complaints",
                [Colors.blueGrey, Colors.blue],
                Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdminComplaintList()),
                  );
                },
              ),
            ],
          ),

          // /// ================= ACCOUNTS & OTHERS =================
          _sectionCard(
            title: "Accounts & Others",
            items: [
              _menuTile(
                Icons.how_to_reg,
                "Admission",
                [Colors.pink, Colors.redAccent],
                Colors.pink,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => QuickAdmissionPage()),
                  );
                },
              ),
              _menuTile(
                Icons.payments,
                "Payment",
                [Colors.orange, Colors.deepOrange],
                Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PaymentListPage()),
                  );
                },
              ),
              _menuTile(
                Icons.receipt_long,
                "Receipt",
                [Colors.purple, Colors.deepPurple],
                Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdminReceiptPage()),
                  );
                },
              ),
              // _menuTile(
              //   Icons.account_balance,
              //   "Balance",
              //   [Colors.purple, Colors.deepPurple],
              //   Colors.purple,
              //   onTap: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (_) => BalanceSheet()),
              //     );
              //   },
              // ),
              _menuTile(
                Icons.trending_up,
                "Inc/Exp",
                [Colors.amber, Colors.orange],
                Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => IncomeExpenseList()),
                  );
                },
              ),
              _menuTile(
                Icons.book,
                "Day-Book",
                [Colors.green, Colors.teal],
                Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DayBook()),
                  );
                },
              ),
              _menuTile(
                Icons.currency_rupee_outlined,
                "All Due",
                [Colors.blueGrey, Colors.blue],
                Colors.blueGrey,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AllDuePage()),
                  );
                },
              ),
              _menuTile(
                Icons.alarm,
                "Alert",
                [Colors.pink, Colors.pinkAccent],
                Colors.pink,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AlertPage()),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _menuTile(
    IconData icon,
    String label,
    List<Color> bgColors,
    Color iconColor, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: bgColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: bgColors.last.withOpacity(0.4),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 11,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> items}) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 TITLE INSIDE CARD
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),

            // 🔹 HORIZONTAL LINE
            Divider(thickness: 1, color: Colors.grey.shade300),

            const SizedBox(height: 10),

            // 🔹 ICON GRID
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.8,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              children: items,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required String title,
    IconData? titleIcon,
    String? value1,
    String? value1Title,
    IconData? value1Icon,
    String? value2,
    String? value2Title,
    IconData? value2Icon,

    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(0.45), // soft glow
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Title Row
            Row(
              children: [
                if (titleIcon != null)
                  Icon(titleIcon, color: Colors.white, size: 16),
                if (titleIcon != null) const SizedBox(width: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            // 🔹 Divider
            Divider(
              color: Colors.white.withOpacity(0.4),
              thickness: 0.8,
              height: 6,
            ),

            if (value1 != null) _statRow(value1Icon, value1Title!, value1),

            if (value2 != null) _statRow(value2Icon, value2Title!, value2),
          ],
        ),
      ),
    );
  }

  Widget _statRow(IconData? icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          if (icon != null) Icon(icon, color: Colors.white70, size: 14),
          if (icon != null) const SizedBox(width: 4),
          Expanded(
            child: Text(
              "$title: $value",
              style: const TextStyle(color: Colors.white, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool isLoading = true;

  int maleCount = 0;
  int femaleCount = 0;
  List birthdays = [];

  @override
  void initState() {
    super.initState();
    fetchStudentAnalysis();
  }

  Future<void> fetchStudentAnalysis() async {
    final response = await ApiService.post(context, "/admin/student/analysis");

    if (response != null && response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        maleCount = data["male_students"] ?? 0;
        femaleCount = data["female_students"] ?? 0;
        birthdays = data["birthdays"] ?? [];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          /// 🔹 Student Graph
          CircleGraphWidget(maleCount: maleCount, femaleCount: femaleCount),

          const SizedBox(height: 16),

          /// 🔹 Upcoming Birthday
          UpcomingBirthdayWidget(birthdays: birthdays),
        ],
      ),
    );
  }
}
