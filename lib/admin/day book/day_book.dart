import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';

class DayBook extends StatefulWidget {
  const DayBook({super.key});

  @override
  State<DayBook> createState() => _DayBookState();
}

class _DayBookState extends State<DayBook> {
  Map<String, dynamic>? dayBookData;
  bool isLoading = false;

  DateTime fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime toDate = DateTime.now();
  @override
  void initState() {
    super.initState();
    loadDayBook();
  }

  Future<void> loadDayBook() async {
    setState(() => isLoading = true);

    final response = await ApiService.post(
      context,
      "/admin/day_book",
      body: {"from": formatDate(fromDate), "to": formatDate(toDate)},
    );

    if (response != null && response.statusCode == 200) {
      dayBookData = jsonDecode(response.body);
    }

    setState(() => isLoading = false);
  }

  String formatDateApi(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }

  // For UI (dd-mm-yyyy)
  String formatDateUi(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year}";
  }

  String formatDate(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6ECFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: BackButton(),
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          'Day Book Report',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            _addButtonBar(context),
            const SizedBox(height: 10),
            _dayBookView(),
          ],
        ),
      ),
    );
  }

  Widget _dayBookView() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (dayBookData == null) {
      return const Text("No data available");
    }

    final income = double.tryParse(dayBookData!['income'].toString()) ?? 0;
    final expense = double.tryParse(dayBookData!['expense'].toString()) ?? 0;
    final receipt = double.tryParse(dayBookData!['receipt'].toString()) ?? 0;
    final empPayment =
        double.tryParse(dayBookData!['emp_payment'].toString()) ?? 0;
    final supPayment =
        double.tryParse(dayBookData!['sup_payment'].toString()) ?? 0;

    final balance = income + receipt - expense - empPayment - supPayment;

    return Column(
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.4,
          children: [
            _summaryCard("Income", income, Icons.arrow_downward, Colors.green),
            _summaryCard("Expense", expense, Icons.arrow_upward, Colors.red),
            _summaryCard("Receipt", receipt, Icons.receipt, Colors.blue),
            _summaryCard(
              "Emp Payment",
              empPayment,
              Icons.people,
              Colors.orange,
            ),
            _summaryCard(
              "Sup Payment",
              supPayment,
              Icons.local_shipping,
              Colors.purple,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _balanceCard(balance),
      ],
    );
  }

  Widget _balanceCard(double balance) {
    final isPositive = balance >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: isPositive
              ? [Colors.green, Colors.green.shade700]
              : [Colors.red, Colors.red.shade700],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance, color: Colors.white),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "Net Balance",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            "₹ ${balance.toStringAsFixed(0)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, double amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _box(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withOpacity(.15),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "₹ ${amount.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _box() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
  );

  Widget _addButtonBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: Row(
        children: [
          Expanded(
            child: _dateBox(
              label: formatDateUi(fromDate),
              title: "From",
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: fromDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (picked != null) {
                  setState(() => fromDate = picked);
                  loadDayBook();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _dateBox(
              label: formatDateUi(toDate),
              title: "To",
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: toDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (picked != null) {
                  setState(() => toDate = picked);
                  loadDayBook();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateBox({
    required String label,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 14),
            const SizedBox(width: 6),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          ],
        ),
      ),
    );
  }
}
