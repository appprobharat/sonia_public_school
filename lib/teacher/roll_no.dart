import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';

class UpdateRollNoPage extends StatefulWidget {
  const UpdateRollNoPage({super.key});

  @override
  State<UpdateRollNoPage> createState() => _UpdateRollNoPageState();
}

class _UpdateRollNoPageState extends State<UpdateRollNoPage> {
  List _students = [];
  bool _isLoading = false;

  final Map<int, TextEditingController> controllers = {};

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    if (!mounted) return;

    debugPrint("🟡 fetchStudents CALLED");

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.post(
        context,
        '/teacher/student/list',
        body: {"type": "all"},
      );

      if (response == null) {
        debugPrint("🔴 RESPONSE NULL (TOKEN EXPIRED)");
        return;
      }

      debugPrint("🟢 STATUS CODE: ${response.statusCode}");
      debugPrint("📦 RAW BODY: ${response.body}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        debugPrint("📦 DECODED TYPE: ${decoded.runtimeType}");

        List list = [];

        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          list = decoded['data'];
        }

        debugPrint("📊 STUDENT COUNT: ${list.length}");

        setState(() {
          _students = list;
        });
        initControllers();
      } else {
        debugPrint("❌ API ERROR: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load students (${response.statusCode})'),
          ),
        );
      }
    } catch (e) {
      debugPrint("🚨 EXCEPTION: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint("🔚 fetchStudents END");
      }
    }
  }

  void initControllers() {
    controllers.clear(); 

    for (int i = 0; i < _students.length; i++) {
      controllers[i] = TextEditingController(
        text: _students[i]['RollNo']?.toString() ?? '',
      );
    }
  }

  Future<void> updateRollNumbers() async {
    List<int> stdIds = [];
    List<String> rollNos = [];

    debugPrint("🟡 UPDATE FUNCTION CALLED");

    for (int i = 0; i < _students.length; i++) {
      final roll = controllers[i]?.text.trim() ?? '';

      debugPrint("👉 Student: ${_students[i]}");
      debugPrint("👉 Roll Entered: $roll");

      if (roll.isEmpty) {
        debugPrint("❌ EMPTY ROLL FOUND at index $i");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Roll No cannot be empty")),
        );
        return;
      }

      final studentId = _students[i]['id']; // ⚠️ verify key

      debugPrint("👉 Student ID: $studentId");

      stdIds.add(studentId);
      rollNos.add(roll);
    }

    /// ✅ FINAL BODY (ARRAY FORMAT)
    final body = {"std_ids": stdIds, "roll_no": rollNos};

    debugPrint("📤 FINAL BODY: $body");

    setState(() => _isLoading = true);

    try {
      debugPrint("🚀 CALLING API...");

      final response = await ApiService.post(
        context,
        '/teacher/student/update_roll_no',
        body: body,
      );

      if (response == null) {
        debugPrint("🔴 RESPONSE NULL (TOKEN ISSUE)");
        return;
      }

      debugPrint("🟢 STATUS CODE: ${response.statusCode}");
      debugPrint("📦 RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200) {
        debugPrint("✅ UPDATE SUCCESS");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Roll Numbers Updated Successfully")),
        );

        fetchStudents();
      } else {
        debugPrint("❌ UPDATE FAILED");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed (${response.statusCode})")),
        );
      }
    } catch (e) {
      debugPrint("🚨 EXCEPTION: $e");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
      debugPrint("🔚 UPDATE FUNCTION END");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Update Roll No ",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: BackButton(),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                ? const Center(child: Text("No Students Found"))
                : ListView.builder(
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final student = _students[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              /// Student Name + Father Name (Column)
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    /// Student Name with Serial
                                    Text(
                                      "${index + 1}. ${student['StudentName'] ?? ''}",
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),

                                    const SizedBox(height: 2),

                                    /// Father Name (smaller)
                                    Text(
                                      student['FatherName'] ?? '',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12, // 👈 smaller
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              /// Roll No Field (Compact)
                              SizedBox(
                                width: 80,
                                height: 38,
                                child: TextField(
                                  controller: controllers[index],
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: "Roll",
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                      horizontal: 8,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: updateRollNumbers,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Update Roll No",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
