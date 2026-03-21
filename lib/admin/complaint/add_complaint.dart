import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';

class AdminAddComplaint extends StatefulWidget {
  const AdminAddComplaint({super.key});

  @override
  State<AdminAddComplaint> createState() => _AdminAddComplaintState();
}

class _AdminAddComplaintState extends State<AdminAddComplaint> {
  List<Map<String, dynamic>> studentList = [];

  String? selectedStudentName;
  String? selectedStudentId;

  final TextEditingController descCtrl = TextEditingController();
  bool showStudentDropdown = false;

  TextEditingController studentSearchCtrl = TextEditingController();

  List<Map<String, dynamic>> filteredStudents = [];
  bool isLoading = false;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  // ================= LOAD STUDENTS =================
  Future<void> _loadStudents() async {
    setState(() => isLoading = true);

    final response = await ApiService.post(context, "/get_student");

    if (response != null && response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      setState(() {
        studentList = data.cast<Map<String, dynamic>>();
        filteredStudents = studentList;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  // ================= SAVE COMPLAINT =================
  Future<void> _saveComplaint() async {
    if (selectedStudentId == null) {
      _showMsg("Please select student");
      return;
    }

    if (descCtrl.text.trim().isEmpty) {
      _showMsg("Please enter description");
      return;
    }

    setState(() => isSubmitting = true);

    final response = await ApiService.post(
      context,
      "/admin/complaint/store",
      body: {
        "StudentId": selectedStudentId!,
        "Description": descCtrl.text.trim(),
      },
    );

    setState(() => isSubmitting = false);

    if (response != null && response.statusCode == 200) {
      _showMsg("Complaint Saved Successfully");
      Navigator.pop(context, true);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4e9fb),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: const BackButton(),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Add Complaint",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Add New Complaint",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// STUDENT LABEL
                    const Text("Student Name*", style: TextStyle(fontSize: 14)),

                    const SizedBox(height: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              showStudentDropdown = !showStudentDropdown;
                              filteredStudents = studentList;
                            });
                          },
                          child: _boxText(
                            selectedStudentName ?? "Select Student",
                            isDropdown: true,
                          ),
                        ),

                        if (showStudentDropdown) _studentDropdownList(),
                      ],
                    ),

                    const SizedBox(height: 16),

                    /// DESCRIPTION
                    const Text("Description", style: TextStyle(fontSize: 14)),

                    const SizedBox(height: 6),

                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "Write Complaint in Detail",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: isSubmitting ? null : _saveComplaint,
                        icon: const Icon(
                          Icons.save,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: isSubmitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Save",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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

  Widget _boxText(String text, {bool isDropdown = false}) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
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
          /// SEARCH
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
                      return s["StudentName"].toString().toLowerCase().contains(
                            value.toLowerCase(),
                          ) ||
                          s["ContactNo"].toString().toLowerCase().contains(
                            value.toLowerCase(),
                          );
                    }).toList();
                  });
                },
              ),
            ),
          ),

          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filteredStudents.length,
              itemBuilder: (context, index) {
                final s = filteredStudents[index];

                final display =
                    "${s["StudentName"]} / ${s["Class"]}-${s["Section"]} / ${s["ContactNo"]}";

                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedStudentName = display;
                      selectedStudentId = s["id"].toString();
                      showStudentDropdown = false;
                      studentSearchCtrl.clear();
                      filteredStudents = studentList;
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
                    child: Text(display, style: const TextStyle(fontSize: 13)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
