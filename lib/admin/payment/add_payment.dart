import 'dart:convert';

import 'package:sonia_public_school/admin/helper.dart';
import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';
import 'package:flutter/services.dart';

class AddPaymentPage extends StatefulWidget {
  final String? paymentId;

  const AddPaymentPage({super.key, this.paymentId});

  @override
  State<AddPaymentPage> createState() => _AddPaymentPageState();
}

class _AddPaymentPageState extends State<AddPaymentPage> {
  final dueCtrl = TextEditingController(text: '0');
  final payCtrl = TextEditingController();
  final afterDueCtrl = TextEditingController(text: '0');
  final narrationCtrl = TextEditingController();
  String paymentType = 'Employee Wise';
  String? selectedPersonId;
  String selectedPersonName = '--Select--';
  bool isPageLoading = false;
  bool isSaving = false;
  final TextEditingController typeCtrl = TextEditingController(
    text: 'Employee Wise',
  );
  final TextEditingController payModeCtrl = TextEditingController();
  String? selectedAccountantId;
  String selectedAccountantName = '--Select--';
  List<Map<String, dynamic>> typeList = [
    {"label": "Employee Wise", "value": "Employee Wise"},
    {"label": "Supplier Wise", "value": "Supplier Wise"},
  ];
  List<Map<String, dynamic>> persons = [];
  List<Map<String, dynamic>> accountants = [];

  List<String> paymentModes = [];
  String paymentMode = '';
  final dateCtrl = TextEditingController();
  bool isEdit = false;
  final TextEditingController employeeCtrl = TextEditingController();
  final FocusNode employeeFocus = FocusNode();
  final GlobalKey employeeKey = GlobalKey();
  bool showBalanceFields = true;
  final TextEditingController accountantCtrl = TextEditingController();
  @override
  void initState() {
    super.initState();

    isEdit = widget.paymentId != null;

    dateCtrl.text = formatDisplayDate(DateTime.now());

    if (isEdit) {
      showBalanceFields = false;
      isPageLoading = true;
      fetchEditData();
    } else {
      fetchPayModes();
      fetchAccountants();
      fetchPersons(); // ✅ ADD THIS
    }

    payCtrl.addListener(() {
      final due = double.tryParse(dueCtrl.text) ?? 0;
      final pay = double.tryParse(payCtrl.text) ?? 0;

      final remaining = due - pay;

      afterDueCtrl.text = remaining.toStringAsFixed(0);
    });
  }

  Future<void> fetchEditData() async {
    print("===== EDIT MODE START =====");
    print("PaymentId: ${widget.paymentId}");

    final response = await ApiService.post(
      context,
      "/admin/payment/edit",
      body: {"Type": "employee", "PaymentId": widget.paymentId},
    );

    if (response != null && response.statusCode == 200) {
      final data = jsonDecode(response.body);

      print("Edit API Response: $data");

      paymentType = "Employee Wise";

      await fetchPayModes();
      await fetchPersons();
      await fetchAccountants();

      setState(() {
        selectedPersonId = data["EmployeeId"].toString();
        payCtrl.text = data["Amount"];
        narrationCtrl.text = data["Remark"]?.toString() ?? "";
        paymentMode = data["Mode"];
        selectedAccountantId = data["PayBy"];

        dateCtrl.text = formatDisplayDate(DateTime.parse(data["Date"]));

        // 👇 SET DROPDOWN NAMES

        final person = persons.firstWhere(
          (e) => e['id'].toString() == selectedPersonId,
          orElse: () => {},
        );

        if (person.isNotEmpty) {
          selectedPersonName = person['EmployeeName'];
          employeeCtrl.text = selectedPersonName;
        }
        final acc = accountants.firstWhere(
          (e) => e['id'].toString() == selectedAccountantId,
          orElse: () => {},
        );

        if (acc.isNotEmpty) {
          selectedAccountantName = acc['EmployeeName'];
          accountantCtrl.text = selectedAccountantName;
        }

        isPageLoading = false;
      });

      print("Selected Person: $selectedPersonName");
      print("Selected Accountant: $selectedAccountantName");
      print("===== EDIT PREFILL COMPLETE =====");
    } else {
      print("Edit API Failed");
      setState(() => isPageLoading = false);
    }
  }

  String formatDisplayDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year}";
  }

  String formatApiDate(String displayDate) {
    final parts = displayDate.split("-");
    return "${parts[2]}-${parts[1]}-${parts[0]}";
  }

  Future<void> savePayment() async {
    if (selectedPersonId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select employee or supplier")),
      );
      return;
    }
    if (payCtrl.text.trim().isEmpty || payCtrl.text == "0") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter payment amount")),
      );
      return;
    }
    if (paymentMode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select payment mode")),
      );
      return;
    }
    if (isSaving) return;

    setState(() => isSaving = true);

    String apiType = paymentType == "Employee Wise" ? "employee" : "supplier";

    final body = {
      "payment_type": apiType,
      "id": selectedPersonId,
      "Date": formatApiDate(dateCtrl.text),
      "Mode": paymentMode,
      "PayBy": selectedAccountantId,
      "Remark": narrationCtrl.text,
      "Amount": payCtrl.text,

      if (isEdit) "Type": "update",
      if (isEdit) "PaymentId": widget.paymentId,
    };

    print("===== STORE / UPDATE API BODY =====");
    print(body);

    final response = await ApiService.post(
      context,
      "/admin/payment/store",
      body: body,
    );

    setState(() => isSaving = false);

    if (response != null && response.statusCode == 200) {
      print("Payment Saved / Updated Successfully");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? "Payment Updated Successfully"
                : "Payment Saved Successfully",
          ),
        ),
      );

      Navigator.pop(context, true);
    } else {
      print("Payment Save Failed");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Something went wrong")));
    }
  }

  Future<void> fetchPayModes() async {
    final response = await ApiService.post(context, "/get_mode");
    if (response != null && response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        paymentModes = data
            .map<String>((e) => e['Paymode'].toString())
            .toList();
        if (paymentModes.isNotEmpty) {
          paymentMode = paymentModes.first;
          payModeCtrl.text = paymentModes.first;
        }
      });
    }
  }

  Future<void> fetchPersons() async {
    setState(() {
      persons = [];
      selectedPersonId = null;
      selectedPersonName = "--Select--";
      dueCtrl.text = "0";
      afterDueCtrl.text = "0";
    });

    if (paymentType == "Employee Wise") {
      final response = await ApiService.post(
        context,
        "/get_employee",
        body: {"type": "employee"},
      );

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          persons = List<Map<String, dynamic>>.from(data);
        });
      }
    } else {
      /// SUPPLIER API CALL
      final response = await ApiService.post(context, "/get_supplier");

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          persons = List<Map<String, dynamic>>.from(data);
        });
      }
    }
  }

  Future<void> fetchBalance(String id) async {
    String type = paymentType == "Employee Wise" ? "employee" : "supplier";

    print("===== FETCH BALANCE =====");
    print("Type: $type");
    print("ID: $id");

    final response = await ApiService.post(
      context,
      "/get_balance",
      body: {"type": type, "id": id},
    );

    if (response != null && response.statusCode == 200) {
      final data = jsonDecode(response.body);

      print("Balance API Response: $data");

      double fine = double.tryParse(data["fine"].toString()) ?? 0;
      double amount = double.tryParse(data["amount"].toString()) ?? 0;

      double totalDue = fine + amount;

      print("Fine: $fine");
      print("Amount: $amount");
      print("Total Due: $totalDue");

      setState(() {
        dueCtrl.text = totalDue.toStringAsFixed(0);
        payCtrl.clear();
        afterDueCtrl.text = totalDue.toStringAsFixed(0);
      });
    } else {
      print("Balance API Failed");
    }
  }

  Future<void> fetchAccountants() async {
    final response = await ApiService.post(
      context,
      "/get_employee",
      body: {"type": "accountant"},
    );

    if (response != null && response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        accountants = List<Map<String, dynamic>>.from(data);

        if (accountants.isNotEmpty) {
          selectedAccountantId = accountants.first['id'].toString();
          selectedAccountantName = accountants.first['EmployeeName'];

          accountantCtrl.text = accountants.first['EmployeeName'];
        }
      });
    }
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
          "Add Payment",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),

      body: isPageLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      /// ===== ROW 1 : DATE + TYPE =====
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
                                );

                                if (picked != null) {
                                  setState(() {
                                    dateCtrl.text = formatDisplayDate(picked);
                                  });
                                }
                              },
                              child: AbsorbPointer(
                                child: _input("Date", "", controller: dateCtrl),
                              ),
                            ),
                          ),

                          const SizedBox(width: 6),

                          if (!isEdit)
                            Expanded(
                              child: ReusableOverlayDropdown(
                                label: "Type*",
                                hint: "Select Type",
                                list: typeList,
                                labelKey: "label",
                                valueKey: "value",
                                controller: typeCtrl,
                                onSelected: (value, label) {
                                  setState(() {
                                    paymentType = value;
                                    typeCtrl.text = label;

                                    employeeCtrl.clear();
                                    selectedPersonId = null;
                                    selectedPersonName = "--Select--";
                                  });

                                  fetchPersons();
                                },
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      /// ===== ROW 2 : EMPLOYEE / SUPPLIER =====
                      ReusableOverlayDropdown(
                        label: paymentType == "Employee Wise"
                            ? "Employee*"
                            : "Supplier*",
                        hint: "Select",
                        list: persons,
                        labelKey: paymentType == "Employee Wise"
                            ? "EmployeeName"
                            : "SupplierName",
                        valueKey: "id",
                        controller: employeeCtrl,
                        onSelected: (value, label) {
                          setState(() {
                            selectedPersonId = value;
                            selectedPersonName = label;
                            showBalanceFields = true;
                          });

                          fetchBalance(value);
                        },
                      ),
                      const SizedBox(height: 8),

                      /// ===== ROW 3 : PAY MODE + PAID BY =====
                      Row(
                        children: [
                          Expanded(
                            child: ReusableOverlayDropdown(
                              label: "Pay Mode*",
                              hint: "Select Mode",
                              list: paymentModes
                                  .map((e) => {"label": e, "value": e})
                                  .toList(),
                              labelKey: "label",
                              valueKey: "value",
                              controller: payModeCtrl,
                              onSelected: (value, label) {
                                setState(() {
                                  paymentMode = value;
                                  payModeCtrl.text = label;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ReusableOverlayDropdown(
                              label: "Paid By*",
                              hint: "Select Accountant",
                              list: accountants,
                              labelKey: "EmployeeName",
                              valueKey: "id",
                              controller: accountantCtrl,
                              onSelected: (value, label) {
                                setState(() {
                                  selectedAccountantId = value;
                                  selectedAccountantName = label;
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      /// ===== ROW 4 : DUE + AMOUNT =====
                      if (showBalanceFields)
                        Row(
                          children: [
                            Expanded(
                              child: _input(
                                "Due",
                                "0",
                                enabled: false,
                                controller: dueCtrl,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _input(
                                "Amount*",
                                "",

                                controller: payCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        _input(
                          "Amount*",
                          "0",
                          controller: payCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),

                      const SizedBox(height: 8),

                      /// ===== ROW 5 : REMAINING =====
                      if (showBalanceFields)
                        _input(
                          "Remaining Due",
                          "0",
                          enabled: false,
                          controller: afterDueCtrl,
                        ),

                      const SizedBox(height: 8),

                      /// ===== ROW 6 : REMARKS =====
                      _input(
                        "Remarks",
                        "Enter remarks...",
                        controller: narrationCtrl,
                        maxLines: 2,
                      ),

                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : savePayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.save,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isEdit
                                          ? "Update Payment"
                                          : "Save Payment",
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ================= INPUT FIELD =================
  Widget _input(
    String label,
    String hint, {
    bool enabled = true,
    String? suffix,
    int maxLines = 1,
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            enabled: enabled,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              suffixText: suffix,
              filled: true,
              fillColor: enabled ? Colors.white : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
