import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:sonia_public_school/api_service.dart';

class TeacherAddHomeworkPage extends StatefulWidget {
  final Map<String, dynamic>? homeworkToEdit;
  const TeacherAddHomeworkPage({super.key, this.homeworkToEdit});

  @override
  State<TeacherAddHomeworkPage> createState() => _TeacherAddHomeworkPageState();
}

class _TeacherAddHomeworkPageState extends State<TeacherAddHomeworkPage> {
  List classes = [];
  List sections = [];
  int? selectedClassId;
  int? selectedSectionId;
  String? existingAttachment;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? assignDate;
  DateTime? submissionDate;
  File? selectedFile;
  bool isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    assignDate = DateTime.now();
    submissionDate = DateTime.now();

    if (widget.homeworkToEdit != null) {
      _loadEditFlow();
    } else {
      fetchClasses();
    }
  }

  Future<void> _loadEditFlow() async {
    setState(() => isLoading = true);
    await fetchClasses();
    await fetchHomeworkDetails(widget.homeworkToEdit!['id']);
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> fetchClasses() async {
    final res = await ApiService.post(context, "/get_class");
    if (res == null) return;

    if (res.statusCode == 200 && mounted) {
      setState(() {
        classes = jsonDecode(res.body);
      });
    }
  }

  Future<void> fetchSections(int classId) async {
    final res = await ApiService.post(
      context,
      "/get_section",
      body: {'ClassId': classId},
    );

    if (res == null) return;

    if (res.statusCode == 200 && mounted) {
      setState(() {
        sections = jsonDecode(res.body);
        selectedSectionId = null;
      });
    }
  }

  Future<void> fetchHomeworkDetails(int homeworkId) async {
    final res = await ApiService.post(
      context,
      "/teacher/homework/edit",
      body: {'HomeworkId': homeworkId},
    );

    if (res == null || res.statusCode != 200) return;

    final data = jsonDecode(res.body);
    debugPrint("HOMEWORK DETAIL RESPONSE: ${res.body}");
    if (!mounted) return;

    _titleController.text = data['HomeworkTitle'] ?? '';
    _descriptionController.text = data['Remark'] ?? '';
    assignDate = DateTime.tryParse(data['WorkDate'] ?? '');
    submissionDate = DateTime.tryParse(data['SubmissionDate'] ?? '');

    existingAttachment = data['Attachment'];

    selectedClassId = int.tryParse(data['Class'] ?? '');

    if (selectedClassId != null) {
      await fetchSections(selectedClassId!);
    }

    selectedSectionId = int.tryParse(data['Section'] ?? '');
    setState(() {});
    debugPrint("ATTACHMENT FROM API: ${data['Attachment']}");
  }

  Future<void> submitHomework() async {
    if (_isSubmitting) return;

    if (selectedClassId == null ||
        selectedSectionId == null ||
        assignDate == null ||
        submissionDate == null ||
        _titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      debugPrint("❌ VALIDATION FAILED");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));

      return;
    }

    _isSubmitting = true;

    setState(() => isLoading = true);

    try {
      final token = await ApiService.getToken();

      final isEdit = widget.homeworkToEdit != null;

      final endpoint = isEdit
          ? "/teacher/homework/update"
          : "/teacher/homework/store";

      debugPrint("========== HOMEWORK API DEBUG ==========");

      debugPrint("📌 ENDPOINT => $endpoint");

      debugPrint("📌 CLASS => $selectedClassId");

      debugPrint("📌 SECTION => $selectedSectionId");

      debugPrint("📌 TITLE => ${_titleController.text}");

      debugPrint("📌 DESCRIPTION => ${_descriptionController.text}");

      debugPrint(
        "📌 ASSIGN DATE => ${DateFormat('yyyy-MM-dd').format(assignDate!)}",
      );

      debugPrint(
        "📌 SUBMISSION DATE => ${DateFormat('yyyy-MM-dd').format(submissionDate!)}",
      );

      debugPrint("📌 FILE => ${selectedFile?.path}");

      final request = http.MultipartRequest(
        'POST',
        Uri.parse("${ApiService.baseUrl}$endpoint"),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.headers['Accept'] = 'application/json';

      request.fields['Class'] = selectedClassId.toString();

      request.fields['Section'] = selectedSectionId.toString();

      request.fields['Title'] = _titleController.text.trim();

      request.fields['Description'] = _descriptionController.text.trim();

      request.fields['AssignDate'] = DateFormat(
        'yyyy-MM-dd',
      ).format(assignDate!);

      request.fields['SubmissionDate'] = DateFormat(
        'yyyy-MM-dd',
      ).format(submissionDate!);

      if (isEdit) {
        request.fields['HomeworkId'] = widget.homeworkToEdit!['id'].toString();
      }

      debugPrint("📌 REQUEST FIELDS => ${request.fields}");

      if (selectedFile != null) {
        debugPrint(
          "📎 ATTACHMENT NAME => ${selectedFile!.path.split('/').last}",
        );

        request.files.add(
          await http.MultipartFile.fromPath('Attachment', selectedFile!.path),
        );

        debugPrint("✅ FILE ADDED");
      } else {
        debugPrint("⚠️ NO FILE SELECTED");
      }

      final response = await request.send();

      final responseBody = await response.stream.bytesToString();

      debugPrint("📥 STATUS CODE => ${response.statusCode}");

      debugPrint("📥 RESPONSE BODY => $responseBody");

      debugPrint("========== API END ==========");

      Map<String, dynamic> decoded = {};

      try {
        decoded = jsonDecode(responseBody);
      } catch (e) {
        debugPrint("❌ JSON DECODE ERROR => $e");
      }

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(decoded['message'] ?? 'Homework Submitted')),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(decoded['message'] ?? 'Submission Failed')),
        );
      }
    } catch (e, stack) {
      debugPrint("❌ EXCEPTION => $e");

      debugPrint("❌ STACK => $stack");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      _isSubmitting = false;

      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: Text(
          widget.homeworkToEdit != null ? "Edit Homework" : "Add Homework",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.assignment_rounded,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.homeworkToEdit != null
                                    ? "Edit Homework"
                                    : "Create Homework",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),

                              const SizedBox(height: 4),

                              const Text(
                                "Fill all details before submitting.",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: selectedClassId,
                          isExpanded: true,
                          borderRadius: BorderRadius.circular(14),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.primary,
                          ),
                          decoration: InputDecoration(
                            labelText: "Class",
                            prefixIcon: const Icon(
                              Icons.school_outlined,
                              color: AppColors.primary,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                          items: classes.map((cls) {
                            return DropdownMenuItem<int>(
                              value: cls['id'],
                              child: Text(
                                cls['Class'],
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => selectedClassId = val);
                            if (val != null) fetchSections(val);
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: selectedSectionId,
                          isExpanded: true,
                          borderRadius: BorderRadius.circular(14),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.primary,
                          ),
                          decoration: InputDecoration(
                            labelText: "Section",
                            prefixIcon: const Icon(
                              Icons.groups_rounded,
                              color: AppColors.primary,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                          items: sections.map((sec) {
                            return DropdownMenuItem<int>(
                              value: sec['id'],
                              child: Text(
                                sec['SectionName'],
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => selectedSectionId = val),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: "Homework Title",
                      prefixIcon: const Icon(Icons.title),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: "Description",
                      prefixIcon: Icon(Icons.edit_note),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: 6,
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Assign Date",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: assignDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              assignDate = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.05),
                                blurRadius: 8,
                              ),
                            ],
                          ),

                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                assignDate != null
                                    ? DateFormat(
                                        'dd-MM-yyyy',
                                      ).format(assignDate!)
                                    : DateFormat(
                                        'dd-MM-yyyy',
                                      ).format(DateTime.now()),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Icon(
                                Icons.calendar_today,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Submission Date",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: submissionDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              submissionDate = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.05),
                                blurRadius: 8,
                              ),
                            ],
                          ),

                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                submissionDate != null
                                    ? DateFormat(
                                        'dd-MM-yyyy',
                                      ).format(submissionDate!)
                                    : DateFormat(
                                        'dd-MM-yyyy',
                                      ).format(DateTime.now()),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Icon(
                                Icons.calendar_today,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Attachment (Optional)",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),

                      GestureDetector(
                        onTap: pickAttachment,
                        child: Container(
                          height: 100,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primary),
                            color: AppColors.primary.withOpacity(0.05),
                          ),
                          child: Row(
                            children: [
                              // LEFT SIDE TEXT
                              Expanded(
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.cloud_upload_outlined,
                                      color: AppColors.primary,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Tap to select attachment",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // RIGHT SIDE IMAGE PREVIEW
                              if (selectedFile != null ||
                                  existingAttachment != null)
                                Stack(
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: selectedFile != null
                                            ? Image.file(
                                                selectedFile!,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.network(
                                                existingAttachment!,
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                    ),

                                    // REMOVE BUTTON
                                    Positioned(
                                      right: -5,
                                      top: -5,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedFile = null;
                                            existingAttachment = null;
                                          });
                                        },
                                        child: const CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Colors.red,
                                          child: Icon(
                                            Icons.close,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                      ),
                      label: Text(
                        widget.homeworkToEdit != null
                            ? "Update Homework"
                            : "Submit Homework",
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: submitHomework,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
