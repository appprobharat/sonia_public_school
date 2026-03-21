import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;
  bool _isSubmitting = false; // 🔒 prevent double submit

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

  // ============================
  // 🔄 EDIT MODE SEQUENTIAL LOAD
  // ============================
  Future<void> _loadEditFlow() async {
    setState(() => isLoading = true);
    await fetchClasses();
    await fetchHomeworkDetails(widget.homeworkToEdit!['id']);
    if (mounted) setState(() => isLoading = false);
  }

  // ============================
  // 📚 FETCH CLASSES
  // ============================
  Future<void> fetchClasses() async {
    final res = await ApiService.post(context, "/get_class");
    if (res == null) return;

    if (res.statusCode == 200 && mounted) {
      setState(() {
        classes = jsonDecode(res.body);
      });
    }
  }

  // ============================
  // 📘 FETCH SECTIONS
  // ============================
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

  // ============================
  // ✏️ FETCH HOMEWORK DETAILS
  // ============================
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

    if (existingAttachment != null && existingAttachment!.isNotEmpty) {
      existingAttachment = ApiService.homeworkAttachment(existingAttachment!);
    }
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    _isSubmitting = true;
    setState(() => isLoading = true);

    try {
      final token = await ApiService.getToken(); // already secure

      final isEdit = widget.homeworkToEdit != null;
      final endpoint = isEdit
          ? "/teacher/homework/update"
          : "/teacher/homework/store";

      final request =
          http.MultipartRequest(
              'POST',
              Uri.parse("${ApiService.baseUrl}$endpoint"),
            )
            ..headers['Authorization'] = 'Bearer $token'
            ..headers['Accept'] = 'application/json'
            ..fields['Class'] = selectedClassId.toString()
            ..fields['Section'] = selectedSectionId.toString()
            ..fields['Title'] = _titleController.text.trim()
            ..fields['Description'] = _descriptionController.text.trim()
            ..fields['AssignDate'] = DateFormat(
              'yyyy-MM-dd',
            ).format(assignDate!)
            ..fields['SubmissionDate'] = DateFormat(
              'yyyy-MM-dd',
            ).format(submissionDate!);

      if (isEdit) {
        request.fields['HomeworkId'] = widget.homeworkToEdit!['id'].toString();
      }

      if (selectedFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('Attachment', selectedFile!.path),
        );
      }

      final resp = await request.send();
      final body = await resp.stream.bytesToString();
      final decoded = jsonDecode(body);

      if (!mounted) return;

      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(decoded['message'] ?? 'Success')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(decoded['message'] ?? 'Failed')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      _isSubmitting = false;
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        selectedFile = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: "Class"),
                    value: selectedClassId,
                    items: classes.map((cls) {
                      return DropdownMenuItem<int>(
                        value: cls['id'],
                        child: Text(cls['Class']),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => selectedClassId = val);
                      if (val != null) fetchSections(val);
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: "Section"),
                    value: selectedSectionId,
                    items: sections.map((sec) {
                      return DropdownMenuItem<int>(
                        value: sec['id'],
                        child: Text(sec['SectionName']),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => selectedSectionId = val),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: "Homework Title",
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: "Description"),
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
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
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
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
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
                        onTap: pickImage,
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
                                      Icons.attach_file,
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
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      onPressed: submitHomework,
                      child: Text(
                        widget.homeworkToEdit != null
                            ? "Update Homework"
                            : "Submit Homework",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
