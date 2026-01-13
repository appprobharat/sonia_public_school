import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../login_page.dart';

class AuthHelper {
  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// 🔐 Get token (iOS + Android safe)
  static Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    final secureToken = await _secureStorage.read(key: 'auth_token');
    if (secureToken != null && secureToken.isNotEmpty) {
      debugPrint("🔐 TOKEN FROM SECURE STORAGE");
      return secureToken;
    }

    final prefsToken = prefs.getString('auth_token') ?? '';
    if (prefsToken.isNotEmpty) {
      debugPrint("🔐 TOKEN FROM PREFS");
      return prefsToken;
    }

    debugPrint("❌ NO TOKEN FOUND");
    return '';
  }

  /// 🌐 Auth GET (auto 401 handle)
  static Future<http.Response?> get(BuildContext context, String url) async {
    final token = await getToken();

    if (token.isEmpty) {
      await forceLogout(context);
      return null;
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    debugPrint("🌐 API GET $url → ${response.statusCode}");

    if (response.statusCode == 401) {
      debugPrint("🚫 401 → AUTO LOGOUT");
      await forceLogout(context);
      return null;
    }

    return response;
  }

  /// 🚫 Logout everywhere (safe)
  static Future<void> forceLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    await _secureStorage.delete(key: 'auth_token');
    await prefs.clear();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
      (_) => false,
    );
  }

  /// 🌐 Auth POST (auto 401 handle)
  static Future<http.Response?> post(
    BuildContext context,
    String url, {
    Map<String, dynamic>? body,
  }) async {
    final token = await getToken();

    if (token.isEmpty) {
      await forceLogout(context);
      return null;
    }

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: body != null ? jsonEncode(body) : null,
    );

    debugPrint("🌐 API $url → ${response.statusCode}");

    if (response.statusCode == 401) {
      debugPrint("🚫 401 → AUTO LOGOUT");
      await forceLogout(context);
      return null;
    }

    return response;
  }
}
