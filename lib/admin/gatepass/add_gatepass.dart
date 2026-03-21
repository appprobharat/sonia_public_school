import 'dart:convert';

import 'package:sonia_public_school/admin/helper.dart';
import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';
import 'package:flutter/services.dart';

class AddGatePassPage extends StatefulWidget {
  final String? gatePassId;

  const AddGatePassPage({super.key, this.gatePassId});

  @override
  State<AddGatePassPage> createState() => _AddGatePassPageState();
}

class _AddGatePassPageState extends State<AddGatePassPage> {
  String selectedType = "Student";
  String selectedEmployee = "--Select Any One--";
  String selectedApprover = "--Select Any One--";
  bool isEdit = false;
  String selectedApproverName = "";
  String selectedApproverId = "";
  bool isLoadingEdit = false;

  String? gatePassId;
  String? selectedUserId;
  final TextEditingController studentDropdownCtrl = TextEditingController();
  final TextEditingController employeeDropdownCtrl = TextEditingController();
  final TextEditingController approverDropdownCtrl = TextEditingController();
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  final TextEditingController typeCtrl = TextEditingController(text: "Student");

  final List<Map<String, dynamic>> typeList = [
    {"label": "Student", "value": "Student"},
    {"label": "Employee", "value": "Employee"},
  ];
  final TextEditingController contactCtrl = TextEditingController();

  // Controllers
  final TextEditingController reasonCtrl = TextEditingController();
  final TextEditingController recommenderCtrl = TextEditingController();
  final TextEditingController receiverCtrl = TextEditingController();
  final TextEditingController relationCtrl = TextEditingController();
  List<Map<String, dynamic>> studentList = [];
  List<Map<String, dynamic>> employeeList = [];
  String selectedStudentName = "";
  String selectedEmployeeName = "";
  final TextEditingController studentCtrl = TextEditingController();
  bool showStudentDropdown = false;
  TextEditingController studentSearchCtrl = TextEditingController();
  List<Map<String, dynamic>> filteredStudents = [];

  DateTime? startDate;
  DateTime? dateTime;
  String selectedStudent = "--Select Any One--";

  @override
  void initState() {
    super.initState();

    if (widget.gatePassId != null) {
      isEdit = true;
      gatePassId = widget.gatePassId;
      _initializeEdit();
    } else {
      _loadStudents();
      _loadEmployees();
    }
  }

  @override
  void dispose() {
    studentCtrl.dispose();
    super.dispose();
  }

  Future<void> _initializeEdit() async {
    setState(() => isLoadingEdit = true);

    await Future.wait([_loadStudents(), _loadEmployees()]);

    await _loadEditData();

    setState(() => isLoadingEdit = false);
  }

  Future<void> _loadEditData() async {
    setState(() => isLoadingEdit = true);

    final response = await ApiService.post(
      context,
      "/admin/gatepass/edit",
      body: {"GatePassId": gatePassId},
    );

    if (response != null && response.statusCode == 200) {
      final data = jsonDecode(response.body);

      /// 🔥 TYPE
      if (data["Type"] == "std") {
        selectedType = "Student";
        selectedUserId = data["StudentId"].toString();
      } else {
        selectedType = "Employee";
        selectedUserId = data["EmployeeId"].toString();
      }

      /// 🔥 DATE
      selectedDate = DateTime.parse(data["Date"]);

      /// 🔥 TIME
      final timeParts = data["Time"].split(":");
      selectedTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );

      /// 🔥 TEXTFIELDS
      reasonCtrl.text = data["LeavingReason"] ?? "";
      recommenderCtrl.text = data["Recommender"] ?? "";
      receiverCtrl.text = data["ReceivedBy"] ?? "";
      relationCtrl.text = data["Relation"] ?? "";
      contactCtrl.text = data["ContactNo"]?.toString() ?? "";
      studentDropdownCtrl.text = selectedStudentName;
      employeeDropdownCtrl.text = selectedEmployeeName;
      approverDropdownCtrl.text = selectedApproverName;

      /// 🔥 APPROVER
      selectedApproverId = data["Approver"].toString();

      if (selectedType == "Student") {
        final student = studentList.firstWhere(
          (e) => e["id"].toString() == selectedUserId,
          orElse: () => {},
        );

        selectedStudentName =
            "${student["StudentName"]} (${student["Class"]}-${student["Section"]})";
      } else {
        final emp = employeeList.firstWhere(
          (e) => e["id"].toString() == selectedUserId,
          orElse: () => {},
        );

        selectedEmployeeName =
            "${emp["EmployeeName"]} (${emp["Designation"]}) / ${emp["ContactNo"]}";
      }

      /// 🔥 Approver Name
      final approver = employeeList.firstWhere(
        (e) => e["id"].toString() == selectedApproverId,
        orElse: () => {},
      );

      selectedApproverName =
          "${approver["EmployeeName"]} (${approver["Designation"]})";

      setState(() => isLoadingEdit = false);
    } else {
      setState(() => isLoadingEdit = false);
    }
  }

  Future<void> _loadStudents() async {
    final response = await ApiService.post(context, "/get_student");

    if (response != null && response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      setState(() {
        studentList = data.cast<Map<String, dynamic>>();
      });
    }
  }

  Future<void> _loadEmployees() async {
    final response = await ApiService.post(context, "/get_employee");

    if (response != null && response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      setState(() {
        employeeList = data.cast<Map<String, dynamic>>();
      });
    }
  }

  String getFormattedDate() {
    return "${selectedDate.year.toString().padLeft(4, '0')}-"
        "${selectedDate.month.toString().padLeft(2, '0')}-"
        "${selectedDate.day.toString().padLeft(2, '0')}";
  }

  String getFormattedTime() {
    final now = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    return "${now.hour.toString().padLeft(2, '0')}:"
        "${now.minute.toString().padLeft(2, '0')}:00";
  }

  Future<void> _saveGatePass() async {
    if (selectedUserId == null || selectedUserId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            selectedType == "Student"
                ? "Please select a student"
                : "Please select an employee",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (contactCtrl.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Contact number must be exactly 10 digits"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    /// REASON VALIDATION
  if (reasonCtrl.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Reason is required"),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
/// APPROVER VALIDATION
if (selectedApproverId.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Please select approver"),
      backgroundColor: Colors.red,
    ),
  );
  return;
}
    final Map<String, String> body = {
      "UserType": selectedType == "Student" ? "std" : "emp",
      "id": selectedUserId ?? "",
      "Date": getFormattedDate(),
      "Time": getFormattedTime(),
      "Reason": reasonCtrl.text.trim(),
      "Recommender": recommenderCtrl.text.trim(),
      "Approver": selectedApproverId,
      "ReceivedBy": receiverCtrl.text.trim(),
      "ContactNo": contactCtrl.text.trim(),
      "Relation": relationCtrl.text.trim(),
    };

    // Only in update
    if (isEdit) {
      body["Type"] = "update";
      body["GatePassId"] = gatePassId ?? "";
    }

    final response = await ApiService.post(
      context,
      "/admin/gatepass/store",
      body: body,
    );

    if (response != null && response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? "Gate Pass Updated Successfully"
                : "Gate Pass Added Successfully",
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
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
          "Add Gatepass",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),

      body: isLoadingEdit
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  _card(
                    child: Column(
                      children: [
                        // 1️⃣ TYPE
                        Opacity(
                          opacity: isEdit ? 0.6 : 1,
                          child: AbsorbPointer(
                            absorbing: isEdit,
                            child: ReusableOverlayDropdown(
                              label: "Type*",
                              hint: "Select Type",
                              list: typeList,
                              labelKey: "label",
                              valueKey: "value",
                              controller: typeCtrl,

                              onSelected: (value, label) async {
                                setState(() {
                                  selectedType = value;
                                  typeCtrl.text = label;

                                  selectedStudentName = "";
                                  selectedEmployeeName = "";
                                  selectedUserId = null;

                                  studentDropdownCtrl.clear();
                                  employeeDropdownCtrl.clear();
                                });

                                if (value == "Student") {
                                  await _loadStudents();
                                } else {
                                  await _loadEmployees();
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 2️⃣ STUDENT / EMPLOYEE
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedType == "Student"
                                  ? "Student*"
                                  : "Employee*",
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),

                            InkWell(
                              onTap: () {
                                setState(() {
                                  showStudentDropdown = !showStudentDropdown;

                                  if (selectedType == "Student") {
                                    filteredStudents = studentList;
                                  } else {
                                    filteredStudents = employeeList;
                                  }
                                });
                              },
                              child: _boxText(
                                selectedType == "Student"
                                    ? (selectedStudentName.isEmpty
                                          ? "Select Student"
                                          : selectedStudentName)
                                    : (selectedEmployeeName.isEmpty
                                          ? "Select Employee"
                                          : selectedEmployeeName),
                                isDropdown: true,
                              ),
                            ),

                            if (showStudentDropdown) _studentDropdownList(),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // 3️⃣ DATE + TIME
                        Row(
                          children: [
                            Expanded(child: _dateBlock()),
                            const SizedBox(width: 8),
                            Expanded(child: _timeBlock()),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // 4️⃣ REASON
                        _reasonField(),

                        const SizedBox(height: 8),

                        // 5️⃣ RECEIVED BY
                        _receiverField(),

                        const SizedBox(height: 8),

                        // 6️⃣ RELATION + CONTACT
                        Row(
                          children: [
                            Expanded(
                              child: _compactInput(
                                label: "Relation",
                                hint: "Enter Relation",
                                controller: relationCtrl,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: _contactField()),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // 7️⃣ RECOMMENDER + APPROVER
                        Row(
                          children: [
                            Expanded(child: _recommenderField()),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ReusableOverlayDropdown(
                                label: "Approver*",
                                hint: "Select Approver",

                                list: employeeList,

                                labelKey: "EmployeeName",
                                valueKey: "id",

                                controller: approverDropdownCtrl,

                                onSelected: (value, label) {
                                  final selected = employeeList.firstWhere(
                                    (e) => e["id"].toString() == value,
                                  );

                                  setState(() {
                                    selectedApproverId = value;
                                    selectedApproverName =
                                        "${selected["EmployeeName"]} (${selected["Designation"]})";

                                    approverDropdownCtrl.text =
                                        selectedApproverName;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _saveGatePass,
                      icon: const Icon(
                        Icons.done_all,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Save Gatepass",
                        style: TextStyle(fontSize: 15, color: Colors.white),
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
    );
  }

  // ================= COMMON CARD =================
  Widget _card({required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(10), child: child),
    );
  }

  // ================= DATE FIELD =================
  Widget _dateBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Date*", style: TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
            );
            if (picked != null) {
              setState(() => selectedDate = picked);
            }
          },
          child: _boxText(
            "${selectedDate.day}-${selectedDate.month}-${selectedDate.year}",
          ),
        ),
      ],
    );
  }

  // ================= DATE TIME =================
  Widget _timeBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Time*", style: TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: selectedTime,
            );
            if (picked != null) {
              setState(() => selectedTime = picked);
            }
          },
          child: _boxText(selectedTime.format(context)),
        ),
      ],
    );
  }

  Widget _contactField() {
    return _compactInput(
      label: "Contact No.*",
      hint: "Enter  number",
      controller: contactCtrl,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
    );
  }

  Widget _recommenderField() {
    return _compactInput(
      label: "Recommender",
      hint: "Recommendation",
      controller: recommenderCtrl,
    );
  }

  Widget _receiverField() {
    return _compactInput(
      label: "Received By",
      hint: "Received by ",
      controller: receiverCtrl,
    );
  }

  Widget _reasonField() {
    return _compactInput(
      label: "Reason For Leaving*",
      controller: reasonCtrl,
      hint: "Write your reason here!!  ",
      maxLines: 3,
      height: 80,
    );
  }

  Widget _compactInput({
    required String label,
    required TextEditingController controller,
    String hint = "",
    int maxLines = 1,
    double height = 40,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  // ================= BOX TEXT =================
  Widget _boxText(String text, {bool isDropdown = false}) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
          if (isDropdown) const Icon(Icons.arrow_drop_down, color: Colors.grey),
        ],
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
                  hintText: "Search...",
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (value) {
                  setState(() {
                    final list = selectedType == "Student"
                        ? studentList
                        : employeeList;

                    filteredStudents = list.where((s) {
                      return (selectedType == "Student"
                              ? s["StudentName"]
                              : s["EmployeeName"])
                          .toString()
                          .toLowerCase()
                          .contains(value.toLowerCase());
                    }).toList();
                  });
                },
              ),
            ),
          ),

          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 150),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filteredStudents.length,
              itemBuilder: (context, index) {
                final s = filteredStudents[index];

                return InkWell(
                  onTap: () {
                    if (selectedType == "Student") {
                      setState(() {
                        selectedStudentName =
                            "${s["StudentName"]} (${s["Class"]}-${s["Section"]})";

                        selectedUserId = s["id"].toString();
                        contactCtrl.text = s["ContactNo"].toString();
                      });
                    } else {
                      setState(() {
                        selectedEmployeeName =
                            "${s["EmployeeName"]} (${s["Designation"]})";

                        selectedUserId = s["id"].toString();
                        contactCtrl.text = s["ContactNo"].toString();
                      });
                    }

                    setState(() {
                      showStudentDropdown = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Text(
                      selectedType == "Student"
                          ? "${s["StudentName"]} (${s["Class"]}-${s["Section"]})"
                          : "${s["EmployeeName"]} (${s["Designation"]})",
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
