import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sonia_public_school/api_service.dart';
import 'package:sonia_public_school/changePasswordPage.dart';

class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String studentName = "";
  String rollNo = "";
  String className = "";
  String section = "";
  String contact = "";
  String address = "";
  String fatherName = "";
  String motherName = "";
  String dob = "";
  String bloodGroup = "";
  String category = "-";
  String caste = '';
  String religion = '';
  String studentPhoto = "";
  String gender = '';
  String adDate = '';
  String ledNo = '';

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initProfile();
  }

  Future<void> _initProfile() async {
    await loadLocalData();
    await fetchProfileFromApi();
  }

  Future<void> loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      studentName = prefs.getString('student_name') ?? '';
      className = prefs.getString('class_name') ?? '';
      studentPhoto = prefs.getString('student_photo') ?? '';
      section = prefs.getString('section') ?? '';
    });
  }

  Future<void> fetchProfileFromApi() async {
    try {
      final res = await ApiService.post(
        context,
        '/student/profile',
        body: {}, // 🔥 Laravel requires body
      );

      if (res == null) return;

      if (res.statusCode != 200) {
        debugPrint('❌ Profile API failed: ${res.statusCode}');
        if (mounted) setState(() => isLoading = false);
        return;
      }

      final data = jsonDecode(res.body);
      debugPrint("📦 Profile Data: $data");

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('roll_no', data['RollNo']?.toString() ?? '');
      await prefs.setString('mobile_no', data['MobileNo']?.toString() ?? '');
      await prefs.setString('father_name', data['FatherName'] ?? '');
      await prefs.setString('mother_name', data['MotherName'] ?? '');
      await prefs.setString('dob', data['DOB'] ?? '');
      await prefs.setString('blood_group', data['BloodGroup'] ?? '');
      await prefs.setString('ledger_no', data['LedgerNo'] ?? '');
      await prefs.setString('gender', data['Gender'] ?? '');
      await prefs.setString('address', data['Address'] ?? '');

      if (!mounted) return;

      setState(() {
        rollNo = data['RollNo']?.toString() ?? '';
        contact = data['MobileNo']?.toString() ?? '';
        fatherName = data['FatherName'] ?? '';
        motherName = data['MotherName'] ?? '';
        dob = data['DOB'] ?? '';
        gender = data['Gender'] ?? '';
        bloodGroup = data['BloodGroup'] ?? '';
        caste = data['Caste'] ?? '';
        religion = data['Religion'] ?? '';
        category = data['Category'] ?? '';
        address = data['Address'] ?? '';
        ledNo = data['LedgerNo'] ?? '';
        adDate = data['AdmissionDate'] ?? '';
        isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Profile exception: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  ImageProvider _profileImage() {
    if (studentPhoto.isEmpty) {
      return const AssetImage('assets/images/logo_new.png');
    }
    return NetworkImage(
      studentPhoto.startsWith('http')
          ? studentPhoto
          : 'https://school.edusathi.in/$studentPhoto',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Student Profile",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary),)
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundImage: _profileImage(),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  studentName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text("Class: $className - $section"),
                                Text("Roll No: $rollNo"),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 30),
                      buildInfoRow(Icons.people, "Father's Name", fatherName),
                      buildInfoRow(Icons.people, "Mother's Name", motherName),
                      buildInfoRow(Icons.person, "Gender", gender),
                      buildInfoRow(Icons.phone, "Contact", contact),
                      buildInfoRow(Icons.cake, "Date Of Birth", dob),
                      buildInfoRow(
                        Icons.calendar_today,
                        "Admission Date",
                        adDate,
                      ),
                      buildInfoRow(Icons.card_membership, "Ledger No.", ledNo),
                      buildInfoRow(
                        Icons.self_improvement,
                        "Religion",
                        religion,
                      ),
                      buildInfoRow(Icons.badge, "Category", category),
                      buildInfoRow(Icons.label_important, "Caste", caste),
                      buildInfoRow(Icons.water_drop, "Blood Group", bloodGroup),
                      buildInfoRow(Icons.location_on, "Address", address),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChangePasswordPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.lock, color: Colors.white),
                        label: const Text(
                          "Change Password",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 10),
          Text("$title: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
