import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final TextEditingController searchController = TextEditingController();

  String selectedStop = "All Stops";

  final List<String> stops = [
    "All Stops",
    "Patna Junction",
    "Kankarbagh",
    "Rajendra Nagar",
    "Boring Road",
    "SONIA Public School",
  ];

  List<StudentModel> students = [];
  List<StudentModel> filteredStudents = [];

  @override
  void initState() {
    super.initState();

    students = dummyStudents;
    filteredStudents = students;

    searchController.addListener(filterStudents);
  }

  void filterStudents() {
    setState(() {
      filteredStudents = students.where((student) {
        final search = searchController.text.toLowerCase();

        final matchSearch =
            student.name.toLowerCase().contains(search) ||
            student.roll.contains(search);

        final matchStop = selectedStop == "All Stops"
            ? true
            : student.stop == selectedStop;

        return matchSearch && matchStop;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    int picked = filteredStudents.where((e) => e.picked).length;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Students",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),

      body: Column(
        children: [
          /// HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.blueGrey,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SummaryBox(
                        "Total",
                        "${filteredStudents.length}",
                        Icons.groups,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _SummaryBox(
                        "Picked",
                        "$picked",
                        Icons.check_circle,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _SummaryBox(
                        "Waiting",
                        "${filteredStudents.length - picked}",
                        Icons.schedule,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: filteredStudents.isEmpty
                        ? 0
                        : picked / filteredStudents.length,
                    minHeight: 7,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  /// STOP
                  DropdownButtonFormField<String>(
                    value: selectedStop,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.location_on),
                      filled: true,
                      fillColor: Colors.white,
                      labelText: "Select Stop",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: stops
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) {
                      selectedStop = v!;
                      filterStudents();
                    },
                  ),

                  const SizedBox(height: 14),

                  /// SEARCH
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search student...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredStudents.length,
                      itemBuilder: (_, index) {
                        final student = filteredStudents[index];

                        return StudentCard(student: student, onChanged: () {});
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryBox(this.title, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),

          const SizedBox(height: 6),

          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class StudentModel {
  final String name;
  final String roll;
  final String studentClass;
  final String phone;
  final String stop;

  bool picked;

  StudentModel({
    required this.name,
    required this.roll,
    required this.studentClass,
    required this.phone,
    required this.stop,
    this.picked = false,
  });
}

List<StudentModel> dummyStudents = [
  StudentModel(
    name: "Rahul Kumar",
    roll: "01",
    studentClass: "5-A",
    phone: "9876543210",
    stop: "Kankarbagh",
  ),

  StudentModel(
    name: "Aman Singh",
    roll: "02",
    studentClass: "6-B",
    phone: "9876501234",
    stop: "Rajendra Nagar",
    picked: true,
  ),

  StudentModel(
    name: "Priya Kumari",
    roll: "03",
    studentClass: "7-A",
    phone: "9876511111",
    stop: "Boring Road",
  ),

  StudentModel(
    name: "Ankit Raj",
    roll: "04",
    studentClass: "8-C",
    phone: "9876522222",
    stop: "Patna Junction",
    picked: true,
  ),
];

class StudentCard extends StatelessWidget {
  final StudentModel student;
  final VoidCallback onChanged;

  const StudentCard({
    super.key,
    required this.student,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          /// Top Row
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withOpacity(.12),
                child: Text(
                  student.name[0],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      "Class ${student.studentClass} • Roll ${student.roll}",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),

              _StatusBadge(student.picked),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _InfoTile(Icons.location_on_outlined, student.stop),
              ),

              const SizedBox(width: 10),

              Expanded(child: _InfoTile(Icons.phone, student.phone)),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO Call Parent
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text("Call"),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onChanged,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: student.picked
                        ? Colors.orange
                        : Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    student.picked ? Icons.undo : Icons.check,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    student.picked ? "Undo" : "Picked",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool picked;

  const _StatusBadge(this.picked);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: picked
            ? Colors.green.withOpacity(.12)
            : Colors.orange.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        picked ? "Picked" : "Waiting",
        style: TextStyle(
          color: picked ? Colors.green : Colors.orange,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoTile(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xffF6F8FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),

          const SizedBox(width: 6),

          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
