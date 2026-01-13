import 'package:flutter/material.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            Icon(Icons.grid_view_rounded, color: Colors.black87),
            const SizedBox(width: 10),
            Image.asset('assets/images/logo.png', height: 32),
            const SizedBox(width: 8),
            Text(
              "EduSathi Admin",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.deepPurple.shade700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// --- Dashboard deepPurple Cards ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statCard(
                  title: "Collection",
                  value1: "67",
                  value1Title: "Today",
                  value2: "76",
                  value2Title: "Dec",
                  value3: "765",
                  value3Title: "Year",
                ),
                _statCard(
                  title: "Students",
                  value1: "67",
                  value1Title: "Student",
                  value2: "76",
                  value2Title: "Siblings",
                  value3: "75",
                  value3Title: "Parents",
                ),
                _statCard(
                  title: "Employee",
                  value1: "67",
                  value1Title: "Male",
                  value2: "76",
                  value2Title: "Female",
                  value3: "0",
                  value3Title: "Staff",
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
                      const Text(
                        "June Fees",
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
                  LinearProgressIndicator(
                    value: 0.38,
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.green,
                    backgroundColor: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 5),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("2800"),
                      Text(
                        "Online: 2800",
                        style: TextStyle(color: Colors.deepPurple),
                      ),
                      Text("7800"),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// --- Grid Menu ---
            GridView.count(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _menuTile(Icons.sms, "SMS"),
                _menuTile(Icons.person, "Students"),
                _menuTile(Icons.leaderboard, "Inquiry"),
                _menuTile(Icons.group, "Teachers"),
                _menuTile(Icons.calendar_month, "Attendance"),
                _menuTile(Icons.account_tree, "Fees "),
                _menuTile(Icons.local_shipping, "Transport"),
                _menuTile(Icons.warning, "Defaulters"),
                _menuTile(Icons.currency_rupee, "Collect Fees"),
                _menuTile(Icons.list_alt, "Summary"),
                _menuTile(Icons.receipt, "Fees Report"),
                _menuTile(Icons.money, "Expenses"),
                _menuTile(Icons.book, "Ledger"),
                _menuTile(Icons.credit_card, "Admit Cards"),
                _menuTile(Icons.alarm, "Reminders"),
                _menuTile(Icons.assignment, "Marksheet"),
              ],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// ---------------- Widgets ----------------

  Widget _statCard({
    required String title,
    String? value1,
    String? value1Title, // ← label 1
    String? value2,
    String? value2Title, // ← label 2
    String? value3,
    String? value3Title, // ← label 3
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade600,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),

            if (value1 != null)
              Text(
                "$value1Title - ${value1}",
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),

            if (value2 != null)
              Text(
                "$value2Title - ${value2}",
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),

            if (value3 != null)
              Text(
                "$value3Title - ${value3}",
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  Widget _menuTile(IconData icon, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: Colors.deepPurple.shade700),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
