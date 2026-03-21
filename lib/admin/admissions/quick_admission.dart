import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

class QuickAdmissionPage extends StatefulWidget {
  final int? studentId;
  const QuickAdmissionPage({super.key, this.studentId});

  @override
  State<QuickAdmissionPage> createState() => _QuickAdmissionPageState();
}

class _QuickAdmissionPageState extends State<QuickAdmissionPage> {
  final studentCtrl = TextEditingController();
  final fatherCtrl = TextEditingController();
  final motherCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final ledgerCtrl = TextEditingController();
  List<Map<String, dynamic>> classList = [];
  List<Map<String, dynamic>> sectionList = [];
  bool isSaving = false;
  bool get isEdit => widget.studentId != null;
  bool loadingEditData = false;
  final List<String> genderList = ["Male", "Female", "Other"];
  String selectedGender = "Male";
  int? selectedClassId;
  int? selectedSectionId;
  String? selectedClass;
  String? selectedSection;
  File? studentPhotoFile;
  String? studentPhotoUrl;

  final ImagePicker _picker = ImagePicker();

  bool loadingClass = false;
  bool loadingSection = false;
  DateTime? dob;

  bool _isValidMobile(String mobile) {
    return RegExp(r'^[0-9]{10}$').hasMatch(mobile);
  }

  @override
  void initState() {
    super.initState();
    fetchClasses();

    if (isEdit) {
      loadingEditData = true;
      fetchStudentForEdit();
    }
  }

  Future<void> fetchStudentForEdit() async {
    try {
      final res = await ApiService.post(
        context,
        "/admin/student/edit",
        body: {"StudentId": widget.studentId},
      );

      if (res == null || res.statusCode != 200) return;

      final data = jsonDecode(res.body);

      // TEXTFIELDS
      studentCtrl.text = data['StudentName'] ?? '';
      fatherCtrl.text = data['FatherName'] ?? '';
      motherCtrl.text = data['MotherName'] ?? '';
      mobileCtrl.text = data['StudentContactNo'].toString();
      addressCtrl.text = data['Address'] ?? '';
      ledgerCtrl.text = data['LedgerNo'] ?? '';
      selectedGender = data['Gender'] ?? 'Male';

      dob = DateTime.tryParse(data['DOB'] ?? '');

      selectedClassId = int.parse(data['Class'].toString());
      selectedSectionId = int.parse(data['Section'].toString());

      // PHOTO URL
      studentPhotoUrl = data['StudentPhoto'];

      await fetchClasses(); // class + section resolve
    } finally {
      loadingEditData = false; // 👈 loader stop
      if (mounted) setState(() {});
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> pickStudentPhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        studentPhotoFile = File(image.path);
        studentPhotoUrl = null;
      });
    }
  }

  Future<void> fetchClasses() async {
    setState(() => loadingClass = true);

    final res = await ApiService.post(context, "/get_class");

    if (res != null && res.statusCode == 200) {
      classList = List<Map<String, dynamic>>.from(
        (jsonDecode(res.body) as List),
      );

      if (classList.isNotEmpty) {
        selectedClassId = classList.first['id'];
        selectedClass = classList.first['Class'];
        fetchSections(selectedClassId!);
      }
    }

    setState(() => loadingClass = false);
  }

  Future<void> fetchSections(int classId) async {
    setState(() {
      loadingSection = true;
      sectionList.clear();
      selectedSection = null;
      selectedSectionId = null;
    });

    final res = await ApiService.post(
      context,
      "/get_section",
      body: {"ClassId": classId},
    );

    if (res != null && res.statusCode == 200) {
      sectionList = List<Map<String, dynamic>>.from(
        (jsonDecode(res.body) as List),
      );

      if (sectionList.isNotEmpty) {
        selectedSectionId = sectionList.first['id'];
        selectedSection = sectionList.first['SectionName'];
      }
    }

    setState(() => loadingSection = false);
  }

  Future<void> saveAdmission() async {
    if (isSaving) return;
    String studentName = studentCtrl.text.trim();
    String fatherName = fatherCtrl.text.trim();
    String mobile = mobileCtrl.text.trim();
    String ledger = ledgerCtrl.text.trim();

    if (studentName.isEmpty) {
      _showError("Please enter student name");
      return;
    }

    if (fatherName.isEmpty) {
      _showError("Please enter father name");
      return;
    }

    if (selectedGender.isEmpty) {
      _showError("Please select gender");
      return;
    }

    if (selectedClassId == null) {
      _showError("Please select class");
      return;
    }

    if (selectedSectionId == null) {
      _showError("Please select section");
      return;
    }

    if (mobile.isEmpty) {
      _showError("Please enter mobile number");
      return;
    }

    if (!_isValidMobile(mobile)) {
      _showError("Mobile number must be exactly 10 digits");
      return;
    }

    if (ledger.isEmpty) {
      _showError("Please enter ledger / fee ID");
      return;
    }

    if (dob == null) {
      _showError("Please select date of birth");
      return;
    }

    isSaving = true;
    setState(() {});

    try {
      final token = await ApiService.getToken();
      final endpoint = "/admin/student/store";

      final request =
          http.MultipartRequest(
              'POST',
              Uri.parse("${ApiService.baseUrl}$endpoint"),
            )
            ..headers['Authorization'] = 'Bearer $token'
            ..headers['Accept'] = 'application/json'
            ..fields['StudentName'] = studentCtrl.text.trim()
            ..fields['FatherName'] = fatherCtrl.text.trim()
            ..fields['MotherName'] = motherCtrl.text.trim()
            ..fields['StudentContactNo'] = mobileCtrl.text.trim()
            ..fields['DOB'] = dob!.toIso8601String().split('T').first
            ..fields['Class'] = selectedClassId.toString()
            ..fields['Section'] = selectedSectionId.toString()
            ..fields['Address'] = addressCtrl.text.trim()
            ..fields['LedgerNo'] = ledgerCtrl.text.trim()
            ..fields['Gender'] = selectedGender;

      request.fields['Type'] = isEdit ? 'update' : 'create';

      if (isEdit) {
        request.fields['StudentId'] = widget.studentId.toString();
      }

      // ✅ IMAGE ONLY IF USER PICKED NEW ONE
      if (studentPhotoFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'StudentPhoto',
            studentPhotoFile!.path,
          ),
        );
      }

      if (isEdit) {
        request.fields['StudentId'] = widget.studentId.toString();
      }
      final resp = await request.send();
      final body = await resp.stream.bytesToString();
      final decoded = jsonDecode(body);

      if (!mounted) return;

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(decoded['message'] ?? 'Saved')));

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
      isSaving = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _pickDob() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDate: DateTime(2015),
    );
    if (date != null) {
      setState(() => dob = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: const BackButton(),
        iconTheme: IconThemeData(color: Colors.white),

        title: const Text(
          'Quick Admission',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: loadingEditData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _section('Student Details', const Color(0xffE8F4FB), [
                    _field(
                      Icons.person,
                      'Student Name',
                      const Color(0xff4DA3FF),
                      studentCtrl,
                    ),

                    _field(
                      Icons.person_outline,
                      'Father Name',
                      const Color(0xff6CC04A),
                      fatherCtrl,
                    ),
                    _field(
                      Icons.person_2_outlined,
                      'Mother Name',
                      const Color(0xffFF6B6B),
                      motherCtrl,
                    ),

                    _genderDropdown(),
                    _dobField(),
                    _photoPicker(),
                  ]),
                  _section('Academic Details', const Color(0xffEAF6E8), [
                    Row(
                      children: [
                        Expanded(
                          child: _dropdown(
                            Icons.school,
                            selectedClass ?? '',
                            const Color(0xff4DA3FF),
                            classList
                                .map((e) => e['Class'].toString())
                                .toList(),
                            (v) {
                              final cls = classList.firstWhere(
                                (e) => e['Class'] == v,
                              );
                              setState(() {
                                selectedClass = v;
                                selectedClassId = cls['id'];
                              });
                              fetchSections(selectedClassId!);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _dropdown(
                            Icons.layers,
                            selectedSection ?? '',
                            const Color(0xff6CC04A),
                            sectionList
                                .map((e) => e['SectionName'].toString())
                                .toList(),
                            (v) {
                              final sec = sectionList.firstWhere(
                                (e) => e['SectionName'] == v,
                              );
                              setState(() {
                                selectedSection = v;
                                selectedSectionId = sec['id'];
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ]),
                  _section('Contact & Address', const Color(0xffFFF2E5), [
                    _field(
                      Icons.call,
                      'Mobile Number   9XXXXXXXXX',
                      const Color(0xff6CC04A),
                      mobileCtrl,
                      keyboard: TextInputType.phone,
                    ),

                    _field(
                      Icons.home,
                      'Address',
                      const Color(0xffB47B3D),
                      addressCtrl,
                    ),
                  ]),
                  _section('Fee / Ledger', const Color(0xffFFF1DC), [
                    _field(
                      Icons.receipt_long,
                      'Ledger / Fee ID',
                      const Color(0xffF4A340),
                      ledgerCtrl,
                    ),
                  ]),

                  GestureDetector(
                    onTap: saveAdmission,

                    child: Container(
                      height: 44,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(
                          colors: [Color(0xff6CC04A), Color(0xff4CAF50)],
                        ),
                      ),
                      child: Center(
                        child: isSaving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isEdit
                                        ? 'Update Admission'
                                        : 'Save Admission',
                                    style: const TextStyle(
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
    );
  }

  Widget _section(String title, Color bg, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...children.map(
            (e) => Padding(padding: const EdgeInsets.only(bottom: 6), child: e),
          ),
        ],
      ),
    );
  }

  Widget _field(
    IconData icon,
    String hint,
    Color color,
    TextEditingController controller, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboard,
            maxLength: keyboard == TextInputType.phone ? 10 : null,
            inputFormatters: keyboard == TextInputType.phone
                ? [FilteringTextInputFormatter.digitsOnly]
                : [],
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              counterText: '', // hide counter
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdown(
    IconData icon,
    String value,
    Color color,
    List<String> items,
    ValueChanged<String> onChanged,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ICON
        Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 8),

        // DROPDOWN
        Expanded(
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: Colors.grey,
                ),
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                items: items
                    .map(
                      (e) => DropdownMenuItem<String>(value: e, child: Text(e)),
                    )
                    .toList(),
                onChanged: (v) => onChanged(v!),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _photoPicker() {
    ImageProvider? image;

    if (studentPhotoFile != null) {
      image = FileImage(studentPhotoFile!); // NEW IMAGE
    } else if (studentPhotoUrl != null && studentPhotoUrl!.isNotEmpty) {
      image = NetworkImage(studentPhotoUrl!); // OLD IMAGE
    }

    return Row(
      children: [
        Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade200,
            image: image != null
                ? DecorationImage(image: image, fit: BoxFit.cover)
                : null,
          ),
          child: image == null
              ? const Icon(Icons.camera_alt, color: Colors.grey)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: pickStudentPhoto,
            child: Container(
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "Upload Student Photo",
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _genderDropdown() {
    return _dropdown(
      Icons.wc,
      selectedGender,
      const Color(0xff9C27B0),
      genderList,
      (v) {
        setState(() {
          selectedGender = v;
        });
      },
    );
  }

  Widget _dobField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ICON BOX (same as _field)
        Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            color: const Color(0xffF4A340),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.cake, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 8),

        // DATE FIELD
        Expanded(
          child: GestureDetector(
            onTap: _pickDob,
            child: Container(
              height: 38,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                dob == null
                    ? 'Date of Birth'
                    : '${dob!.day.toString().padLeft(2, '0')}/'
                          '${dob!.month.toString().padLeft(2, '0')}/'
                          '${dob!.year}',
                style: TextStyle(
                  fontSize: 12,
                  color: dob == null ? Colors.grey : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
