import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';

class BalanceSheet extends StatefulWidget {
  const BalanceSheet({super.key});

  @override
  State<BalanceSheet> createState() => _BalanceSheetState();
}

class _BalanceSheetState extends State<BalanceSheet> {
  @override
  Widget build(BuildContext context) {
    final purple = const Color(0xFF8E44AD);

    return Scaffold(
      backgroundColor: const Color(0xFFF6ECFB),
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: AppColors.primary,
        leading: const BackButton(),
        title: const Text(
          'Balance Sheet ',
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
            _dateFilter(purple),
            const SizedBox(height: 8),
            _schoolCard(),
            const SizedBox(height: 10),
            _section(
              title: 'Student Receipts',
              icon: Icons.school,
              tag: 'Amount',
              items: const [
                _RowItem('Rahul Yadav', 'LKG/B • 31-01-2024', 5000),
                _RowItem('Aman Gupta', '4TH/A • 25-01-2025', 4200),
                _RowItem('Varsha Singh', '3RD/C • 19-02-2025', 3500),
              ],
              total: 12700,
              badgeText: 'Total Amount',
            ),
            _section(
              title: 'Employee Receipts',
              icon: Icons.work,
              tag: 'Amount',
              items: const [
                _RowItem('Pooja', '25 Dec 2024 | Vinay Kumar', 258),
                _RowItem('Ayush Raj', '25 Jan 2025 | Vinay Kumar', 1000),
              ],
              total: 1258,
              badgeText: 'Total Amount',
            ),
            _section(
              title: 'Other Income',
              icon: Icons.account_balance_wallet,
              tag: 'Amount',
              items: const [
                _RowItem('Donation', '05 Jan 2024 | Office', 5000),
                _RowItem('Tripic charges', '10 Jan 2025', 1000),
              ],
              total: 51000,
              badgeText: 'Total Balance',
              badgeColor: Colors.redAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateFilter(Color purple) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _box(),
      child: Column(
        children: [
          _dropdownRow(Icons.calendar_today, 'Date Range-Wise'),
          const SizedBox(height: 6),
          _dropdownRow(Icons.date_range, '04-02-2024  •  04-02-2025'),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {},
              icon: const Icon(Icons.search, size: 14, color: Colors.white),
              label: const Text(
                'Search Report',
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _schoolCard() {
  //   return Container(
  //     padding: const EdgeInsets.all(10),
  //     decoration: _box(),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: const [
  //         Text(
  //           'Technical Public School',
  //           style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
  //         ),
  //         SizedBox(height: 4),
  //         Text('Faridabad, Haryana', style: TextStyle(fontSize: 11)),
  //         SizedBox(height: 4),
  //         Text(
  //           '📞 9555442060   ✉️ techinnovationschool@gmail.com',
  //           style: TextStyle(fontSize: 11),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  Widget _schoolCard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/logo.png', // school logo
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Technical Public School',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Faridabad, Haryana', style: TextStyle(fontSize: 11)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.phone, size: 12, color: AppColors.primary),
              const Text(':9555442060 ', style: TextStyle(fontSize: 11)),
              SizedBox(width: 20),
              Icon(Icons.mail, size: 12, color: AppColors.primary),
              const Text(
                ' techinnovationschool@gmail.com',
                style: TextStyle(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required String tag,
    required List<_RowItem> items,
    required int total,
    required String badgeText,
    Color badgeColor = Colors.green,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: _box(),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.deepPurple),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _tag(tag),
            ],
          ),
          const Divider(height: 12),
          ...items.map((e) => _itemRow(e)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ₹${total.toString()}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemRow(_RowItem e) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.name, style: const TextStyle(fontSize: 12)),
                Text(
                  e.sub,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            '₹${e.amount}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _dropdownRow(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: _innerBox(),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.deepPurple),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 11))),
          const Icon(Icons.keyboard_arrow_down, size: 16),
        ],
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, color: Colors.white),
      ),
    );
  }

  BoxDecoration _box() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    boxShadow: const [
      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
    ],
  );

  BoxDecoration _innerBox() => BoxDecoration(
    color: const Color(0xFFF4ECFA),
    borderRadius: BorderRadius.circular(10),
  );
}

class _RowItem {
  final String name;
  final String sub;
  final int amount;

  const _RowItem(this.name, this.sub, this.amount);
}
