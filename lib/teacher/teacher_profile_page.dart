import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sonia_public_school/api_service.dart';
import 'package:sonia_public_school/changePasswordPage.dart';


class TeacherProfilePage extends StatefulWidget {
  const TeacherProfilePage({super.key});

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  String name = '';
  String gender = '';
  String employeeId = '';
  String relativeName = '';
  String dob = '';
  String doj = '';
  String contact = '';
  String qualification = '';
  String address = '';
  String className = '';
  String section = '';
  String photo = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadLocalInfo();
    fetchTeacherProfile();
  }

  // ---------------- LOAD LOCAL DATA ----------------
  Future<void> loadLocalInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      name = prefs.getString('teacher_name') ?? '';
      className = prefs.getString('teacher_class') ?? '';
      section = prefs.getString('teacher_section') ?? '';
      photo = prefs.getString('teacher_photo') ?? '';
    });
  }

  // ---------------- FETCH PROFILE ----------------
 Future<void> fetchTeacherProfile() async {
  try {
    final response = await ApiService.post(
      context,
      '/teacher/profile',
    );

    // Token expired → AuthHelper already logged out
    if (response == null) return;

    if (!mounted) return;

    final data = jsonDecode(response.body);

    setState(() {
      gender = data['Gender'] ?? '';
      employeeId = data['EmployeeId'] ?? '';
      relativeName = data['RelativeName'] ?? '';
      dob = data['DOB'] ?? '';
      doj = data['DOJ'] ?? '';
      contact = data['ContactNo']?.toString() ?? '';
      qualification = data['EmpQualification'] ?? '';
      address = data['Address'] ?? '';
      isLoading = false;
    });
  } catch (e) {
    if (!mounted) return;
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Failed to load profile")),
    );
  }
}

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Teacher Profile",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary),)
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundImage: photo.isNotEmpty
                                ? NetworkImage(photo)
                                : const AssetImage(
                                    'assets/images/logo_new.png',
                                  ) as ImageProvider,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                const Text("Class Teacher"),
                                Text("$className - $section"),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 30, thickness: 1),

                      buildInfoRow(Icons.badge, "Employee ID", employeeId),
                      buildInfoRow(Icons.person_outline, "Relative Name", relativeName),
                      buildInfoRow(Icons.male, "Gender", gender),
                      buildInfoRow(Icons.phone, "Contact No.", contact),
                      buildInfoRow(Icons.cake, "Date of Birth", dob),
                      buildInfoRow(Icons.calendar_month, "Joining Date", doj),
                      buildInfoRow(Icons.school, "Qualification", qualification),
                      buildInfoRow(Icons.location_on, "Address", address),

                      const SizedBox(height: 20),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 10),
          Text("$title: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
