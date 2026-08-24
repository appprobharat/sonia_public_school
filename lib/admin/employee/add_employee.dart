import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AddEmployeePage extends StatefulWidget {
  final int? employeeId;
  final bool isEdit;

  const AddEmployeePage({super.key, this.employeeId, this.isEdit = false});

  @override
  State<AddEmployeePage> createState() => _AddEmployeePageState();
}

class _AddEmployeePageState extends State<AddEmployeePage> {
  final empNameCtrl = TextEditingController();
  final relativeCtrl = TextEditingController();
  final contactCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  String gender = "Male";
  final genders = ["Male", "Female", "Other"];

  DateTime? dob;
  File? image;

  List<Map<String, dynamic>> classList = [];
  List<Map<String, dynamic>> sectionList = [];

  int? selectedClassId;
  int? selectedSectionId;

  String? selectedClass;
  String? selectedSection;
  List<Map<String, dynamic>> roleList = [];
  List<Map<String, dynamic>> departmentList = [];
  List<Map<String, dynamic>> designationList = [];

  String? selectedRole;
  int? selectedDepartmentId;
  int? selectedDesignationId;
  bool isSaving = false;
  bool isEdit = false;
  int? employeeId;
  bool loadingClass = false;
  bool loadingSection = false;
  bool isPageLoading = false;
  String? networkImageUrl;

  @override
  void initState() {
    super.initState();

    fetchRoles();
    fetchDepartments();
    fetchDesignations();
    fetchClasses();

    if (widget.isEdit && widget.employeeId != null) {
      employeeId = widget.employeeId;
      isEdit = true;
      fetchEmployeeDetails(widget.employeeId!);
    }
  }

  bool _isValidMobile(String mobile) {
    return RegExp(r'^[0-9]{10}$').hasMatch(mobile);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> fetchEmployeeDetails(int id) async {
    setState(() => isPageLoading = true);

    final res = await ApiService.post(
      context,
      "/admin/employee/edit",
      body: {"EmployeeId": id},
    );

    if (res != null && res.statusCode == 200) {
      final data = jsonDecode(res.body);

      empNameCtrl.text = data['EmployeeName'] ?? '';
      relativeCtrl.text = data['RelativeName'] ?? '';
      contactCtrl.text = data['ContactNo'].toString();
      emailCtrl.text = data['Email'] ?? '';
      addressCtrl.text = data['Address'] ?? '';
      networkImageUrl = data['Photo'];

      gender = data['Gender'] ?? "Male";
      selectedRole = data['Role'];

      selectedDepartmentId = int.tryParse(data['Department'].toString());
      selectedDesignationId = int.tryParse(data['Designation'].toString());

      if (data['DOB'] != null) {
        dob = DateTime.tryParse(data['DOB']);
      }

      // If Teacher
      if (selectedRole == "Teacher") {
        selectedClassId = data['Class'];
        selectedSectionId = data['Section'];

        // Fetch sections for class
        await fetchSections(selectedClassId!);

        final classData = classList.firstWhere(
          (e) => e['id'] == selectedClassId,
          orElse: () => {},
        );

        selectedClass = classData['Class'];

        final sectionData = sectionList.firstWhere(
          (e) => e['id'] == selectedSectionId,
          orElse: () => {},
        );

        selectedSection = sectionData['SectionName'];
      }

      setState(() {});
    }

    setState(() => isPageLoading = false);
  }

  Future<void> fetchClasses() async {
    setState(() => loadingClass = true);

    final res = await ApiService.post(context, "/get_class");

    if (res != null && res.statusCode == 200) {
      classList = List<Map<String, dynamic>>.from(
        (jsonDecode(res.body) as List),
      );
    }

    setState(() => loadingClass = false);
  }

  Future<void> fetchRoles() async {
    final res = await ApiService.post(context, "/get_role");

    if (res != null && res.statusCode == 200) {
      roleList = List<Map<String, dynamic>>.from(jsonDecode(res.body));
      selectedRole = null;
      setState(() {});
    }
  }

  Future<void> fetchDepartments() async {
    final res = await ApiService.post(context, "/get_department");

    if (res != null && res.statusCode == 200) {
      departmentList = List<Map<String, dynamic>>.from(jsonDecode(res.body));

      setState(() {});
    }
  }

  Future<void> fetchDesignations() async {
    final res = await ApiService.post(context, "/get_designation");

    if (res != null && res.statusCode == 200) {
      designationList = List<Map<String, dynamic>>.from(jsonDecode(res.body));

      setState(() {});
    }
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

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> addEmployee() async {
    if (isSaving) return;

    String name = empNameCtrl.text.trim();
    String mobile = contactCtrl.text.trim();
    String email = emailCtrl.text.trim();

    if (name.isEmpty) {
      _showError("Please enter employee name");
      return;
    }

    if (mobile.isEmpty) {
      _showError("Please enter mobile number");
      return;
    }

    if (!_isValidMobile(mobile)) {
      _showError("Mobile number must be 10 digits");
      return;
    }

    if (email.isNotEmpty && !_isValidEmail(email)) {
      _showError("Please enter valid email address");
      return;
    }

    if (selectedDepartmentId == null) {
      _showError("Please select department");
      return;
    }

    if (selectedDesignationId == null) {
      _showError("Please select designation");
      return;
    }

    if (selectedRole == null) {
      _showError("Please select role");
      return;
    }

    if (dob == null) {
      _showError("Please select date of birth");
      return;
    }

    // If role is Teacher then class & section required
    if (selectedRole == "Teacher" &&
        (selectedClassId == null || selectedSectionId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select Class & Section for Teacher")),
      );
      return;
    }

    isSaving = true;
    setState(() {});

    try {
      final token = await ApiService.getToken();
      final endpoint = "/admin/employee/store";

      final request =
          http.MultipartRequest(
              'POST',
              Uri.parse("${ApiService.baseUrl}$endpoint"),
            )
            ..headers['Authorization'] = 'Bearer $token'
            ..headers['Accept'] = 'application/json'
            ..fields['EmployeeName'] = empNameCtrl.text.trim()
            ..fields['RelativeName'] = relativeCtrl.text.trim()
            ..fields['ContactNo'] = contactCtrl.text.trim()
            ..fields['Email'] = emailCtrl.text.trim()
            ..fields['DOB'] = dob!.toIso8601String().split('T').first
            ..fields['Gender'] = gender
            ..fields['Address'] = addressCtrl.text.trim()
            ..fields['Department'] = selectedDepartmentId.toString()
            ..fields['Designation'] = selectedDesignationId.toString()
            ..fields['Role'] = selectedRole!;

      // ✅ Only if Teacher
      if (selectedRole == "Teacher") {
        request.fields['Class'] = selectedClassId.toString();
        request.fields['Section'] = selectedSectionId.toString();
      } else {
        request.fields['Class'] = "";
        request.fields['Section'] = "";
      }

      // ✅ Type for update
      request.fields['Type'] = isEdit ? 'update' : 'create';

      if (isEdit && employeeId != null) {
        request.fields['EmployeeId'] = employeeId.toString();
      }

      // ✅ Photo only if selected
      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('Photo', image!.path),
        );
      }

      final resp = await request.send();
      final body = await resp.stream.bytesToString();
      final decoded = jsonDecode(body);

      if (!mounted) return;

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(decoded['message'] ?? 'Employee Saved')),
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
      isSaving = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      initialDate: DateTime(2000),
    );

    if (picked != null) {
      setState(() => dob = picked);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6ECF9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: BackButton(),
        iconTheme: IconThemeData(color: Colors.white),

        title: const Text(
          'Employee Registration',
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
                      'Employee Name *',
                      Icons.person,
                      const Color(0xffF4A261),
                    ),
                    _input('Enter Employee Name', empNameCtrl),

                    _label(
                      'Relative Name',
                      Icons.people,
                      const Color(0xff4DA3FF),
                    ),
                    _input('Enter S/o W/o', relativeCtrl),

                    _label('Contact No', Icons.call, const Color(0xff6CC04A)),
                    _input(
                      'Enter Contact Number',
                      contactCtrl,
                      keyboardType: TextInputType.phone,
                    ),
                    _label(
                      'Email Address',
                      Icons.email,
                      const Color(0xff8E44AD),
                    ),
                    _input(
                      'Enter Email Address',
                      emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label(
                                'Date Of Birth',
                                Icons.calendar_month,
                                const Color(0xff9B59B6),
                              ),
                              GestureDetector(
                                onTap: _pickDob,
                                child: _dateInput(
                                  dob == null
                                      ? 'Select Date'
                                      : '${dob!.day}-${dob!.month}-${dob!.year}',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Gender', Icons.person_2, Colors.blueGrey),
                              PopupMenuButton<String>(
                                onSelected: (v) => setState(() => gender = v),
                                itemBuilder: (_) => genders
                                    .map(
                                      (e) => PopupMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ),
                                    )
                                    .toList(),
                                child: _dropdown(gender),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label(
                                'Department',
                                Icons.apartment,
                                const Color(0xff6C63FF),
                              ),

                              PopupMenuButton<String>(
                                onSelected: (v) {
                                  final dept = departmentList.firstWhere(
                                    (e) => e['Department'] == v,
                                  );
                                  setState(() {
                                    selectedDepartmentId = dept['id'];
                                  });
                                },
                                itemBuilder: (_) => departmentList
                                    .map(
                                      (e) => PopupMenuItem(
                                        value: e['Department'].toString(),
                                        child: Text(e['Department'].toString()),
                                      ),
                                    )
                                    .toList(),
                                child: _dropdown(
                                  selectedDepartmentId == null
                                      ? "Select Department"
                                      : departmentList
                                            .firstWhere(
                                              (e) =>
                                                  e['id'] ==
                                                  selectedDepartmentId,
                                            )['Department']
                                            .toString(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label(
                                'Designation',
                                Icons.badge,
                                Colors.blueGrey,
                              ),

                              PopupMenuButton<String>(
                                onSelected: (v) {
                                  final des = designationList.firstWhere(
                                    (e) => e['Designation'] == v,
                                  );
                                  setState(() {
                                    selectedDesignationId = des['id'];
                                  });
                                },
                                itemBuilder: (_) => designationList
                                    .map(
                                      (e) => PopupMenuItem(
                                        value: e['Designation'].toString(),
                                        child: Text(
                                          e['Designation'].toString(),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                child: _dropdown(
                                  selectedDesignationId == null
                                      ? "Select Designation"
                                      : designationList
                                            .firstWhere(
                                              (e) =>
                                                  e['id'] ==
                                                  selectedDesignationId,
                                            )['Designation']
                                            .toString(),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),
                      ],
                    ),
                    _label('Address', Icons.home, const Color(0xff4DA3FF)),
                    _input('Enter Full Address', addressCtrl),
                    const SizedBox(height: 6),
                    _label(
                      'Employee Role *',
                      Icons.supervisor_account,
                      const Color(0xff8E44AD),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        setState(() {
                          selectedRole = v;
                          selectedClassId = null;
                          selectedSectionId = null;
                          selectedClass = null;
                          selectedSection = null;
                        });
                      },
                      itemBuilder: (_) => roleList
                          .map(
                            (e) => PopupMenuItem(
                              value: e['Role'].toString(),
                              child: Text(e['Role'].toString()),
                            ),
                          )
                          .toList(),
                      child: _dropdown(selectedRole ?? "Select Role"),
                    ), // ✅ Show only when role = Teacher
                    if (selectedRole == "Teacher") ...[
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label(
                                  'Class',
                                  Icons.school,
                                  const Color(0xff9B59B6),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (v) {
                                    final cls = classList.firstWhere(
                                      (e) => e['Class'] == v,
                                    );

                                    setState(() {
                                      selectedClass = v;
                                      selectedClassId = cls['id'];
                                    });

                                    fetchSections(selectedClassId!);
                                  },
                                  itemBuilder: (_) => classList
                                      .map(
                                        (e) => PopupMenuItem(
                                          value: e['Class'].toString(),
                                          child: Text(e['Class'].toString()),
                                        ),
                                      )
                                      .toList(),
                                  child: _dropdown(
                                    selectedClass ?? "Select Class",
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label(
                                  'Section',
                                  Icons.school,
                                  Colors.blueGrey,
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (v) {
                                    final sec = sectionList.firstWhere(
                                      (e) => e['SectionName'] == v,
                                    );

                                    setState(() {
                                      selectedSection = v;
                                      selectedSectionId = sec['id'];
                                    });
                                  },
                                  itemBuilder: (_) => sectionList
                                      .map(
                                        (e) => PopupMenuItem(
                                          value: e['SectionName'].toString(),
                                          child: Text(
                                            e['SectionName'].toString(),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  child: _dropdown(
                                    selectedSection ?? "Select Section",
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          height: 64,
                          width: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black12),
                          ),
                          child: ClipOval(
                            child: image != null
                                ? Image.file(image!, fit: BoxFit.cover)
                                : (networkImageUrl != null &&
                                      networkImageUrl!.isNotEmpty)
                                ? Image.network(
                                    networkImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.person,
                                      color: Colors.grey,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 32,
                                    color: Colors.grey,
                                  ),
                          ),
                        ),

                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xff6DBB63),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  height: 36,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xff6DBB63),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.camera_alt,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Select Photo',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              image == null
                                  ? 'No image selected'
                                  : 'Image selected',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: isSaving ? null : addEmployee,
                      child: Container(
                        height: 44,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: const LinearGradient(
                            colors: [Color(0xff6DBB63), Color(0xff4CAF50)],
                          ),
                        ),
                        child: Center(
                          child: isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      isEdit ? 'Update Employee' : 'Register',
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
    String hint,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xffFAF7FC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: keyboardType == TextInputType.phone ? 10 : null,
        inputFormatters: keyboardType == TextInputType.phone
            ? [FilteringTextInputFormatter.digitsOnly]
            : [],
        decoration: InputDecoration(
          counterText: '',
          isDense: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _dropdown(String text) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xffFAF7FC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
          const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _dateInput(String date) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xffFAF7FC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Expanded(child: Text(date, style: const TextStyle(fontSize: 12))),
          const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}
