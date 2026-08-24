import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';

class ApiService {
  /// 🔥 CHANGE ONLY HERE
  static const String baseUrl = "https://soniapublicschool.apppro.in/api";
  static const String Url = "https://soniapublicschool.apppro.in";

  /// ⏱ Timeout (iOS safe)
  static const Duration timeout = Duration(seconds: 20);

  /// 🔐 Secure storage (iOS + Android)
  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ================= TOKEN =================

  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();

    final secureToken = await _secureStorage.read(key: 'auth_token');
    if (secureToken != null && secureToken.isNotEmpty) {
      return secureToken;
    }

    return prefs.getString('auth_token') ?? '';
  }

  static Future<Map<String, String>> multipartHeaders() async {
    final token = await _getToken();
    return {'Authorization': 'Bearer $token', 'Accept': 'application/json'};
  }

  static Future<Map<String, String>> headers() async {
    return await _headers();
  }

  // ================= LOGOUT =================

  static Future<void> forceLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _secureStorage.deleteAll();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
      (_) => false,
    );
  }

  // ================= HEADERS =================

  static Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  // ================= POST WITHOUT TOKEN (LOGIN / OTP) =================
  static Future<http.Response?> postPublic(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl$endpoint"),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body ?? {}),
          )
          .timeout(timeout);

      return response;
    } on TimeoutException {
      debugPrint("⏱ API TIMEOUT: $endpoint");
      return null;
    }
  }

  // ================= GET =================

  static Future<http.Response?> get(
    BuildContext context,
    String endpoint,
  ) async {
    final token = await _getToken();

    if (token.isEmpty) {
      await forceLogout(context);
      return null;
    }

    try {
      final response = await http
          .get(Uri.parse("$baseUrl$endpoint"), headers: await _headers())
          .timeout(timeout);

      if (response.statusCode == 401) {
        await forceLogout(context);
        return null;
      }

      return response;
    } on TimeoutException {
      debugPrint("⏱ API TIMEOUT: $endpoint");
      return null;
    }
  }

  static Future<String> getToken() async {
    return await _getToken();
  }

  // ================= POST =================

  static Future<http.Response?> post(
    BuildContext context,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final token = await _getToken();

    if (token.isEmpty) {
      debugPrint("❌ No Token Found");
      await forceLogout(context);
      return null;
    }

    final url = "$baseUrl$endpoint";
    final headers = await _headers();
    final requestBody = jsonEncode(body ?? {});

  

    try {
      final response = await http
          .post(Uri.parse(url), headers: headers, body: requestBody)
          .timeout(timeout);

      if (response.statusCode == 401) {
        debugPrint("❌ Unauthorized (401)");
        await forceLogout(context);
        return null;
      }

      return response;
    } on TimeoutException {
      debugPrint("⏱ API TIMEOUT : $url");
      return null;
    } catch (e, stackTrace) {
      debugPrint("❌ API ERROR : $e");
      debugPrint(stackTrace.toString());
      return null;
    }
  }

  static Future<http.StreamedResponse?> multipartPost(
    BuildContext context,
    String endpoint, {
    Map<String, String>? fields,
    File? file,
    String fileKey = 'Attachment',
  }) async {
    final token = await _getToken();

    if (token.isEmpty) {
      await forceLogout(context);
      return null;
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl$endpoint"),
      );

      request.headers.addAll(await multipartHeaders());

      // ✅ FIELDS
      if (fields != null) {
        request.fields.addAll(fields);
      }

      // ✅ FILE
      if (file != null) {
        request.files.add(
          await http.MultipartFile.fromPath(fileKey, file.path),
        );
      }

      final response = await request.send();

      if (response.statusCode == 401) {
        await forceLogout(context);
        return null;
      }

      return response;
    } on TimeoutException {
      debugPrint("⏱ API TIMEOUT: $endpoint");

      return null;
    } catch (e) {
      debugPrint("❌ MULTIPART ERROR => $e");

      return null;
    }
  }

  // ================= SAVE SESSIONS =================
  static Future<void> saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    // 🔐 Token
    await _secureStorage.write(key: 'auth_token', value: data['token']);
    await prefs.setString('auth_token', data['token']);
    await prefs.setBool('is_logged_in', true);

    final String userType = data['user_type'] ?? '';
    final Map<String, dynamic> profile = data['profile'] ?? {};

    await prefs.setString('user_type', userType);

    // ================= TEACHER =================
    if (userType.toLowerCase() == 'teacher') {
      await prefs.setString('teacher_name', profile['name'] ?? '');
      await prefs.setString('teacher_class', profile['class'] ?? '');
      await prefs.setString('teacher_section', profile['section'] ?? '');
      await prefs.setString('school_name', profile['school'] ?? '');
      await prefs.setString('teacher_photo', profile['photo'] ?? '');

      debugPrint("👨‍🏫 TEACHER LOGIN SAVED");
      debugPrint("Name: ${profile['name']}");
      debugPrint("Class: ${profile['class']}");
      debugPrint("Section: ${profile['section']}");
      debugPrint("School: ${profile['school']}");
      debugPrint("Photo: ${profile['photo']}");
    }
    // ================= STUDENT =================
    else if (userType.toLowerCase() == 'student') {
      await prefs.setString('student_name', profile['student_name'] ?? '');
      await prefs.setString('class_name', profile['class_name'] ?? '');
      await prefs.setString('section', profile['section'] ?? '');
      await prefs.setString('school_name', profile['school_name'] ?? '');
      await prefs.setString('student_photo', profile['student_photo'] ?? '');
    }
  }

  // ================= ATTACHMENTS =================
  static const siblingUrl =
      'https://soniapublicschool.apppro.in/uploads/no_image.png';
}

class AppColors {
  static const primary = Colors.red;
  static const success = Colors.green;
  static const danger = Colors.red;
  static const info = Colors.blue;
  static const designerColor = Colors.redAccent;
  static const LinearGradient appBarGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDC2626), Color(0xFFEF4444), Color(0xFFF87171)],
  );
}

class AppAssets {
  static const defaultAvatar = 'assets/images/default_avatar.png';
  static const logo = 'assets/images/logo.png';
  static const logo_new = 'assets/images/logo_new.png';

  static const schoolName = "SONIA PUBLIC SR. SEC. SCHOOL";
  static const schoolDescription =
      "Empowering Education, Simplifying Management.";

  static const websiteName = "www.soniapublicschool.org";
  static const companyWebsite = "https://soniapublicschool.org/";
}
