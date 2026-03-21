import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';

class EmployeeModel {
  final int id;
  final String name;
  final String contact;
  final String designation;

  EmployeeModel({
    required this.id,
    required this.name,
    required this.contact,
    required this.designation,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] ?? 0,
      name: json['EmployeeName'] ?? '',
      contact: json['ContactNo']?.toString() ?? '',
      designation: json['Designation'] ?? '',
    );
  }
}

class LedgerEntry {
  final String date;
  final String particular;
  final String refNo;
  final String credit;
  final String debit;
  final String balance;

  LedgerEntry({
    required this.date,
    required this.particular,
    required this.refNo,
    required this.credit,
    required this.debit,
    required this.balance,
  });

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      date: json['Date']?.toString() ?? '',
      particular: json['Particular']?.toString() ?? '',
      refNo: json['RefNo']?.toString() ?? '--',
      credit: json['Credit']?.toString() ?? '--',
      debit: json['Debit']?.toString() ?? '--',
      balance: "₹${json['Balance'] ?? 0}",
    );
  }
}

class TeacherLedgerPage extends StatefulWidget {
  const TeacherLedgerPage({super.key});

  static Widget _cell(String text) => Expanded(
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 11),
    ),
  );

  @override
  State<TeacherLedgerPage> createState() => _TeacherLedgerPageState();
}

class _TeacherLedgerPageState extends State<TeacherLedgerPage> {
  List<EmployeeModel> studentList = [];
  List<EmployeeModel> filteredStudents = [];
  bool showEmployeeDropdown = false;
  late DateTime fromDate;
  late DateTime toDate;
  List<LedgerEntry> ledgerList = [];
  bool isLoadingLedger = false;

  Map<String, dynamic>? empInfo;

  EmployeeModel? selectedEmployee;
  bool isLoadingEmployee = false;

  final TextEditingController employeeSearchCtrl = TextEditingController();
  String formatLedgerDate(String rawDate) {
    try {
      final parts = rawDate.split('-');
      if (parts.length == 3) {
        String day = parts[0];
        String month = parts[1];
        String year = parts[2];

        String shortYear = year.substring(year.length - 2); // 25

        return "$day-$month-$shortYear";
      }
      return rawDate;
    } catch (e) {
      return rawDate;
    }
  }

  String _monthName(int month) {
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
    return months[month - 1];
  }

  Future<void> fetchLedger() async {
    if (selectedEmployee == null) return;

    setState(() {
      isLoadingLedger = true;
      ledgerList.clear();
      empInfo = null;
    });

    final res = await ApiService.post(
      context,
      "/admin/employee/ledger",
      body: {
        "EmployeeId": selectedEmployee!.id.toString(),
        "from":
            "${fromDate.year}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}",
        "to":
            "${toDate.year}-${toDate.month.toString().padLeft(2, '0')}-${toDate.day.toString().padLeft(2, '0')}",
      },
    );

    if (res != null && res.statusCode == 200) {
      final data = jsonDecode(res.body);

      empInfo = data;

      List ledgerData = data["ledger"] ?? [];

      ledgerList = ledgerData.map((e) => LedgerEntry.fromJson(e)).toList();
    }

    setState(() => isLoadingLedger = false);
  }

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')} "
        "${_monthName(date.month)} "
        "${date.year}";
  }

  @override
  void initState() {
    super.initState();

    toDate = DateTime.now();
    fromDate = DateTime(toDate.year, toDate.month - 1, toDate.day);

    fetchEmployee();
  }

  Future<void> fetchEmployee() async {
    setState(() => isLoadingEmployee = true);

    final res = await ApiService.post(context, "/get_employee");

    if (res != null && res.statusCode == 200) {
      final List data = jsonDecode(res.body);

      studentList = data.map((e) => EmployeeModel.fromJson(e)).toList();
      filteredStudents = List.from(studentList);
    }

    setState(() => isLoadingEmployee = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F6F8),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: const Text(
          "Teacher Ledger",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: BackButton(),

        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            _filterCard(),
            const SizedBox(height: 10),
            _teacherInfoCard(),
            const SizedBox(height: 10),
            _ledgerTable(),
          ],
        ),
      ),
    );
  }

  // ---------------- FILTER CARD ----------------
  Widget _filterCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: fromDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => fromDate = picked);

                        if (selectedEmployee != null) {
                          fetchLedger();
                        }
                      }
                    },
                    child: _inputField(
                      Icons.calendar_today,
                      formatDate(fromDate),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: toDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => toDate = picked);

                        if (selectedEmployee != null) {
                          fetchLedger();
                        }
                      }
                    },
                    child: _inputField(
                      Icons.calendar_today,
                      formatDate(toDate),
                    ),
                  ),
                ),
              ],
            ),

            Column(
              children: [
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "From To Date: ${formatDate(fromDate)} - ${formatDate(toDate)}",
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 5),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      showEmployeeDropdown = !showEmployeeDropdown;
                    });
                  },
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 18, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            selectedEmployee == null
                                ? "Select Employee"
                                : "${selectedEmployee!.name} (${selectedEmployee!.designation}) / ${selectedEmployee!.contact}",
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        Icon(
                          showEmployeeDropdown
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                        ),
                      ],
                    ),
                  ),
                ),

                // 👇 DROPDOWN LIST
                if (showEmployeeDropdown) _EmployeeDropdownList(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _EmployeeDropdownList() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
        ],
      ),
      child: Column(
        children: [
          // SEARCH
          Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              height: 35,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xffF5F5F5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: TextField(
                controller: employeeSearchCtrl,
                decoration: const InputDecoration(
                  hintText: "Search Employee...",
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (value) {
                  setState(() {
                    filteredStudents = studentList.where((e) {
                      return e.name.toLowerCase().contains(
                            value.toLowerCase(),
                          ) ||
                          e.designation.toLowerCase().contains(
                            value.toLowerCase(),
                          ) ||
                          e.contact.contains(value);
                    }).toList();
                  });
                },
              ),
            ),
          ),

          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 150),
            child: isLoadingEmployee
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      final s = filteredStudents[index];

                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedEmployee = s;
                            showEmployeeDropdown = false;
                          });
                          fetchLedger();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selectedEmployee?.id == s.id
                                ? Colors.blue.shade50
                                : Colors.white,
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          child: Text(
                            "${s.name} (${s.designation}) / ${s.contact}",
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ---------------- TEACHER INFO CARD ----------------
  Widget _teacherInfoCard() {
    if (empInfo == null) return const SizedBox();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PHOTO
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.grey.shade200,
              backgroundImage:
                  (empInfo!['Photo'] != null &&
                      empInfo!['Photo'].toString().isNotEmpty)
                  ? NetworkImage(empInfo!['Photo'])
                  : null,
              child:
                  (empInfo!['Photo'] == null ||
                      empInfo!['Photo'].toString().isEmpty)
                  ? const Icon(Icons.person, size: 30, color: Colors.grey)
                  : null,
            ),

            const SizedBox(width: 12),

            // DETAILS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    empInfo!['EmployeeName'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Employee Id: ${empInfo!['EmployeeId'] ?? ''}",
                    style: const TextStyle(fontSize: 13),
                  ),

                  Text(
                    "Relative Name: ${empInfo!['RelativeName'] ?? ''}",
                    style: const TextStyle(fontSize: 13),
                  ),

                  Text(
                    "Contact: ${empInfo!['ContactNo'] ?? ''}",
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- LEDGER TABLE ----------------
  Widget _ledgerTable() {
    if (isLoadingLedger) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (ledgerList.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          height: 300,
          padding: const EdgeInsets.symmetric(vertical: 40),
          alignment: Alignment.center,
          child: Column(
            children: const [
              Icon(Icons.receipt_long, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                "No Transactions Found",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    double totalCredit = 0;
    double totalDebit = 0;

    for (var e in ledgerList) {
      double credit = double.tryParse(e.credit.replaceAll("₹", "")) ?? 0;
      double debit = double.tryParse(e.debit.replaceAll("₹", "")) ?? 0;

      totalCredit += credit;
      totalDebit += debit.abs();
    }

    double openingBalance =
        double.tryParse(empInfo?['OpeningBalance']?.toString() ?? "0") ?? 0;
    double closingBalance = ledgerList.isNotEmpty
        ? double.tryParse(ledgerList.last.balance.replaceAll("₹", "")) ?? 0
        : openingBalance;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: SizedBox(
        child: Column(
          children: [
            // HEADER
            Container(
              decoration: const BoxDecoration(
                color: Color(0xff6BA368),
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
              child: Row(
                children: const [
                  _HeaderCell("Date"),
                  _HeaderCell("Particular"),
                  _HeaderCell("Ref"),
                  _HeaderCell("Credit"),
                  _HeaderCell("Debit"),
                  _HeaderCell("Balance"),
                ],
              ),
            ),

            // OPENING BALANCE
            if (empInfo != null)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                  color: Colors.grey.shade100,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 🔹 DATE + PARTICULAR MERGED
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(
                          "Opening Balance",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // REF
                    Expanded(child: Center(child: Text("--"))),

                    // CREDIT
                    Expanded(child: Center(child: Text("--"))),

                    // DEBIT
                    Expanded(child: Center(child: Text("--"))),

                    // BALANCE
                    Expanded(
                      child: Center(
                        child: Text(
                          "₹${openingBalance.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // LEDGER ROWS
            ...ledgerList.asMap().entries.map((entry) {
              LedgerEntry e = entry.value;

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    TeacherLedgerPage._cell(formatLedgerDate(e.date)),
                    TeacherLedgerPage._cell(e.particular),
                    TeacherLedgerPage._cell(e.refNo),
                    Expanded(
                      child: Text(
                        e.credit,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    Expanded(
                      child: Text(
                        e.debit,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    TeacherLedgerPage._cell(e.balance),
                  ],
                ),
              );
            }).toList(), // SUMMARY ROW
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(10),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🔹 DATE + PARTICULAR MERGED
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Text(
                        "Closing Balance",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // REF
                  Expanded(child: Center(child: Text("--"))),

                  // TOTAL CREDIT
                  Expanded(
                    child: Center(
                      child: Text(
                        "₹${totalCredit.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // TOTAL DEBIT
                  Expanded(
                    child: Center(
                      child: Text(
                        "₹${totalDebit.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // FINAL BALANCE
                  Expanded(
                    child: Center(
                      child: Text(
                        "₹${closingBalance.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- SMALL WIDGETS ----------------
  Widget _inputField(IconData icon, String hint) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(hint, style: const TextStyle(fontSize: 13)),
          const Spacer(),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
