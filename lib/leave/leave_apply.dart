import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sonia_public_school/api_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ApplyLeavePage extends StatefulWidget {
  const ApplyLeavePage({super.key});

  @override
  State<ApplyLeavePage> createState() => _ApplyLeavePageState();
}

class _ApplyLeavePageState extends State<ApplyLeavePage> {
  final TextEditingController purposeController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;
  File? selectedFile;
  String? fileName;
  final ImagePicker picker = ImagePicker();
  bool isLoading = false;
  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    startDate = now;
    endDate = now.add(const Duration(days: 1));
  }

  String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> pickImage() async {
    final XFile? pickedFile = await showModalBottomSheet<XFile>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Camera"),
                onTap: () async {
                  final image = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 70,
                  );
                  Navigator.pop(context, image);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text("Gallery"),
                onTap: () async {
                  final image = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 70,
                  );
                  Navigator.pop(context, image);
                },
              ),
            ],
          ),
        );
      },
    );

    if (pickedFile != null) {
      setState(() {
        selectedFile = File(pickedFile.path);
        fileName = pickedFile.name;
      });
    }
  }

  Future<void> pickDate({required bool isStart}) async {
    DateTime initialDate = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;

          if (endDate != null && endDate!.isBefore(startDate!)) {
            endDate = null;
          }
        } else {
          endDate = picked;
        }
      });
    }
  }

  Future<void> submitLeave() async {
    if (purposeController.text.trim().isEmpty) {
      showSnack("Enter purpose");
      return;
    }

    if (startDate == null || endDate == null) {
      showSnack("Select start and end date");
      return;
    }

    if (endDate!.isBefore(startDate!)) {
      showSnack("End date cannot be before start date");
      return;
    }

    setState(() => isLoading = true);

    try {
      final uri = Uri.parse("${ApiService.baseUrl}/student/leave/apply");

      final request = http.MultipartRequest("POST", uri);

      /// 🔹 Headers (token)
      final headers = await ApiService.headers();
      request.headers.addAll(headers);

      /// 🔹 Fields
      request.fields["Purpose"] = purposeController.text.trim();
      request.fields["StartDate"] = formatDate(startDate!);
      request.fields["EndDate"] = formatDate(endDate!);

      /// 🔥 Attachment (MAIN PART)
      if (selectedFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            "Attachment", // 👈 key same hona chahiye backend se
            selectedFile!.path,
          ),
        );
      }

      final response = await request.send();

      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        showSnack("Leave applied successfully");
        Navigator.pop(context, true);
      } else {
        showSnack("Failed to apply leave");
      }
    } catch (e) {
      setState(() => isLoading = false);
      showSnack("Error occurred");
    }
  }

  void showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value == null ? label : DateFormat('dd MMM yyyy').format(value),
                style: TextStyle(
                  fontSize: 13,
                  color: value == null ? Colors.grey : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply Leave'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                /// 🔹 Date Row (START + END)
                Row(
                  children: [
                    Expanded(
                      child: buildDateField(
                        label: "Start Date",
                        value: startDate,
                        onTap: () => pickDate(isStart: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: buildDateField(
                        label: "End Date",
                        value: endDate,
                        onTap: () => pickDate(isStart: false),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                /// 🔹 Leave Days Indicator (Auto)
                if (startDate != null && endDate != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        "Total Days: ${endDate!.difference(startDate!).inDays + 1}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                const SizedBox(height: 30),

                /// 🔹 Purpose Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: purposeController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: "Enter leave purpose...",
                      border: InputBorder.none,
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// 🔹 Title
                      const Text(
                        "Attachment",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      /// 🔹 Upload / File Row
                      Row(
                        children: [
                          /// File Name or Placeholder
                          Expanded(
                            child: InkWell(
                              onTap: pickImage,
                              child: Row(
                                children: [
                                  const Icon(Icons.attach_file, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      fileName ?? "Upload Image",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: fileName == null
                                            ? Colors.grey
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          /// 🔹 Delete Button (ONLY if file selected)
                          if (selectedFile != null)
                            InkWell(
                              onTap: () {
                                setState(() {
                                  selectedFile = null;
                                  fileName = null;
                                });
                              },
                              child: const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                /// 🔹 Submit Button (Better UI)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isLoading ? null : submitLeave,
                    child: const Text(
                      "Apply Leave",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// 🔹 Loader
          if (isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
