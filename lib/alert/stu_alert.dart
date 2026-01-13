import 'dart:convert';
import 'package:flutter/material.dart';
import '../api_service.dart';

class StudentAlertPage extends StatefulWidget {
  const StudentAlertPage({super.key});

  @override
  State<StudentAlertPage> createState() => _StudentAlertPageState();
}

class _StudentAlertPageState extends State<StudentAlertPage> {
  TextEditingController searchController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  List<dynamic> students = [];
  List<dynamic> filteredStudents = [];
  Set<String> selectedStudentIds = {};

  bool isLoading = false;
  bool isSending = false; // 🔥 NEW → Loader for Send Button
  bool selectAll = false;

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  @override
  void dispose() {
    searchController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> fetchStudents() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
   final res = await ApiService.post(
  context,
  "/teacher/student/list",
);


      // 🔐 AuthHelper handles 401 + logout
      if (res == null) return;

      debugPrint("📥 STUDENT LIST STATUS: ${res.statusCode}");
      debugPrint("📥 STUDENT LIST BODY: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (!mounted) return;
        setState(() {
          students = List<dynamic>.from(data);
          filteredStudents = List<dynamic>.from(data);
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load students")),
        );
      }
    } catch (e) {
      debugPrint("🚨 FETCH STUDENTS ERROR: $e");

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Something went wrong")));
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  void filterStudents(String query) {
    if (!mounted) return;

    setState(() {
      filteredStudents = students
          .where(
            (s) => s["StudentName"].toString().toLowerCase().contains(
              query.toLowerCase(),
            ),
          )
          .toList();
    });
  }

  // ====================================================
  // 🔴 SEND ALERT (Loader Added)
  // ====================================================
  Future<void> sendAlert() async {
    final message = descriptionController.text.trim();

    // 🔒 Validation
    if (message.isEmpty || selectedStudentIds.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Please enter message and select students"),
        ),
      );
      return;
    }

    // 🔄 Start loader
    if (!mounted) return;
    setState(() => isSending = true);

    try {
      // 🔹 Collect FCM tokens safely
      final List<String> tokens = [];

      for (final student in students) {
        final id = student["id"]?.toString();
        final fcm = student["fcm_token"];

        if (id != null &&
            selectedStudentIds.contains(id) &&
            fcm != null &&
            fcm.toString().isNotEmpty) {
          tokens.add(fcm.toString());
        }
      }

      if (tokens.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("⚠️ No FCM token found")));
        return;
      }

      final body = {"message": message, "tokens": tokens};

      debugPrint("📤 ALERT BODY: $body");

      // 🔐 SAFE API CALL (same pattern as dashboard)
    final res = await ApiService.post(
  context,
  "/teacher/student/alert",
  body: body,
);

      // ⚠️ AuthHelper already handles 401 + logout
      if (res == null) return;

      debugPrint("📥 ALERT STATUS: ${res.statusCode}");
      debugPrint("📥 ALERT BODY: ${res.body}");

      if (res.statusCode == 200) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Alert Sent Successfully")),
        );

        descriptionController.clear();
        setState(() {
          selectAll = false;
          selectedStudentIds.clear();
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ Failed: ${res.body}")));
      }
    } catch (e) {
      debugPrint("🚨 SEND ALERT ERROR: $e");

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Something went wrong")));
    } finally {
      // 🔄 Stop loader safely
      if (!mounted) return;
      setState(() => isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Alert"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary),)
          : Column(
              children: [
                // MESSAGE BOX
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Write alert message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                // SEARCH BOX
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    onChanged: filterStudents,
                    decoration: InputDecoration(
                      hintText: "Search Student...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                // SELECT ALL
                Row(
                  children: [
                    Checkbox(
                      value: selectAll,
                      onChanged: (val) {
                        if (!mounted) return;

                        setState(() {
                          selectAll = val ?? false;

                          if (selectAll && filteredStudents.isNotEmpty) {
                            selectedStudentIds = filteredStudents
                                .map((s) => s["id"].toString())
                                .toSet();
                          } else {
                            selectedStudentIds.clear();
                          }
                        });
                      },
                    ),
                    const Text("Select All Students"),
                  ],
                ),

                // STUDENT LIST
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      final id = student["id"].toString();
                      final isChecked = selectedStudentIds.contains(id);

                      return Card(
                        child: ListTile(
                          leading: Checkbox(
                            value: isChecked,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  selectedStudentIds.add(id);
                                } else {
                                  selectedStudentIds.remove(id);
                                }
                                selectAll =
                                    selectedStudentIds.length ==
                                    filteredStudents.length;
                              });
                            },
                          ),
                          title: Text(student["StudentName"]),
                          subtitle: Text(
                            "Father: ${student["FatherName"]}\nRoll: ${student["RollNo"]}",
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // SEND BUTTON (with loader)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(14),
                      ),
                      onPressed: isSending ? null : sendAlert,
                      child: isSending
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Send Alert",
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
