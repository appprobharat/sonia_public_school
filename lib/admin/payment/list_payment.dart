import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sonia_public_school/admin/payment/add_payment.dart';
import 'package:sonia_public_school/api_service.dart';

class PaymentListPage extends StatefulWidget {
  const PaymentListPage({super.key});

  @override
  State<PaymentListPage> createState() => _PaymentListPageState();
}

class _PaymentListPageState extends State<PaymentListPage> {
  final TextEditingController searchCtrl = TextEditingController();

  List<Map<String, dynamic>> payments = [];
  List<Map<String, dynamic>> filteredPayments = [];
  final List<Map<String, String>> typeList = [
    {"label": "Employee", "value": "employee"},
    {"label": "Supplier", "value": "supplier"},
  ];

  List<String> modeList = [];

  bool isLoading = false;

  String currentType = "employee";
  String? selectedMode;

  late String fromDate;
  late String toDate;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    final oneMonthBack = DateTime(now.year, now.month - 1, now.day);

    fromDate = _formatDate(oneMonthBack);
    toDate = _formatDate(now);

    fetchPayModes();
    fetchPayments();
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> fetchPayModes() async {
    final response = await ApiService.post(context, "/get_mode");

    if (response != null && response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        modeList = List<String>.from(data.map((e) => e["Paymode"].toString()));
      });
    }
  }

  String _formatDisplayDate(String date) {
    final parts = date.split("-");
    if (parts.length == 3) {
      return "${parts[2]}-${parts[1]}-${parts[0]}";
    }
    return date;
  }

  Future<void> _pickDate(bool isFrom) async {
    DateTime initialDate = isFrom
        ? DateTime.parse(fromDate)
        : DateTime.parse(toDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      String formatted = _formatDate(picked);

      setState(() {
        if (isFrom) {
          fromDate = formatted;
        } else {
          toDate = formatted;
        }
      });

      fetchPayments();
    }
  }

  Future<void> fetchPayments() async {
    setState(() => isLoading = true);

    print("===== PAYMENT FILTER REQUEST =====");
    print({
      "from": fromDate,
      "to": toDate,
      "type": currentType,
      "mode": selectedMode,
    });

    final response = await ApiService.post(
      context,
      "/admin/payment/list",
      body: {
        "from": fromDate,
        "to": toDate,
        "type": currentType,
        if (selectedMode != null) "mode": selectedMode,
      },
    );

    if (response != null) {
      print("===== PAYMENT API RESPONSE =====");
      print("Status Code: ${response.statusCode}");
      print("Raw Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        print("Decoded Data: $data");
        print("Total Records: ${data.length}");

        setState(() {
          payments = List<Map<String, dynamic>>.from(data);
          filteredPayments = payments;
        });
      } else {
        print("API ERROR: ${response.body}");
      }
    } else {
      print("API RESPONSE IS NULL");
    }

    setState(() => isLoading = false);
  }

  void _onSearch(String query) {
    if (query.isEmpty) {
      filteredPayments = payments;
    } else {
      final q = query.toLowerCase();
      filteredPayments = payments.where((p) {
        final name = (p['Name'] ?? "").toString().toLowerCase();
        final phone = (p['ContactNo'] ?? "").toString();
        return name.contains(q) || phone.contains(q);
      }).toList();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F1FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: BackButton(),
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          'Payments',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddPaymentPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                _dateField("From", fromDate, true),
                const SizedBox(width: 8),
                _dateField("To", toDate, false),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                _typeDropdown(),
                const SizedBox(width: 8),
                _modeDropdown(),
              ],
            ),
          ),
          _searchBar(context),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredPayments.isEmpty
                ? const Center(child: Text("No payments found"))
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: filteredPayments.length,
                    itemBuilder: (context, index) {
                      final p = filteredPayments[index];

                      return PaymentCard(
                        name: p['Name'] ?? "",
                        phone: p['ContactNo']?.toString() ?? "",
                        date: p['Date'] ?? "",
                        amount: "₹ ${p['Amount']}",
                        by: p['PayBy'] ?? "",
                        remark: p['Remark'] ?? "",
                        classInfo: p['Mode'],
                        paymentId: p['id'].toString(),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // SEARCH BAR
  Widget _searchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: searchCtrl,
                      onChanged: _onSearch,
                      decoration: const InputDecoration(
                        hintText: "Search by name or contact...",
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _modeDropdown() {
    return Expanded(
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedMode,
            hint: const Text("Pay Mode", style: TextStyle(fontSize: 12)),

            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down, size: 18),
            style: const TextStyle(fontSize: 12, color: Colors.black),
            items: [
              const DropdownMenuItem<String>(value: null, child: Text("All")),
              ...modeList.map((mode) {
                return DropdownMenuItem<String>(value: mode, child: Text(mode));
              }).toList(),
            ],
            onChanged: (value) {
              setState(() {
                selectedMode = value == "all" ? null : value;
              });
              fetchPayments();
            },
          ),
        ),
      ),
    );
  }

  Widget _typeDropdown() {
    return Expanded(
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: currentType,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down, size: 18),
            style: const TextStyle(fontSize: 12, color: Colors.black),
            items: typeList.map((e) {
              return DropdownMenuItem<String>(
                value: e["value"],
                child: Text(e["label"]!),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                currentType = value!;
              });
              fetchPayments();
            },
          ),
        ),
      ),
    );
  }

  Widget _dateField(String label, String date, bool isFrom) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _pickDate(isFrom),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatDisplayDate(date),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
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

class PaymentCard extends StatelessWidget {
  final String name;
  final String phone;
  final String date;
  final String amount;
  final String by;
  final String remark;
  final String? classInfo;
  final String paymentId;

  const PaymentCard({
    super.key,
    required this.paymentId,
    required this.name,
    required this.phone,
    required this.date,
    required this.amount,
    required this.by,
    required this.remark,
    this.classInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + Amount
          Row(
            children: [
              Icon(Icons.person, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Phone + Date
          Row(
            children: [
              Icon(Icons.call, size: 13, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                phone,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const Spacer(),
              Text(
                date,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Mode + Paid By
          Row(
            children: [
              Icon(Icons.credit_card, size: 13, color: AppColors.primary),
              const SizedBox(width: 6),

              Text(
                "Mode: ${classInfo ?? "-"}",
                style: const TextStyle(fontSize: 11),
              ),

              const Spacer(),

              Text(
                "By: $by",
                style: const TextStyle(fontSize: 11),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              // 🔹 Remark only if available
              if (remark.isNotEmpty) ...[
                Icon(Icons.comment, size: 13, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    remark,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else
                const Spacer(),

              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddPaymentPage(paymentId: paymentId),
                    ),
                  );

                  if (result == true) {
                    Navigator.pop(context, true);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.edit, size: 14, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
