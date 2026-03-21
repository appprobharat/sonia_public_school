import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ClassModel {
  final int id;
  final String name;

  ClassModel({required this.id, required this.name});

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(id: json['id'], name: json['Class']);
  }
}

class SectionModel {
  final int id;
  final String name;

  SectionModel({required this.id, required this.name});

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    return SectionModel(id: json['id'], name: json['SectionName']);
  }
}

class AdminAddHomework extends StatefulWidget {
  final int? homeworkId;

  const AdminAddHomework({super.key, this.homeworkId});

  bool get isEdit => homeworkId != null;

  @override
  State<AdminAddHomework> createState() => _AdminAddHomeworkState();
}

class _AdminAddHomeworkState extends State<AdminAddHomework> {
  final TextEditingController remarkCtrl = TextEditingController();

  DateTime? workDate;
  DateTime? submissionDate;

  String? selectedClass;
  String? selectedSection;

  final TextEditingController titleCtrl = TextEditingController();
  String? existingAttachmentUrl;
  File? selectedImage;
  final ImagePicker _picker = ImagePicker();

  bool isSubmitting = false;
  List<ClassModel> classList = [];
  List<SectionModel> sectionList = [];
  bool isEditLoading = false;
  int? selectedClassId;
  int? selectedSectionId;

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();

    if (widget.isEdit) {
      isEditLoading = true;
    }

    _initializePage();
  }

  Future<void> _initializePage() async {
    await fetchClasses();

    if (widget.isEdit) {
      await loadHomeworkDetail();
    }

    setState(() {
      isEditLoading = false;
    });
  }

  Future<void> loadHomeworkDetail() async {
    try {
      setState(() => isEditLoading = true);

      final response = await ApiService.post(
        context,
        "/admin/homework/edit",
        body: {"HomeworkId": widget.homeworkId.toString()},
      );

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);

        titleCtrl.text = data["Title"] ?? "";
        remarkCtrl.text = data["Remark"] ?? "";
        existingAttachmentUrl = data["Attachment"];
        workDate = DateTime.tryParse(data["Date"] ?? "");
        submissionDate = DateTime.tryParse(data["Submission"] ?? "");

        selectedClassId = int.tryParse(data["Class"].toString());
        selectedSectionId = int.tryParse(data["Section"].toString());

        /// 🔥 Set class name
        final cls = classList.firstWhere((e) => e.id == selectedClassId);
        selectedClass = cls.name;

        /// 🔥 Fetch sections for that class
        final responseSec = await ApiService.post(
          context,
          "/get_section",
          body: {"ClassId": selectedClassId.toString()},
        );

        if (responseSec != null && responseSec.statusCode == 200) {
          final dataSec = jsonDecode(responseSec.body);

          sectionList = (dataSec as List)
              .map((e) => SectionModel.fromJson(e))
              .toList();

          /// 🔥 Now match section
          final sec = sectionList.firstWhere((e) => e.id == selectedSectionId);

          selectedSection = sec.name;
        }

        setState(() {});
      }
    } catch (e) {
      debugPrint("Edit load error: $e");
    }

    setState(() => isEditLoading = false);
  }

  Future<void> fetchClasses() async {
    try {
      final response = await ApiService.post(context, "/get_class");

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);

        classList = (data as List).map((e) => ClassModel.fromJson(e)).toList();

        setState(() {});
      }
    } catch (e) {
      debugPrint("Class fetch error: $e");
    }
  }

  Future<void> fetchSections(int classId) async {
    try {
      final response = await ApiService.post(
        context,
        "/get_section",
        body: {"ClassId": classId.toString()},
      );

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);

        sectionList = (data as List)
            .map((e) => SectionModel.fromJson(e))
            .toList();

        selectedSection = null;
        selectedSectionId = null;

        setState(() {});
      }
    } catch (e) {
      debugPrint("Section fetch error: $e");
    }
  }

  Future<void> _pickDate(bool isWorkDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isWorkDate) {
          workDate = picked;
        } else {
          submissionDate = picked;
        }
      });
    }
  }

  Future<void> _saveHomework() async {
    if (selectedClass == null) {
      _showMsg("Please select class");
      return;
    }

    if (selectedSection == null) {
      _showMsg("Please select section");
      return;
    }

    if (workDate == null) {
      _showMsg("Please select work date");
      return;
    }

    if (submissionDate == null) {
      _showMsg("Please select submission date");
      return;
    }

    if (titleCtrl.text.trim().isEmpty) {
      _showMsg("Please enter title");
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final token = await ApiService.getToken();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse("${ApiService.baseUrl}/admin/homework/store"),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['Class'] = selectedClassId.toString();
      request.fields['Section'] = selectedSectionId.toString();

      request.fields['Date'] = _formatDate(workDate!);
      request.fields['Submission'] = _formatDate(submissionDate!);
      request.fields['Remark'] = remarkCtrl.text.trim();
      request.fields['Title'] = titleCtrl.text.trim();
      if (widget.isEdit) {
        request.fields["Type"] = "update";
        request.fields["HomeworkId"] = widget.homeworkId.toString();
      }
      if (selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('Attachment', selectedImage!.path),
        );
      }

      if (titleCtrl.text.trim().isEmpty) {
        _showMsg("Please enter title");
        return;
      }

      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      final decoded = jsonDecode(respStr);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showMsg(decoded['message'] ?? "Homework Added");
        Navigator.pop(context, true);
      } else {
        _showMsg(decoded['message'] ?? "Failed to save");
      }
    } catch (e) {
      _showMsg("Error: $e");
    }

    setState(() => isSubmitting = false);
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
        existingAttachmentUrl = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6ECFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: BackButton(),
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          widget.isEdit ? "Edit Homework" : "Add Homeworks",
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: isEditLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// CLASS + SECTION (Row Compact)
                    Row(
                      children: [
                        Expanded(
                          child: _selectContainer(
                            title: "Class",
                            value: selectedClass,
                            icon: Icons.school_outlined,
                            options: classList.map((e) => e.name).toList(),

                            onSelected: (val) {
                              final selected = classList.firstWhere(
                                (e) => e.name == val,
                              );

                              selectedClass = selected.name;
                              selectedClassId = selected.id;

                              fetchSections(selected.id);

                              setState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _selectContainer(
                            title: "Section",
                            value: selectedSection,
                            icon: Icons.group_outlined,
                            options: sectionList.map((e) => e.name).toList(),

                            onSelected: (val) {
                              final selected = sectionList.firstWhere(
                                (e) => e.name == val,
                              );

                              selectedSection = selected.name;
                              selectedSectionId = selected.id;

                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    /// WORK DATE
                    _modernDateField(
                      label: "Work Date",
                      icon: Icons.calendar_today_outlined,
                      date: workDate,
                      onTap: () => _pickDate(true),
                    ),

                    const SizedBox(height: 18),

                    /// SUBMISSION DATE
                    _modernDateField(
                      label: "Submission Date",
                      icon: Icons.event_available_outlined,
                      date: submissionDate,
                      onTap: () => _pickDate(false),
                    ),

                    const SizedBox(height: 14),

                    /// TITLE FIELD
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: "Title",
                        prefixIcon: const Icon(Icons.title),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    /// REMARK
                    TextField(
                      controller: remarkCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: "Remark",
                        prefixIcon: const Icon(Icons.edit_note_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),

                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    /// ATTACHMENT FIELD
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Attachment",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),

                        InkWell(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                              color: const Color(0xfffafafa),
                            ),
                            child: Row(
                              children: [
                                /// LEFT SIDE TEXT
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.attach_file, size: 18),
                                      const SizedBox(width: 6),

                                      Expanded(
                                        child: Text(
                                          selectedImage != null
                                              ? selectedImage!.path
                                                    .split('/')
                                                    .last
                                              : (existingAttachmentUrl != null
                                                    ? existingAttachmentUrl!
                                                          .split('/')
                                                          .last
                                                    : "Tap to select image"),
                                          style: const TextStyle(fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 10),

                                /// RIGHT SIDE SQUARE PREVIEW
                                Container(
                                  height: 60,
                                  width: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey.shade200,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: selectedImage != null
                                        ? Image.file(
                                            selectedImage!,
                                            fit: BoxFit.cover,
                                          )
                                        : existingAttachmentUrl != null &&
                                              existingAttachmentUrl!.isNotEmpty
                                        ? Image.network(
                                            existingAttachmentUrl!,
                                            fit: BoxFit.cover,
                                          )
                                        : const Icon(Icons.image, size: 25),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    /// SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : _saveHomework,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [Color(0xff4CAF50), Color(0xff2E7D32)],
                            ),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: isSubmitting
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    widget.isEdit
                                        ? "Update Homework"
                                        : "Save Homework",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
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

  Widget _selectContainer({
    required String title,
    required String? value,
    required IconData icon,
    required List<String> options,
    required Function(String) onSelected,
  }) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (context) => options
          .map((e) => PopupMenuItem<String>(value: e, child: Text(e)))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          color: const Color(0xfffafafa),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value ?? "Select",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _modernDateField({
    required String label,
    required IconData icon,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
        child: Text(date == null ? "Select Date" : _formatDate(date)),
      ),
    );
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
