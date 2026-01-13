
import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';

class AddComplaint extends StatefulWidget {
  const AddComplaint({super.key});

  @override
  State<AddComplaint> createState() => _AddComplaintPageState();
}

class _AddComplaintPageState extends State<AddComplaint> {
  final TextEditingController _descriptionController = TextEditingController();
  bool isSubmitting = false;

  // ====================================================
  // 🚀 SUBMIT COMPLAINT (SAFE FOR iOS + ANDROID)
  // ====================================================
  Future<void> submitComplaint() async {
    final description = _descriptionController.text.trim();

    if (description.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a complaint description"),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => isSubmitting = true);

    try {
      debugPrint("📤 COMPLAINT BODY: $description");

      final res = await ApiService.post(
        context,
        "/student/complaint/store",
        body: {
          "Description": description,
        },
      );

      // AuthHelper already handles 401 + logout
      if (res == null) return;

      debugPrint("📥 COMPLAINT STATUS: ${res.statusCode}");
      debugPrint("📥 COMPLAINT BODY: ${res.body}");

      if (!mounted) return;

      if (res.statusCode == 200) {
        _descriptionController.clear();

        Navigator.pop(context); // back to list

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Complaint submitted successfully"),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to submit complaint"),
          ),
        );
      }
    } catch (e) {
      debugPrint("🚨 COMPLAINT ERROR: $e");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Something went wrong"),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Register Complaint",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        leading: const BackButton(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _descriptionController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: "Write your complaint here...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: isSubmitting ? null : submitComplaint,
              icon: const Icon(Icons.send, color: Colors.white),
              label: const Text(
                "Submit Complaint",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
