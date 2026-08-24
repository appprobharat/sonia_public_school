import 'dart:convert';
import 'dart:io';
import 'package:sonia_public_school/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class HolidayHomeworkPage extends StatefulWidget {
  final Map<String, dynamic>? homeworkData;

  const HolidayHomeworkPage({super.key, this.homeworkData});

  @override
  State<HolidayHomeworkPage> createState() => _HolidayHomeworkPageState();
}

class _HolidayHomeworkPageState extends State<HolidayHomeworkPage> {
  List<Map<String, dynamic>> classList = [];
  bool get isEdit => widget.homeworkData != null;
  String? selectedClassId;
  String selectedHoliday = "Summer";

  bool loadingClass = false;

  bool isLoading = true;
  bool _isSubmitting = false;

  File? selectedFile;
  String? selectedFileName;

  final titleController = TextEditingController();

  final descriptionController = TextEditingController();

  final List<Map<String, dynamic>> holidayList = [
    {"id": "Summer", "name": "Summer"},
    {"id": "Winter", "name": "Winter"},
    {"id": "Festival", "name": "Festival"},
    {"id": "National", "name": "National"},
    {"id": "Weekly", "name": "Weekly"},
  ];
  @override
  void initState() {
    super.initState();

    initializeData();
  }

  Future<void> initializeData() async {
    setState(() {
      isLoading = true;
    });

    await fetchClasses();

    if (isEdit) {
      await fetchEditData();
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchClasses() async {
    setState(() {
      loadingClass = true;
    });

    final res = await ApiService.post(context, "/get_class");

    if (res != null && res.statusCode == 200) {
      classList = List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }

    setState(() {
      loadingClass = false;
    });
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);

        selectedFileName = result.files.single.name;
      });
    }
  }

  Future<void> fetchEditData() async {
    if (!isEdit) return;

    try {
      final response = await ApiService.post(
        context,
        "/teacher/holiday/homework/edit",

        body: {"HomeworkId": widget.homeworkData!['HomeworkId'].toString()},
      );

      if (response == null) return;

      debugPrint("📥 EDIT STATUS => ${response.statusCode}");
      debugPrint("📥 EDIT RESPONSE => ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final data = decoded is List ? decoded.first : decoded;

        setState(() {
          selectedClassId = data['ClassId']?.toString();

          selectedHoliday = data['Type']?.toString() ?? "Summer";

          titleController.text = data['Title']?.toString() ?? '';

          descriptionController.text = data['Description']?.toString() ?? '';

          selectedFileName = data['Attachment']?.toString().split('/').last;
        });
      }
    } catch (e) {
      debugPrint("❌ EDIT FETCH ERROR => $e");
    }
  }

  Future<void> saveHomework() async {
    if (_isSubmitting) return;

    if (selectedClassId == null ||
        titleController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );

      return;
    }

    _isSubmitting = true;

    setState(() {});

    try {
      final response = await ApiService.multipartPost(
        context,

        isEdit
            ? "/teacher/holiday/homework/update"
            : "/teacher/holiday/homework/store",

        fields: {
          if (isEdit)
            "HomeworkId": widget.homeworkData!['HomeworkId'].toString(),

          "ClassId": selectedClassId.toString(),
          "Type": selectedHoliday,
          "Title": titleController.text.trim(),
          "Description": descriptionController.text.trim(),
        },

        file: selectedFile,
      );

      if (response == null) return;

      final responseBody = await response.stream.bytesToString();

      debugPrint("📥 STATUS => ${response.statusCode}");

      debugPrint("📥 RESPONSE => $responseBody");

      Map<String, dynamic> decoded = {};

      try {
        decoded = jsonDecode(responseBody);
      } catch (_) {}

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(decoded['message'] ?? "Holiday Homework Saved"),
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(decoded['message'] ?? "Submission Failed")),
        );
      }
    } catch (e) {
      debugPrint("❌ ERROR => $e");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      _isSubmitting = false;

      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,

      backgroundColor: const Color(0xffF5F7FB),

      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,

        title: Text(
          isEdit ? "Edit Holiday Homework" : "Holiday Homework",

          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    /// HEADER
                    Text(
                      isEdit
                          ? "Update Holiday Homework"
                          : "Create Holiday Homework",

                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _dropdown(
                            label: "Class",
                            icon: Icons.school_outlined,
                            value: selectedClassId,
                            items: classList,
                            valueKey: "id",
                            labelKey: "Class",
                            onChanged: (val) {
                              setState(() {
                                selectedClassId = val;
                              });
                            },
                          ),
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: _dropdown(
                            label: "Holiday Type",
                            icon: Icons.beach_access_outlined,
                            value: selectedHoliday,
                            items: holidayList,
                            valueKey: "id",
                            labelKey: "name",
                            onChanged: (val) {
                              setState(() {
                                selectedHoliday = val!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    /// TITLE
                    _textField(
                      controller: titleController,
                      label: "Title",
                      hint: "Enter homework title",
                      icon: Icons.title,
                    ),

                    const SizedBox(height: 10),

                    /// DESCRIPTION
                    _textField(
                      controller: descriptionController,
                      label: "Description",
                      hint: "Write homework...",
                      icon: Icons.description_outlined,
                      maxLines: 4,
                    ),

                    const SizedBox(height: 10),

                    /// ATTACHMENT
                    const Text(
                      "Attachment",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 5),

                    InkWell(
                      borderRadius: BorderRadius.circular(10),

                      onTap: pickFile,

                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),

                        decoration: BoxDecoration(
                          color: const Color(0xffF8F9FD),

                          borderRadius: BorderRadius.circular(10),

                          border: Border.all(color: Colors.grey.shade200),
                        ),

                        child: Row(
                          children: [
                            Icon(
                              Icons.attach_file_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),

                            const SizedBox(width: 8),

                            Expanded(
                              child: Text(
                                selectedFileName ?? "Upload Image/PDF",

                                style: TextStyle(
                                  fontSize: 12,

                                  color: selectedFileName != null
                                      ? Colors.black
                                      : Colors.grey.shade600,
                                ),

                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            /// REMOVE FILE
                            if (selectedFileName != null)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedFile = null;
                                    selectedFileName = null;
                                  });
                                },

                                child: Container(
                                  padding: const EdgeInsets.all(4),

                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),

                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                ),
                              )
                            else
                              Text(
                                "Browse",

                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    /// BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 44,

                      child: ElevatedButton(
                        onPressed: saveHomework,

                        style: ElevatedButton.styleFrom(
                          elevation: 0,

                          backgroundColor: AppColors.primary,

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [
                            const Icon(
                              Icons.save_outlined,
                              color: Colors.white,
                              size: 18,
                            ),

                            const SizedBox(width: 6),

                            Text(
                              isEdit ? "Update Homework" : "Save Homework",

                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
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
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          label,

          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),

        const SizedBox(height: 5),

        TextField(
          controller: controller,
          maxLines: maxLines,

          style: const TextStyle(fontSize: 13),

          decoration: InputDecoration(
            hintText: hint,

            hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),

            prefixIcon: Icon(icon, size: 18, color: AppColors.primary),

            filled: true,

            fillColor: const Color(0xffF8F9FD),

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),

              borderSide: BorderSide(color: Colors.grey.shade200),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),

              borderSide: BorderSide(color: Colors.grey.shade200),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),

              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<Map<String, dynamic>> items,
    required String valueKey,
    required String labelKey,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          label,

          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),

        const SizedBox(height: 5),

        Container(
          height: 46,

          padding: const EdgeInsets.symmetric(horizontal: 10),

          decoration: BoxDecoration(
            color: const Color(0xffF8F9FD),

            borderRadius: BorderRadius.circular(10),

            border: Border.all(color: Colors.grey.shade200),
          ),

          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,

              isExpanded: true,

              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),

              hint: const Text("Select", style: TextStyle(fontSize: 12)),

              onChanged: onChanged,

              items: items.map((e) {
                return DropdownMenuItem<String>(
                  value: e[valueKey].toString(),

                  child: Row(
                    children: [
                      Icon(icon, size: 16, color: AppColors.primary),

                      const SizedBox(width: 6),

                      Text(
                        e[labelKey].toString(),

                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
