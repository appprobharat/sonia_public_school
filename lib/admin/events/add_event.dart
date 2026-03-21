import 'dart:convert';
import 'dart:io';
import 'package:sonia_public_school/admin/helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';
import 'package:http/http.dart' as http;

class EmployeeModel {
  final String id;
  final String name;
  final String designation;
  final String phone;

  EmployeeModel({
    required this.id,
    required this.name,
    required this.designation,
    required this.phone,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'].toString(),
      name: json['EmployeeName'].toString(),
      designation: json['Designation'].toString(),
      phone: json['ContactNo'].toString(),
    );
  }
}

class AddEventPage extends StatefulWidget {
  final String? eventId;
  const AddEventPage({super.key, this.eventId});
  bool get isEdit => eventId != null;
  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  List<EmployeeModel> employeeList = [];
  String? selectedEmployeeId;
  bool isEmployeeLoading = false;
  bool isSaving = false;
  bool isEditLoading = false;
  DateTime _issueDate = DateTime.now();
  DateTime _validDate = DateTime.now();
  File? _pickedFile;
  String _fileName = "No File Chosen";
  String? existingAttachment;
  final ImagePicker _picker = ImagePicker();
  @override
  void initState() {
    super.initState();
    loadEmployees();
    if (widget.isEdit) {
      loadEventDetail();
    }
  }

  Future<void> saveEvent({bool isUpdate = false, String? eventId}) async {
    if (_titleCtrl.text.isEmpty ||
        _descCtrl.text.isEmpty ||
        selectedEmployeeId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill required fields")));
      return;
    }

    try {
      setState(() => isSaving = true); // ⭐ START LOADER

      final request = http.MultipartRequest(
        "POST",
        Uri.parse("${ApiService.baseUrl}/admin/event/store"),
      );

      request.headers.addAll(await ApiService.multipartHeaders());

      request.fields.addAll({
        "Title": _titleCtrl.text,
        "Description": _descCtrl.text,
        "AddedBy": selectedEmployeeId!,
        "Date": formatApiDate(_issueDate),
        "ValidDate": formatApiDate(_validDate),
      });

      if (isUpdate && eventId != null) {
        request.fields["Type"] = "update";
        request.fields["EventId"] = eventId;
      }

      if (_pickedFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('Attachment', _pickedFile!.path),
        );
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      debugPrint("SAVE ERROR: $e");
    }

    if (mounted) {
      setState(() => isSaving = false);
    }
  }

  Future<void> loadEventDetail() async {
    try {
      setState(() => isEditLoading = true);

      final response = await ApiService.post(
        context,
        "/admin/event/edit",
        body: {"EventId": widget.eventId},
      );

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);

        _titleCtrl.text = data['Title'] ?? "";
        _descCtrl.text = data['Description'] ?? "";

        selectedEmployeeId = data['AddedBy']?.toString();

        _issueDate = DateTime.parse(data['Date']);
        _validDate = DateTime.parse(data['ValidDate']);

        if (data['Attachment'] != null) {
          existingAttachment = data['Attachment'];
          _fileName = data['Attachment'].toString().split('/').last;
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    if (mounted) {
      setState(() => isEditLoading = false);
    }
  }

  String formatApiDate(DateTime d) {
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  Future<void> loadEmployees() async {
    try {
      setState(() => isEmployeeLoading = true);

      final response = await ApiService.post(context, "/get_employee");

      if (response != null && response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        employeeList = data.map((e) => EmployeeModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint("EMPLOYEE ERROR: $e");
    }

    if (mounted) {
      setState(() => isEmployeeLoading = false);
    }
  }

  Future<void> _pickDate(bool isIssue) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isIssue) {
          _issueDate = picked;
        } else {
          _validDate = picked;
        }
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
          widget.isEdit ? "Edit Event" : "Add Event",
          style: TextStyle(
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
              padding: const EdgeInsets.all(10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: _box(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Event',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Divider(height: 16),

                    _label('Event Title*'),
                    _input(_titleCtrl, 'Enter Event Title'),

                    const SizedBox(height: 8),
                    _label('Event Release By'),
                    _dropdown(),

                    const SizedBox(height: 8),
                    _label('Issue Date'),
                    _dateField(_issueDate, () => _pickDate(true)),

                    const SizedBox(height: 8),
                    _label('Valid Date'),
                    _dateField(_validDate, () => _pickDate(false)),

                    const SizedBox(height: 8),
                    _label('Description*'),
                    _textarea(_descCtrl, 'Enter Event Description'),

                    const SizedBox(height: 8),
                    _label('Attachment/File/Document*'),
                    _filePicker(),

                    const SizedBox(height: 14),
                    _saveBtn(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(t, style: const TextStyle(fontSize: 11)),
  );

  Widget _input(TextEditingController c, String hint) {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: c,
        style: const TextStyle(fontSize: 12),
        decoration: _dec(hint),
      ),
    );
  }

  Widget _textarea(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      maxLines: 3,
      style: const TextStyle(fontSize: 12),
      decoration: _dec(hint),
    );
  }

  Widget _dropdown() {
    return ReusableOverlayDropdown(
      label: "",
      hint: isEmployeeLoading ? "Loading..." : "--Select Employee--",
      controller: TextEditingController(
        text: employeeList
            .firstWhere(
              (e) => e.id == selectedEmployeeId,
              orElse: () =>
                  EmployeeModel(id: "", name: "", designation: "", phone: ""),
            )
            .name,
      ),
      list: employeeList.map((e) {
        return {
          "label": "${e.name} (${e.designation}) / ${e.phone}",
          "value": e.id,
        };
      }).toList(),
      labelKey: "label",
      valueKey: "value",
      onSelected: (value, label) {
        setState(() {
          selectedEmployeeId = value;
        });
      },
    );
  }

  Widget _dateField(DateTime d, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 38,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: _innerBox(),
        child: Text(
          '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _pickedFile = File(image.path);
          _fileName = image.name;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Widget _filePicker() {
    return InkWell(
      onTap: pickImage,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: _innerBox(),
        child: Row(
          children: [
            const Icon(Icons.attach_file, size: 18),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                _fileName,
                style: const TextStyle(fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            /// RIGHT SIDE PREVIEW
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.grey.shade200,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: _pickedFile != null
                    ? Image.file(_pickedFile!, fit: BoxFit.cover)
                    : (existingAttachment != null &&
                              existingAttachment!.isNotEmpty
                          ? Image.network(
                              existingAttachment!,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.image, size: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _saveBtn() {
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        height: 38,
        width: 130,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: isSaving
              ? null
              : () {
                  saveEvent(isUpdate: widget.isEdit, eventId: widget.eventId);
                },
          child: isSaving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      widget.isEdit ? "Update" : "Save",
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 11),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
  );

  BoxDecoration _box() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
  );

  BoxDecoration _innerBox() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: Colors.grey.shade300),
  );
}
