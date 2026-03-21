import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sonia_public_school/admin/income/add_income.dart';
import 'package:sonia_public_school/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class IncomeExpenseModel {
  final int id;
  final String type;
  final String date;
  final String itemName;
  final String price;
  final String quantity;
  final int amount;
  final String mode;
  final String addedBy;
  final String remark;
  final String? attachment;

  IncomeExpenseModel({
    required this.id,
    required this.type,
    required this.date,
    required this.itemName,
    required this.price,
    required this.quantity,
    required this.amount,
    required this.mode,
    required this.addedBy,
    required this.remark,
    this.attachment,
  });

  factory IncomeExpenseModel.fromJson(Map<String, dynamic> json) {
    return IncomeExpenseModel(
      id: json['id'],
      type: json['Type'],
      date: json['Date'],
      itemName: json['ItemName'],
      price: json['Price'].toString(),
      quantity: json['Quantity'].toString(),
      amount: json['Amount'],
      mode: json['Mode'],
      addedBy: json['AddedBy'],
      remark: json['Remark'] ?? "",
      attachment: json['Attachment'],
    );
  }
}

class IncomeExpenseList extends StatefulWidget {
  const IncomeExpenseList({super.key});

  @override
  State<IncomeExpenseList> createState() => _IncomeExpenseListState();
}

class _IncomeExpenseListState extends State<IncomeExpenseList> {
  List<IncomeExpenseModel> list = [];

  List<IncomeExpenseModel> filteredList = [];

  bool loading = true;
  late String fromDate;
  late String toDate;
  final TextEditingController searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final oneMonthBack = DateTime(now.year, now.month - 1, now.day);

    fromDate = _formatDate(oneMonthBack);
    toDate = _formatDate(now);
    fetchList();
  }

  Future<void> _downloadFile(BuildContext context, String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Attachment not available")));
      return;
    }

    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Downloading...")));

      final fileName = url.split('/').last;
      late File file;

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw Exception("Download failed");
      }

      /// ===== ANDROID =====
      if (Platform.isAndroid) {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        file = File('${downloadsDir.path}/$fileName');

        await file.writeAsBytes(response.bodyBytes, flush: true);

        /// preview
        await OpenFile.open(file.path);

        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Downloaded & opened")));
      }

      /// ===== iOS =====
      if (Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        file = File('${dir.path}/$fileName');

        await file.writeAsBytes(response.bodyBytes, flush: true);
        await OpenFile.open(file.path);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Download failed")));
    }
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Widget _searchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),

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
                        hintText: "Search by items...",
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

  String _formatDisplayDate(String date) {
    final parts = date.split("-"); // yyyy-MM-dd
    if (parts.length == 3) {
      return "${parts[2]}-${parts[1]}-${parts[0]}";
    }
    return date;
  }

  void _onSearch(String query) {
    if (query.isEmpty) {
      filteredList = list;
    } else {
      final q = query.toLowerCase();

      filteredList = list.where((e) {
        return e.itemName.toLowerCase().contains(q) ||
            e.addedBy.toLowerCase().contains(q) ||
            e.mode.toLowerCase().contains(q);
      }).toList();
    }

    setState(() {});
  }

  Future<void> _pickDate(bool isFrom) async {
    DateTime initialDate = DateTime.parse(isFrom ? fromDate : toDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      if (isFrom && picked.isAfter(DateTime.parse(toDate))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("From date cannot be after To date")),
        );
        return;
      }

      if (!isFrom && picked.isBefore(DateTime.parse(fromDate))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("To date cannot be before From date")),
        );
        return;
      }
      String formatted = _formatDate(picked);

      setState(() {
        if (isFrom) {
          fromDate = formatted;
        } else {
          toDate = formatted;
        }
      });

      fetchList();
    }
  }

  Future<void> fetchList() async {
    loading = true;
    setState(() {});

    try {
      final response = await ApiService.post(
        context,
        "/admin/expense/list",
        body: {"from": fromDate, "to": toDate},
      );

      if (response != null && response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        list = (decoded as List)
            .map((e) => IncomeExpenseModel.fromJson(e))
            .toList();

        filteredList = list;
      }

      loading = false;
      setState(() {});
    } catch (e) {
      loading = false;
      setState(() {});
    }
  }

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
          'Income & Expense',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddIncomeExpPage()),
                ).then((value) {
                  if (value == true) {
                    fetchList();
                  }
                });
              },
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),

                  child: Row(
                    children: [
                      _dateField("From", fromDate, true),
                      const SizedBox(width: 8),
                      _dateField("To", toDate, false),
                    ],
                  ),
                ),

                _searchBar(context),

                Expanded(
                  child: filteredList.isEmpty
                      ? const Center(
                          child: Text(
                            "No Data Found",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(10),
                          itemCount: filteredList.length,
                          itemBuilder: (_, i) => _entryCard(filteredList[i]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _entryCard(IncomeExpenseModel e) {
    final isIncome = e.type == "Income";
    final Color badgeColor = isIncome ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ================= ROW 1 =================
          Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  e.itemName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  e.type,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: AppColors.primary,
              ),
              const SizedBox(width: 3),

              Text(
                e.date,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 6),

          /// ================= ROW 2 =================
          Row(
            children: [
              _info(Icons.currency_rupee, "Price", e.price),
              _info(Icons.tag, "Qty", e.quantity),
              _info(Icons.account_balance_wallet_outlined, "Mode", e.mode),
            ],
          ),

          const SizedBox(height: 6),

          /// ================= ROW 3 =================
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "By: ${e.addedBy}",
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),

              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AddIncomeExpPage(expenseId: e.id.toString()),
                    ),
                  ).then((v) {
                    if (v == true) fetchList();
                  });
                },
                child: const Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          /// ================= ROW 4 =================
          if (e.remark.isNotEmpty ||
              (e.attachment != null && e.attachment!.isNotEmpty)) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (e.remark.isNotEmpty) ...[
                  const Icon(
                    Icons.notes_outlined,
                    size: 13,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      e.remark,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                ],

                if (e.attachment != null && e.attachment!.isNotEmpty)
                  InkWell(
                    onTap: () => _downloadFile(context, e.attachment!),
                    child: const Icon(
                      Icons.download,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _dateField(String label, String date, bool isFrom) {
    return Expanded(
      child: GestureDetector(
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
              const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
              const SizedBox(width: 10),
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
    );
  }
}

Widget _info(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(right: 12),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.primary),
        const SizedBox(width: 3),

        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 11, color: Colors.black87),
            children: [
              TextSpan(
                text: "$label: ",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              TextSpan(
                text: value,
                style: const TextStyle(fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
