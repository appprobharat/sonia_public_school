import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final currentController = TextEditingController();
  final newController = TextEditingController();
  final confirmController = TextEditingController();

  bool isSubmitting = false;

 Future<void> handleChangePassword() async {
  if (!_formKey.currentState!.validate()) return;

  final currentPass = currentController.text.trim();
  final newPass = newController.text.trim();
  final confirmPass = confirmController.text.trim();

  if (currentPass == newPass) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("New password cannot be same as current password"),
      ),
    );
    return;
  }

  if (newPass != confirmPass) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("New password and confirm password do not match"),
      ),
    );
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text("Confirm Change"),
      content: const Text("Are you sure you want to change your password?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text("Yes"),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  if (!mounted) return;
  setState(() => isSubmitting = true);

  try {
    final response = await ApiService.post(
      context,
      '/password',
      body: {
        'current_pass': currentPass,
        'new_pass': newPass,
      },
    );

    if (!mounted) return;
    setState(() => isSubmitting = false);

    // 🔐 Auto logout already handled inside AuthHelper
    if (response == null) return;

    final data = jsonDecode(response.body);

    if (data['status'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password changed successfully!")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? "Password change failed"),
        ),
      );
    }
  } catch (e) {
    if (!mounted) return;
    setState(() => isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Network error: $e")),
    );
  }
}


  @override
  void dispose() {
    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Change Password',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: currentController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter current password' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(Icons.lock_open),
                ),
                validator: (value) =>
                    value!.length < 8 ? 'Minimum 8 characters' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) =>
                    value!.length < 8 ? 'Minimum 8 characters required' : null,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : handleChangePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Submit",
                          style:
                              TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
