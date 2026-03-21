import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sonia_public_school/admin/gatepass/add_gatepass.dart';
import 'package:sonia_public_school/api_service.dart';

class GatePassListPage extends StatefulWidget {
  const GatePassListPage({super.key});

  @override
  State<GatePassListPage> createState() => _GatePassListPageState();
}

class _GatePassListPageState extends State<GatePassListPage> {
  final TextEditingController searchCtrl = TextEditingController();
  DateTime fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime toDate = DateTime.now();

  List<Map<String, dynamic>> gatePassList = [];
  bool isLoading = true;

  List<Map<String, dynamic>> filteredList = [];

  @override
  void initState() {
    super.initState();
    _loadGatePassList();
  }

  void _filterList(String value) {
    if (value.isEmpty) {
      filteredList = List.from(gatePassList);
    } else {
      filteredList = gatePassList.where((item) {
        return item["Name"].toString().toLowerCase().contains(
          value.toLowerCase(),
        );
      }).toList();
    }

    setState(() {});
  }

  // For API (yyyy-mm-dd)
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

  Future<void> _loadGatePassList() async {
    setState(() => isLoading = true);

    final response = await ApiService.post(
      context,
      "/admin/gatepass/list",
      body: {"from": formatDateApi(fromDate), "to": formatDateApi(toDate)},
    );

    if (response != null && response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      setState(() {
        gatePassList = data.cast<Map<String, dynamic>>();
        filteredList = List.from(gatePassList);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Widget _addButtonBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
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
                  _loadGatePassList();
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
                  _loadGatePassList();
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
          "Gate Pass",
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
                MaterialPageRoute(builder: (_) => const AddGatePassPage()),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          _addButtonBar(context),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: TextField(
              controller: searchCtrl,
              onChanged: (v) => _filterList(v),
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
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : gatePassList.isEmpty
                ? const Center(child: Text("No Gate Pass Found"))
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: filteredList.length,

                    itemBuilder: (context, i) {
                      final g = filteredList[i];

                      return GatePassCard(
                        id: g["id"].toString(),
                        type: g["Type"] ?? "",
                        name: g["Name"] ?? "",
                        date: g["Date"] ?? "",
                        time: g["Time"] ?? "",
                        reason: g["Reason"] ?? "",
                        recommender: g["Recommender"] ?? "",
                        approver: g["Approver"] ?? "",
                        receivedBy: g["ReceivedBy"],
                        contactNo: g["ContactNo"]?.toString(),
                        relation: g["Relation"],
                        onUpdated: _loadGatePassList,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ================= GATE PASS CARD =================
class GatePassCard extends StatelessWidget {
  final String id;
  final String type;
  final String name;
  final String date;
  final String time;
  final String reason;
  final String recommender;
  final String approver;
  final String? receivedBy;
  final String? contactNo;
  final String? relation;
  final VoidCallback onUpdated;

  const GatePassCard({
    super.key,
    required this.id,
    required this.type,
    required this.name,
    required this.date,
    required this.time,
    required this.reason,
    required this.recommender,
    required this.approver,
    this.receivedBy,
    this.contactNo,
    this.relation,
    required this.onUpdated,
  });

  Widget _rowItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.primary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEmployee = type.toLowerCase() == "employee";

    final Color badgeColor = isEmployee ? Colors.green : Colors.blue;
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 NAME + ID
            Row(
              children: [
                const Icon(Icons.person, size: 15, color: AppColors.primary),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "$type",
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            /// 🔹 Type + Contact (Same Row)
            Row(
              children: [
                if (contactNo != null)
                  Expanded(child: _rowItem(Icons.phone, "Contact: $contactNo")),
                InkWell(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddGatePassPage(gatePassId: id),
                      ),
                    );

                    if (result == true) {
                      onUpdated();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.edit, size: 16, color: AppColors.primary),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            /// 🔹 Date + Time
            Row(
              children: [
                Expanded(child: _rowItem(Icons.calendar_today, "Date: $date")),
                Expanded(child: _rowItem(Icons.lock_clock, "Time: $time")),
              ],
            ),

            const SizedBox(height: 6),

            /// 🔹 Recommender + Approver (Same Row)
            Row(
              children: [
                Expanded(
                  child: _rowItem(Icons.person_outline, "Recc: $recommender"),
                ),
                Expanded(
                  child: _rowItem(Icons.verified_user, "App: $approver"),
                ),
              ],
            ),

            const SizedBox(height: 6),

            /// 🔹 ReceivedBy + Relation (Same Row)
            if (receivedBy != null || relation != null)
              Row(
                children: [
                  if (receivedBy != null)
                    Expanded(
                      child: _rowItem(Icons.badge, "Received: $receivedBy"),
                    ),
                  if (relation != null)
                    Expanded(
                      child: _rowItem(Icons.group, "Relation: $relation"),
                    ),
                ],
              ),
            const SizedBox(height: 6),

            /// 🔹 Reason
            _rowItem(Icons.info_outline, "Reason: $reason"),
          ],
        ),
      ),
    );
  }
}
