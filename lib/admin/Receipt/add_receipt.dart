import 'dart:convert';
import 'package:sonia_public_school/admin/ledger/stu_ledger.dart';
import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';
import 'package:flutter/services.dart';

class AddAdminReceiptPage extends StatefulWidget {
  final String? receiptId;

  const AddAdminReceiptPage({super.key, this.receiptId});

  @override
  State<AddAdminReceiptPage> createState() => _AddAdminReceiptPageState();
}

class _AddAdminReceiptPageState extends State<AddAdminReceiptPage> {
  DateTime receiptDate = DateTime.now();
  bool get isEdit => widget.receiptId != null;
  bool isSaving = false;

  List<StudentModel> studentList = [];
  List<StudentModel> filteredStudents = [];
  bool isBalanceLoading = false;

  String collectedBy = 'Please Select';
  String payMode = 'Please Select';
  bool isEditLoading = false;

  List<String> payModes = [];
  List<Map<String, dynamic>> accountants = [];

  bool isLoadingData = false;
  bool isLoadingStudents = false;
  bool showStudentDropdown = false;
  int? selectedAccountantId;
  final TextEditingController studentSearchCtrl = TextEditingController();
  final discountCtrl = TextEditingController();
  final fineCtrl = TextEditingController();
  final receiptCtrl = TextEditingController();
  final narrationCtrl = TextEditingController();
  double calculatedBalance = 0;
  double dueAmount = 0;
  double previousReceiptAmount = 0;
  StudentModel? selectedStudent;
  Future<void> _pickReceiptDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: receiptDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        receiptDate = picked;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    if (isEdit) {
      isEditLoading = true;
    }

    initPage();
  }

  Future<void> initPage() async {
    await fetchStudents();
    await fetchPayModes();
    await fetchAccountants();

    discountCtrl.addListener(calculateBalance);
    fineCtrl.addListener(calculateBalance);
    receiptCtrl.addListener(calculateBalance);

    if (isEdit) {
      await loadReceiptData();
    }

    if (isEdit) {
      setState(() {
        isEditLoading = false;
      });
    }
  }

  @override
  void dispose() {
    studentSearchCtrl.dispose();
    discountCtrl.dispose();
    fineCtrl.dispose();
    receiptCtrl.dispose();
    narrationCtrl.dispose();
    super.dispose();
  }

  Future<void> loadReceiptData() async {
    final response = await ApiService.post(
      context,
      "/admin/receipt/edit",
      body: {"ReceiptId": widget.receiptId},
    );

    if (response != null && response.statusCode == 200) {
      final data = jsonDecode(response.body);

      receiptDate = DateTime.parse(data["Date"]);
      payMode = data["Mode"];
      selectedAccountantId = int.tryParse(data["PayBy"].toString());
      if (selectedAccountantId != null) {
        final accountant = accountants.firstWhere(
          (e) => e["id"].toString() == selectedAccountantId.toString(),
          orElse: () => {},
        );

        if (accountant.isNotEmpty) {
          collectedBy = accountant["EmployeeName"] ?? "Please Select";
        }
      }
      narrationCtrl.text = data["Remark"] ?? "";
      discountCtrl.text = data["Discount"].toString();
      fineCtrl.text = data["Fine"].toString();
      previousReceiptAmount = double.tryParse(data["Amount"].toString()) ?? 0;
      receiptCtrl.text = data["Amount"].toString();

      final studentId = int.parse(data["StudentId"]);

      selectedStudent = studentList.firstWhere((e) => e.id == studentId);

      await fetchStudentBalance(studentId);
    }
  }

  Future<void> saveReceipt() async {
    /// STUDENT VALIDATION
    if (selectedStudent == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select student")));
      return;
    }

    /// PAY MODE VALIDATION
    if (payMode == 'Please Select' || payMode.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select pay mode")));
      return;
    }

    /// COLLECTED BY VALIDATION
    if (selectedAccountantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select collected by")),
      );
      return;
    }

    /// RECEIPT AMOUNT VALIDATION
    if (receiptCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Receipt amount cannot be empty")),
      );
      return;
    }

    setState(() => isSaving = true);

    final body = {
      "StudentId": selectedStudent!.id,
      "Date":
          "${receiptDate.year}-${receiptDate.month.toString().padLeft(2, '0')}-${receiptDate.day.toString().padLeft(2, '0')}",
      "Mode": payMode,
      "PayBy": selectedAccountantId,
      "Remark": narrationCtrl.text,
      "Due": dueAmount.toStringAsFixed(0),
      "Discount": discountCtrl.text.isEmpty ? "0" : discountCtrl.text,
      "Fine": fineCtrl.text.isEmpty ? "0" : fineCtrl.text,
      "Amount": receiptCtrl.text.isEmpty ? "0" : receiptCtrl.text,
      "Balance": calculatedBalance.toStringAsFixed(0),

      if (isEdit) "Type": "update",
      if (isEdit) "ReceiptId": widget.receiptId,
    };

    final response = await ApiService.post(
      context,
      "/admin/receipt/store",
      body: body,
    );

    setState(() => isSaving = false);

    if (response != null && response.statusCode == 200) {
      Navigator.pop(context, true);
    }
  }

  Future<void> fetchStudentBalance(int id) async {
    setState(() => isBalanceLoading = true);

    final response = await ApiService.post(
      context,
      "/get_balance",
      body: {"type": "student", "id": id},
    );

    if (response != null && response.statusCode == 200) {
      final data = jsonDecode(response.body);

      double fine = double.tryParse(data["fine"].toString()) ?? 0;
      double amount = double.tryParse(data["amount"].toString()) ?? 0;

      setState(() {
        dueAmount = fine + amount;
        calculateBalance();
      });
    }

    setState(() => isBalanceLoading = false);
  }

  Future<void> fetchStudents() async {
    setState(() => isLoadingStudents = true);

    final res = await ApiService.post(context, "/get_student");

    if (res != null && res.statusCode == 200) {
      final List data = jsonDecode(res.body);

      studentList = data.map((e) => StudentModel.fromJson(e)).toList();
      filteredStudents = List.from(studentList);
    }

    setState(() => isLoadingStudents = false);
  }

  Future<void> fetchAccountants() async {
    final response = await ApiService.post(
      context,
      "/get_employee",
      body: {"type": "accountant"},
    );

    if (response != null && response.statusCode == 200) {
      final data = jsonDecode(response.body);

      accountants = List<Map<String, dynamic>>.from(data);

      if (accountants.isNotEmpty && !isEdit) {
        selectedAccountantId = accountants.first["id"];
        collectedBy = accountants.first["EmployeeName"];
      }
    }

    setState(() {});
  }

  Future<void> fetchPayModes() async {
    setState(() => isLoadingData = true);

    final response = await ApiService.post(context, "/get_mode");

    if (response != null && response.statusCode == 200) {
      final data = jsonDecode(response.body);

      payModes = List<String>.from(data.map((e) => e["Paymode"].toString()));

      if (payModes.isNotEmpty && !isEdit) {
        payMode = payModes.first;
      }
    }

    setState(() => isLoadingData = false);
  }

  void calculateBalance() {
    double discount = double.tryParse(discountCtrl.text) ?? 0;
    double fine = double.tryParse(fineCtrl.text) ?? 0;
    double receipt = double.tryParse(receiptCtrl.text) ?? 0;

    double total = dueAmount - discount + fine;

    if (isEdit) {
      total = total + previousReceiptAmount;
    }

    setState(() {
      calculatedBalance = total - receipt;
    });
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
        title: Text(
          isEdit ? "Edit Receipt" : "Add Receipt",
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),

        centerTitle: true,
      ),

      body: (isEdit && isEditLoading)
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        _card(
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Date",
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(height: 4),
                                        InkWell(
                                          onTap: _pickReceiptDate,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Container(
                                            height: 40,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.calendar_today,
                                                  size: 16,
                                                  color: Colors.grey,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    "${receiptDate.day}-${receiptDate.month}-${receiptDate.year}",
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons.arrow_drop_down,
                                                  color: Colors.grey,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Pay Mode",
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(height: 4),
                                        PopupMenuButton<String>(
                                          onSelected: (v) {
                                            setState(() {
                                              payMode = v;
                                            });
                                          },
                                          itemBuilder: (_) => payModes
                                              .map(
                                                (e) => PopupMenuItem(
                                                  value: e,
                                                  child: Text(e),
                                                ),
                                              )
                                              .toList(),

                                          child: Container(
                                            height: 40,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.payments,
                                                  size: 16,
                                                  color: Colors.grey,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    payMode,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons.arrow_drop_down,
                                                  color: Colors.grey,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    showStudentDropdown = !showStudentDropdown;
                                  });
                                },
                                child: Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.person,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          selectedStudent == null
                                              ? "Select Student Name"
                                              : "${selectedStudent!.name} / ${selectedStudent!.studentClass} (${selectedStudent!.section})",
                                          style: const TextStyle(fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Icon(
                                        showStudentDropdown
                                            ? Icons.arrow_drop_up
                                            : Icons.arrow_drop_down,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // 👇 DROPDOWN LIST
                              if (showStudentDropdown) _studentDropdownList(),
                            ],
                          ),
                        ),

                        if (selectedStudent != null)
                          _card(
                            child: Column(
                              children: [
                                Container(
                                  height: 40,
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Text(
                                        "Due Amount",
                                        style: TextStyle(fontSize: 13),
                                      ),
                                      const Spacer(),
                                      isBalanceLoading
                                          ? CircularProgressIndicator()
                                          : Text(
                                              "₹ ${dueAmount.toStringAsFixed(0)}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.red,
                                              ),
                                            ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: _input(
                                        "Discount",
                                        "Enter Discount",
                                        controller: discountCtrl,
                                        keyboardType:
                                            TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        isNumber: true,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _input(
                                        "Fine",
                                        "Enter Fine",
                                        controller: fineCtrl,
                                        keyboardType:
                                            TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        isNumber: true,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: _input(
                                        "Receipt Amount",
                                        "Receipt Amount",
                                        controller: receiptCtrl,
                                        keyboardType:
                                            TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        isNumber: true,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Balance",
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            height: 40,
                                            alignment: Alignment.centerLeft,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Spacer(),
                                                Text(
                                                  "₹ ${calculatedBalance.toStringAsFixed(0)}",
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                PopupMenuButton<Map<String, dynamic>>(
                                  onSelected: (v) {
                                    setState(() {
                                      selectedAccountantId = v["id"];
                                      collectedBy = v["EmployeeName"];
                                    });
                                  },
                                  itemBuilder: (_) => accountants
                                      .map(
                                        (e) => PopupMenuItem(
                                          value: e,
                                          child: Text(e["EmployeeName"]),
                                        ),
                                      )
                                      .toList(),
                                  child: _dropdown("Collected By", collectedBy),
                                ),

                                const SizedBox(height: 8),
                                _input(
                                  "Narration",
                                  "Enter remark/narration...",
                                  maxLines: 2,
                                  controller: narrationCtrl,
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 10),

                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: isSaving ? null : saveReceipt,
                            icon: isSaving
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.save,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                            label: Text(
                              isEdit ? "Update Receipt" : "Save Receipt",
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
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

  Widget _studentDropdownList() {
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
                controller: studentSearchCtrl,
                decoration: const InputDecoration(
                  hintText: "Search student...",
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (value) {
                  setState(() {
                    filteredStudents = studentList.where((s) {
                      return s.name.toLowerCase().contains(
                            value.toLowerCase(),
                          ) ||
                          s.father.toLowerCase().contains(
                            value.toLowerCase(),
                          ) ||
                          s.ledgerNo.toLowerCase().contains(
                            value.toLowerCase(),
                          );
                    }).toList();
                  });
                },
              ),
            ),
          ),

          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 150),
            child: isLoadingStudents
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
                        onTap: () async {
                          setState(() {
                            selectedStudent = s;
                            showStudentDropdown = false;
                            dueAmount = 0;
                          });

                          await fetchStudentBalance(s.id);
                        },

                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selectedStudent?.id == s.id
                                ? Colors.blue.shade50
                                : Colors.white,
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          child: Text(
                            "${s.name} CO: ${s.father} / ${s.studentClass} (${s.section}) - ${s.ledgerNo}",
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
}

// ================= COMMON CARD =================
Widget _card({required Widget child}) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(padding: const EdgeInsets.all(10), child: child),
  );
}

// ================= DROPDOWN =================
Widget _dropdown(String label, String value) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(Icons.person, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
      const SizedBox(height: 4),
      Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    ],
  );
}

Widget _input(
  String label,
  String hint, {
  IconData? icon,
  int maxLines = 1,
  TextEditingController? controller,
  TextInputType keyboardType = TextInputType.text,
  bool isNumber = false,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          if (icon != null) Icon(icon, size: 16, color: Colors.grey),
          if (icon != null) const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
      const SizedBox(height: 4),
      TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: isNumber
            ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))]
            : null,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 12,
          ),
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ],
  );
}
