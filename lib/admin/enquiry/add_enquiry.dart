import 'dart:convert';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';

class AddEnquiryPage extends StatefulWidget {
  final int? enquiryId; // 👈 add this

  const AddEnquiryPage({super.key, this.enquiryId});

  @override
  State<AddEnquiryPage> createState() => _AddEnquiryPageState();

  static Widget _headerCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _AddEnquiryPageState extends State<AddEnquiryPage> {
  final fatherCtrl = TextEditingController();
  final motherCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final remarkCtrl = TextEditingController();
  final followUpDateCtrl = TextEditingController();
  List<Map<String, dynamic>> classList = [];
  bool isEditLoading = false;

  List<TextEditingController> childNameCtrls = List.generate(
    3,
    (_) => TextEditingController(),
  );
  bool isSubmitting = false;

  List<String?> selectedDOB = List.generate(3, (_) => null);
  List<String?> selectedClass = List.generate(3, (_) => null);

  @override
  void initState() {
    super.initState();
    fetchClasses();

    if (widget.enquiryId != null) {
      fetchEnquiryDetails();
    }
  }

  Future<void> fetchEnquiryDetails() async {
    setState(() => isEditLoading = true);

    final response = await ApiService.post(
      context,
      "/admin/student/enquiry/edit",
      body: {"EnquiryId": widget.enquiryId.toString()},
    );

    if (response != null && response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data.isNotEmpty) {
        final enquiry = data[0];

        fatherCtrl.text = enquiry['FatherName'] ?? "";
        motherCtrl.text = enquiry['MotherName'] ?? "";
        mobileCtrl.text = enquiry['MobileNo'] ?? "";
        addressCtrl.text = enquiry['Address'] ?? "";
        followUpDateCtrl.text = enquiry['FollowUpDate'] ?? "";
        remarkCtrl.text = enquiry['Remark'] ?? "";

        List students = enquiry['students'] ?? [];

        for (int i = 0; i < students.length && i < 3; i++) {
          childNameCtrls[i].text = students[i]['ChildName'] ?? "";
          selectedDOB[i] = students[i]['DOB'];
          selectedClass[i] = students[i]['Class']?.toString();
        }

        setState(() {});
      }
    }

    setState(() => isEditLoading = false);
  }

  Future<void> fetchClasses() async {
    final res = await ApiService.post(context, "/get_class");

    if (res != null && res.statusCode == 200) {
      setState(() {
        classList = List<Map<String, dynamic>>.from(jsonDecode(res.body));
      });
    }
  }

  Future<void> submitEnquiry() async {
    if (fatherCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Father name is required"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (motherCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mother name is required"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (mobileCtrl.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mobile number must be 10 digits"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (followUpDateCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Follow up date is required"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => isSubmitting = true);

    List<Map<String, dynamic>> students = [];

    for (int i = 0; i < childNameCtrls.length; i++) {
      if (childNameCtrls[i].text.trim().isNotEmpty) {
        if (selectedDOB[i] == null || selectedClass[i] == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Complete details for child ${i + 1}"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        students.add({
          "ChildName": childNameCtrls[i].text,
          "DOB": selectedDOB[i],
          "Class": selectedClass[i],
        });
      }
    }
    if (students.isEmpty) {
      setState(() => isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please add at least one child with name, DOB and class",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    Map<String, dynamic> body = {
      "FatherName": fatherCtrl.text,
      "MotherName": motherCtrl.text,
      "MobileNo": mobileCtrl.text,
      "Address": addressCtrl.text,
      "FollowUpDate": followUpDateCtrl.text,
      "Remark": remarkCtrl.text,
      "students": students,
    };

    if (widget.enquiryId != null) {
      body["Type"] = "update";
      body["EnquiryId"] = widget.enquiryId.toString();
      body["Status"] = "Pending";
    }

    print("FINAL BODY: ${jsonEncode(body)}");

    final response = await ApiService.post(
      context,
      "/admin/student/enquiry/store",
      body: body,
    );

    setState(() => isSubmitting = false);

    if (response != null && response.statusCode == 200) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6ECF9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: const BackButton(),
        title: Text(
          widget.enquiryId == null
              ? 'Add Admission Enquiry'
              : 'Edit Admission Enquiry',

          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: isEditLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(
                      'Father Name *',
                      Icons.person,
                      const Color(0xffF4A261),
                    ),
                    _input('Enter Father\'s Name', controller: fatherCtrl),

                    _label(
                      'Mother Name *',
                      Icons.person_outline,
                      const Color(0xffE76F51),
                    ),
                    _input('Enter Mother\'s Name', controller: motherCtrl),

                    _label(
                      'Mobile Number *',
                      Icons.call,
                      const Color(0xff6CC04A),
                    ),
                    _input(
                      'Enter Mobile Number',
                      controller: mobileCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      isMobile: true,
                    ),

                    _label('Address *', Icons.home, const Color(0xff6FA8DC)),
                    _input(
                      'Enter Current Address',
                      maxLines: 2,
                      controller: addressCtrl,
                    ),
                    _label(
                      'Follow up date *',
                      Icons.calendar_month,
                      const Color(0xff6FA8DC),
                    ),
                    GestureDetector(
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );

                        if (picked != null) {
                          String formatted =
                              "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                          followUpDateCtrl.text = formatted;
                          setState(() {});
                        }
                      },
                      child: AbsorbPointer(
                        child: _input(
                          'Select Follow Up Date',
                          controller: followUpDateCtrl,
                        ),
                      ),
                    ),

                    _label('Remarks', Icons.home, const Color(0xff6FA8DC)),
                    _input(
                      'Write your Remarks',
                      maxLines: 2,
                      controller: remarkCtrl,
                    ),

                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 6),

                    const Text(
                      'Child Details',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    _childHeader(),
                    _childRow(1),
                    _childRow(2),
                    _childRow(3),

                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: isSubmitting ? null : submitEnquiry,
                      child: Container(
                        height: 42,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          color: isSubmitting ? Colors.grey : AppColors.primary,
                        ),
                        child: Center(
                          child: isSubmitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.done,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Submit',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _label(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _input(
    String hint, {
    int maxLines = 1,
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    bool isMobile = false,
  }) {
    return Container(
      height: maxLines == 1 ? 38 : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xffFAF7FC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        maxLength: maxLength,
        inputFormatters: isMobile
            ? [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ]
            : null,
        decoration: InputDecoration(
          counterText: "",
          isDense: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _childHeader() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.danger, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          AddEnquiryPage._headerCell('#', flex: 1),
          AddEnquiryPage._headerCell('Name Of The Child *', flex: 3),
          AddEnquiryPage._headerCell('DOB *', flex: 2),
          AddEnquiryPage._headerCell('Admission In Class *', flex: 3),
        ],
      ),
    );
  }

  Widget _childRow(int index) {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          _cell(Text(index.toString()), flex: 1),
          _cell(
            TextField(
              controller: childNameCtrls[index - 1],
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Name',
                isDense: true,
              ),
            ),

            flex: 3,
          ),
          _cell(
            GestureDetector(
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime(2015),
                  firstDate: DateTime(1995),
                  lastDate: DateTime.now(),
                );

                if (picked != null) {
                  selectedDOB[index - 1] =
                      "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                  setState(() {});
                }
              },
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedDOB[index - 1] ?? "Select DOB",
                      style: TextStyle(
                        fontSize: 12,
                        color: selectedDOB[index - 1] == null
                            ? Colors.grey
                            : Colors.black,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
            flex: 2,
          ),
          _cell(
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: selectedClass[index - 1],
                hint: const Text(
                  "Select Class",
                  style: TextStyle(fontSize: 12),
                ),
                items: classList.map((e) {
                  return DropdownMenuItem<String>(
                    value: e['id'].toString(),
                    child: Text(
                      e['Class'],
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedClass[index - 1] = value;
                  });
                },
              ),
            ),
            flex: 3,
          ),
        ],
      ),
    );
  }

  Widget _cell(Widget child, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: child,
      ),
    );
  }
}
