import 'dart:convert';
import 'package:flutter/material.dart';
import '../api_service.dart';

class StudentAlertPage extends StatefulWidget {
  const StudentAlertPage({super.key});

  @override
  State<StudentAlertPage> createState() => _StudentAlertPageState();
}

class _StudentAlertPageState extends State<StudentAlertPage> {
  bool sending = false;

  bool selectAll = true;

  final TextEditingController messageCtrl = TextEditingController();

  bool hasLoadedData = false;
  List<Map<String, dynamic>> students = [];
  bool loadingStudents = false;
  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    setState(() => loadingStudents = true);

    final res = await ApiService.post(
      context,
      "/teacher/student/list",
      body: {},
    );

    if (res != null && res.statusCode == 200) {
      final List data = jsonDecode(res.body);

      students = data.map((e) {
        return {
          "id": e["id"],
          "name": e["StudentName"],
          "father": e["FatherName"],
          "roll": e["RollNo"],
          "dob": e["DOB"],
          "image": e["StudentPhoto"],
          "selected": true,
        };
      }).toList();

      selectAll = true;
    }

    setState(() => loadingStudents = false);
  }

  Future<void> sendAlert(List<int> studentIds) async {
    setState(() => sending = true);

    final res = await ApiService.post(
      context,
      "/teacher/student/alert",
      body: {"message": messageCtrl.text.trim(), "student_ids": studentIds},
    );

    setState(() => sending = false);

    if (res != null && res.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Alert sent successfully")));
      messageCtrl.clear();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to send alert")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff3e5f5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: BackButton(),
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          "Student Alert",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            _messageBox(),
            _selectAll(),
            Expanded(child: _studentList()),
          ],
        ),
      ),
    );
  }

  Widget _messageBox() {
    return TextField(
      controller: messageCtrl,
      maxLines: 2,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: "Enter your message here...",
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _selectAll() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Checkbox(
                  value: selectAll,
                  onChanged: (v) {
                    setState(() {
                      selectAll = v ?? false;
                      for (var student in students) {
                        student['selected'] = selectAll;
                      }
                    });
                  },
                ),
                const Text("Select All", style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: sending ? Colors.green.shade300 : Colors.green,
                disabledBackgroundColor: Colors.green.shade300,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: sending
                  ? null
                  : () {
                      final selectedStudents = students
                          .where((s) => s['selected'] == true)
                          .toList();

                      if (selectedStudents.isEmpty ||
                          messageCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Select students & enter message"),
                          ),
                        );
                        return;
                      }

                      final selectedIds = selectedStudents
                          .map<int>((s) => s['id'] as int)
                          .toList();

                      sendAlert(selectedIds);
                    },
              child: sending
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.send, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          "Send",
                          style: TextStyle(fontSize: 13, color: Colors.white),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentList() {
    if (loadingStudents) {
      return const Center(child: CircularProgressIndicator());
    }

    if (students.isEmpty) {
      return const Center(child: Text("No students found"));
    }

    return ListView.builder(
      itemCount: students.length,
      itemBuilder: (context, index) {
        final s = students[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: s['selected'],
                onChanged: (v) {
                  setState(() {
                    s['selected'] = v;
                    selectAll = students.every(
                      (stu) => stu['selected'] == true,
                    );
                  });
                },
              ),
              CircleAvatar(
                radius: 22,
                backgroundImage: s['image'] != null
                    ? NetworkImage(s['image'])
                    : null,
                backgroundColor: Colors.grey.shade300,
                child: s['image'] == null
                    ? const Icon(Icons.person, size: 22)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      "Father: ${s['father']}",
                      style: const TextStyle(fontSize: 12),
                    ),

                    Text(
                      "Roll No: ${s['roll']}",
                      style: const TextStyle(fontSize: 12),
                    ),

                    Text(
                      "DOB: ${s['dob']}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
