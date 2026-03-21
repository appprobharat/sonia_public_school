import 'dart:async';
import 'dart:convert';
import 'package:sonia_public_school/admin/admin_dashboard.dart';
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
    // 1️⃣ Validation
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

        await sendFcmTokenToLaravel();

        if (!mounted) return;

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
      // 6️⃣ Loader stop (always)
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> sendFcmTokenToLaravel() async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    debugPrint("FCM TOKEN: $fcmToken");

    if (fcmToken == null || fcmToken.isEmpty) {
      debugPrint('❌ FCM token not found');
      return;
    }

    try {
      final response = await ApiService.post(
        context,
        "/save_token",
        body: {'fcm_token': fcmToken},
      );

      if (response != null) {
        debugPrint("✅ FCM token sent successfully");
      }
    } catch (e) {
      debugPrint("❌ FCM Error: $e");
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.white, Colors.white]),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Image.asset(AppAssets.logo, height: 80),
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
                    "Login Here",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),

                  SizedBox(height: 20),

                  TextField(
                    controller: idController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: 15),

                  TextField(
                    controller: passwordController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () =>
                            setState(() => _obscureText = !_obscureText),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
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

                  SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              "Login",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: 20),

                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text("Powered by ", style: TextStyle(fontSize: 12)),
                      Text(
                        "TechInnovation App Pvt. Ltd.®",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.designerColor,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 5),
                      Text(
                        "Visit our website ",
                        style: TextStyle(fontSize: 12),
                      ),
                      GestureDetector(
                        onTap: _launchURL,
                        child: Text(
                          AppAssets.websiteName,
                          style: TextStyle(color: AppColors.info, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
