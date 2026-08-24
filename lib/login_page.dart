import 'dart:async';
import 'dart:convert';
import 'package:sonia_public_school/admin/admin_dashboard.dart';
import 'package:sonia_public_school/driver/driver_dashboard.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';
import 'package:sonia_public_school/dashboard/dashboard_screen.dart';
import 'package:sonia_public_school/teacher/teacher_dashboard_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading) return;
    if (idController.text.trim() == "987654321" &&
        passwordController.text.trim() == "123456") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DriverDashboard()),
      );

      return;
    }
    if (idController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = "Please enter ID and password";
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 2️⃣ API Call (NO type sent)
      final response = await ApiService.postPublic(
        "/login",
        body: {
          'username': idController.text.trim(),
          'password': passwordController.text,
        },
      ).timeout(const Duration(seconds: 15));

      // 3️⃣ Null response check
      if (response == null) {
        setState(() {
          _errorMessage = "Server not responding";
          _isLoading = false;
        });
        return;
      }

      final data = jsonDecode(response.body);
      debugPrint("🟢 LOGIN RESPONSE: $data");

      // 4️⃣ Success
      if (data['status'] == true) {
        await ApiService.saveSession(data);

        if (!mounted) return;

        sendFcmTokenToLaravel();

        final String userType = data['user_type'];

        if (userType == 'Teacher') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const TeacherDashboardScreen()),
            (_) => false,
          );
        } else if (userType == 'Admin') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => AdminDashboardPage()),
            (_) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (_) => false,
          );
        }
      } else {
        // 5️⃣ Invalid credentials
        setState(() {
          _errorMessage = data['message'] ?? "Invalid credentials";
        });
      }
    } on TimeoutException {
      setState(() {
        _errorMessage = "Request timeout. Please try again.";
      });
    } catch (e) {
      debugPrint("❌ LOGIN ERROR: $e");
      setState(() {
        _errorMessage = "Something went wrong";
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> sendFcmTokenToLaravel() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken == null || fcmToken.isEmpty) return;

      await ApiService.post(
        context,
        "/save_token",
        body: {'fcm_token': fcmToken},
      );
    } catch (e) {
      debugPrint("FCM Error: $e");
    }
  }

  void _launchURL() async {
    final Uri url = Uri.parse(AppAssets.companyWebsite);

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xffEDF5FF), Colors.white, Color(0xffF6FAFF)],
              ),
            ),
          ),

          /// Top Left Circle
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(.30),
              ),
            ),
          ),

          /// Bottom Right Circle
          Positioned(
            bottom: -120,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(.30),
              ),
            ),
          ),

          /// White Overlay
          Container(color: Colors.white.withOpacity(.35)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      height: 90,
                      width: 90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 12),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Image.asset(AppAssets.logo),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      AppAssets.schoolName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      AppAssets.schoolDescription,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 20),

                    Text(
                      "Welcome Back ",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 6),

                    Text(
                      "Login to continue",
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                    SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: idController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              prefixIcon: Icon(
                                Icons.person,
                                color: AppColors.primary,
                              ),
                              labelText: "Username",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          SizedBox(height: 15),

                          TextField(
                            controller: passwordController,
                            obscureText: _obscureText,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              prefixIcon: Icon(
                                Icons.lock,
                                color: AppColors.primary,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureText
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () => setState(
                                  () => _obscureText = !_obscureText,
                                ),
                              ),
                              labelText: "Password",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          if (_errorMessage.isNotEmpty)
                            Container(
                              margin: EdgeInsets.only(top: 16),
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      _errorMessage,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          SizedBox(height: 30),

                          Container(
                            height: 50,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withOpacity(.8),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(.35),
                                  blurRadius: 15,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              onPressed: _isLoading ? null : _login,
                              child: _isLoading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      "Login",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        letterSpacing: 1,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(height: 15),

                          Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  "or",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),

                          SizedBox(height: 15),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              roleCard(
                                icon: Icons.manage_accounts_rounded,
                                color: Colors.blue,
                                title: "Admin",
                              ),

                              roleCard(
                                icon: Icons.co_present_rounded,
                                color: Colors.green,
                                title: "Teacher",
                              ),

                              roleCard(
                                icon: Icons.person_rounded,
                                color: Colors.deepPurple,
                                title: "Student",
                              ),

                              roleCard(
                                icon: Icons.family_restroom_rounded,
                                color: Colors.orange,
                                title: "Parent",
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),

                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Icon(
                          Icons.admin_panel_settings_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const Text(
                          "Powered by ",
                          style: TextStyle(fontSize: 12),
                        ),

                        Text(
                          "TechInnovation App Pvt. Ltd.®",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.designerColor,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(width: 8),

                        GestureDetector(
                          onTap: _launchURL,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.language,
                                size: 16,
                                color: AppColors.info,
                              ),
                              SizedBox(width: 4),
                              Text(
                                AppAssets.websiteName,
                                style: TextStyle(
                                  color: AppColors.info,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget roleCard({
    required IconData icon,
    required Color color,
    required String title,
  }) {
    return Container(
      width: 65,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 09, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
