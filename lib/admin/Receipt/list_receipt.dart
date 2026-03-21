import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sonia_public_school/admin/Receipt/add_receipt.dart';
import 'package:sonia_public_school/api_service.dart';

class ReceiptModel {
  final int id;
  final String name;
  final String fatherName;
  final String className;
  final String section;
  final String contactNo;
  final String ledgerNo;
  final String amount;
  final String date;
  final String payBy;
  final String mode;
  final String? remark;
  final String refNo;

  ReceiptModel({
    required this.contactNo,
    required this.id,
    required this.name,
    required this.fatherName,
    required this.className,
    required this.section,
    required this.ledgerNo,
    required this.amount,
    required this.date,
    required this.payBy,
    required this.mode,
    required this.refNo,
    this.remark,
  });

  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    return ReceiptModel(
      id: json["id"] ?? 0,
      name: json["Name"]?.toString() ?? "",
      fatherName: json["FatherName"]?.toString() ?? "",
      className: json["Class"]?.toString() ?? "",
      section: json["Section"]?.toString() ?? "",
      ledgerNo: json["LedgerNo"]?.toString() ?? "",
      contactNo: json["ContactNo"]?.toString() ?? "",
      amount: json["Amount"]?.toString() ?? "0",
      date: json["Date"]?.toString() ?? "",
      payBy: json["PayBy"]?.toString() ?? "",
      mode: json["Mode"]?.toString() ?? "",
      remark: json["Remark"]?.toString(),
      refNo: json["RefNo"]?.toString() ?? "",
    );
  }
}

class AdminReceiptPage extends StatefulWidget {
  const AdminReceiptPage({super.key});

  @override
  State<AdminReceiptPage> createState() => _AdminReceiptPageState();
}

class _AdminReceiptPageState extends State<AdminReceiptPage> {
  late DateTime startDate;
  late DateTime endDate;
  String? selectedMode;
  List<String> modeList = [];
  String? selectedPayById;
  String? selectedPayByName;
  List<Map<String, dynamic>> accountants = [];

  List<ReceiptModel> allReceipts = [];
  List<ReceiptModel> filteredReceipts = [];
  bool isLoading = false;
  DateTime _parseDate(String date) {
    if (date.isEmpty) return DateTime.now();

    final parts = date.split("-");
    if (parts.length != 3) return DateTime.now();

    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
  }

  final TextEditingController searchCtrl = TextEditingController();
  @override
  void initState() {
    super.initState();
    endDate = DateTime.now();
    startDate = DateTime.now().subtract(const Duration(days: 30));
    fetchAccountants();
    fetchPayModes();
    fetchReceipts();
  }

  Future<void> fetchAccountants() async {
    final response = await ApiService.post(
      context,
      "/get_employee",
      body: {"type": "accountant"},
    );

    if (response != null && response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      setState(() {
        accountants = data.map<Map<String, dynamic>>((e) {
          return {
            "id": e["id"].toString(),
            "name": e["EmployeeName"].toString(),
          };
        }).toList();
      });
    }
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

  void _applyFilter() {
    final query = searchCtrl.text.toLowerCase();

    filteredReceipts = allReceipts.where((r) {
      final matchName =
          r.name.toLowerCase().contains(query) ||
          r.fatherName.toLowerCase().contains(query) ||
          r.ledgerNo.toLowerCase().contains(query);

      final receiptDate = _parseDate(r.date);

      final matchDate =
          !receiptDate.isBefore(startDate) && !receiptDate.isAfter(endDate);

      return matchName && matchDate;
    }).toList();

    setState(() {});
  }

  String _apiDate(DateTime d) {
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  Future<void> fetchReceipts() async {
    setState(() => isLoading = true);

    final body = {
      "from": _apiDate(startDate),
      "to": _apiDate(endDate),
      "payby": selectedPayById,
      "mode": selectedMode,
    };

    final response = await ApiService.post(
      context,
      "/admin/receipt/list",
      body: body,
    );

    if (response != null && response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      allReceipts = data.map((e) => ReceiptModel.fromJson(e)).toList();
      filteredReceipts = List.from(allReceipts);
    }

    setState(() => isLoading = false);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? startDate : endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        isStart ? startDate = picked : endDate = picked;
      });

      await fetchReceipts();
    }
  }

  String _fmt(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}-"
        "${d.month.toString().padLeft(2, '0')}-"
        "${d.year}";
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
          "Receipts",
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
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddAdminReceiptPage()),
              );

              if (result == true) {
                fetchReceipts();
              }
            },
          ),
        ],
      ),

      body: Column(
        children: [
          _filterBar(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredReceipts.isEmpty
                ? const Center(child: Text("No Receipts Found"))
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: filteredReceipts.length,
                    itemBuilder: (context, i) {
                      final r = filteredReceipts[i];
                      return ReceiptCard(
                        name: r.name,
                        parent: r.fatherName,
                        classInfo: "${r.className} (${r.section})",
                        ledgerNo: r.ledgerNo,
                        contactNo: r.contactNo,
                        date: r.date,
                        receiptNo: r.refNo.isNotEmpty ? r.refNo : "#${r.id}",
                        amount: r.amount,
                        mode: r.mode,
                        payBy: r.payBy,
                        remark: r.remark,
                        onEdit: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddAdminReceiptPage(
                                receiptId: r.id.toString(),
                              ),
                            ),
                          );

                          if (result == true) {
                            fetchReceipts();
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ---------------- FILTER BAR ----------------
  Widget _filterBar() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          // 🔹 DATE ROW
          Row(
            children: [
              Expanded(
                child: _dateBox(
                  label: _fmt(startDate),
                  title: "From Date",
                  onTap: () => _pickDate(isStart: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dateBox(
                  label: _fmt(endDate),
                  title: "To Date",
                  onTap: () => _pickDate(isStart: false),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 🔹 DROPDOWN ROW (NO extra horizontal padding)
          Row(
            children: [
              _paidByDropdown(),
              const SizedBox(width: 8),
              _modeDropdown(),
            ],
          ),

          const SizedBox(height: 8),

          TextField(
            controller: searchCtrl,
            onChanged: (v) => _applyFilter(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, size: 18),
              hintText: "Search by name",
              hintStyle: const TextStyle(fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeDropdown() {
    return Expanded(
      child: Stack(
        children: [
          Container(
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
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                style: const TextStyle(fontSize: 12, color: Colors.black),
                items: [
                  const DropdownMenuItem(value: null, child: Text("All")),
                  ...modeList.map(
                    (mode) => DropdownMenuItem(value: mode, child: Text(mode)),
                  ),
                ],
                onChanged: (value) {
                  setState(() => selectedMode = value);
                  fetchReceipts();
                },
              ),
            ),
          ),

          Positioned(
            left: 12,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              color: const Color(0xffF6F1FA),
              child: const Text(
                "Pay Mode",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paidByDropdown() {
    return Expanded(
      child: Stack(
        children: [
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedPayById,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                style: const TextStyle(fontSize: 12, color: Colors.black),
                items: [
                  const DropdownMenuItem(value: null, child: Text("All")),
                  ...accountants.map(
                    (e) => DropdownMenuItem(
                      value: e["id"],
                      child: Text(e["name"]),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => selectedPayById = value);
                  fetchReceipts();
                },
              ),
            ),
          ),

          Positioned(
            left: 12,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              color: const Color(0xffF6F1FA),
              child: const Text(
                "Paid By",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateBox({
    required String label,
    required VoidCallback onTap,
    required String title,
  }) {
    return Stack(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(label, style: const TextStyle(fontSize: 12)),
                ),
                const Icon(Icons.keyboard_arrow_down, size: 18),
              ],
            ),
          ),
        ),
        Positioned(
          left: 12,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            color: const Color(0xffF6F1FA),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ================= RECEIPT CARD =================
class ReceiptCard extends StatelessWidget {
  final String name;
  final String parent;
  final String classInfo;
  final String ledgerNo;
  final String contactNo;
  final String date;
  final String receiptNo;
  final String amount;
  final String mode;
  final String payBy;
  final String? remark;
  final VoidCallback? onEdit;

  const ReceiptCard({
    super.key,
    required this.name,
    required this.parent,
    required this.classInfo,
    required this.ledgerNo,
    required this.contactNo,
    required this.date,
    required this.receiptNo,
    required this.amount,
    required this.mode,
    required this.payBy,
    this.remark,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔹 ROW 1 → Name (Father) —— Date
          Row(
            children: [
              Expanded(
                child: Text(
                  "$name ($parent)",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                date,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          /// 🔹 ROW 2 → RefNo | Class | Mode
          Row(
            children: [
              Icon(Icons.school, size: 13, color: AppColors.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  classInfo,
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              Icon(Icons.receipt_long, size: 13, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                "#${receiptNo.replaceAll("#", "")}",
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          /// 🔹 ROW 3 → Ledger | Contact
          Row(
            children: [
              // 🔹 Phone
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        contactNo,
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // 🔹 Ledger
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        ledgerNo,
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // 🔹 Mode (Right Side)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  mode,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🔹 LEFT SIDE (Remark Flexible)
              Expanded(
                child: (remark != null && remark!.isNotEmpty)
                    ? Row(
                        children: [
                          Icon(
                            Icons.notes_outlined,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              remark!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox(),
              ),

              // 🔹 RIGHT SIDE (By + Amount)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("By: $payBy", style: const TextStyle(fontSize: 11)),
                  const SizedBox(width: 12),
                  Text(
                    "₹ $amount",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
