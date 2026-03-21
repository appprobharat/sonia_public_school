import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sonia_public_school/admin/employee/add_employee.dart';
import 'package:sonia_public_school/api_service.dart';

class EmployeeListPage extends StatefulWidget {
  const EmployeeListPage({super.key});

  @override
  State<EmployeeListPage> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends State<EmployeeListPage> {
  final TextEditingController searchCtrl = TextEditingController();

  List<Map<String, dynamic>> employees = [];
  List<Map<String, dynamic>> filteredEmployees = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchEmployees();
  }

  Future<void> fetchEmployees() async {
    setState(() => isLoading = true);

    final res = await ApiService.post(context, "/admin/employee/list");

    if (res != null && res.statusCode == 200) {
      employees = List<Map<String, dynamic>>.from(jsonDecode(res.body));
      filteredEmployees = employees;
    }

    setState(() => isLoading = false);
  }

  void _onSearch(String query) {
    if (query.isEmpty) {
      filteredEmployees = employees;
    } else {
      final q = query.toLowerCase();

      filteredEmployees = employees.where((e) {
        final name = (e['Name'] ?? "").toString().toLowerCase();
        final mobile = (e['ContactNo'] ?? "").toString();

        return name.contains(q) || mobile.contains(q);
      }).toList();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6ECF9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: BackButton(),
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          'Employee',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEmployeePage()),
              );

              if (result == true) {
                fetchEmployees();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // SEARCH + ADD EMPLOYEE
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: searchCtrl,
                      onChanged: _onSearch,
                      decoration: const InputDecoration(
                        hintText: 'Search employee...',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // EMPLOYEE LIST
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredEmployees.isEmpty
                ? const Center(child: Text("No Employees Found"))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filteredEmployees.length,
                    itemBuilder: (context, index) {
                      final e = filteredEmployees[index];

                      return EmployeeCard(
                        id: e['id'],
                        name: e['Name'] ?? "",
                        designation: e['Designation'] ?? "",
                        dob: e['DOB'] ?? "-",
                        mobile: e['ContactNo']?.toString() ?? "-",
                        email: e['Email'] ?? "-",
                        photo: e['Photo'] ?? "",
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class EmployeeCard extends StatelessWidget {
  final int id;
  final String name;
  final String designation;
  final String dob;
  final String mobile;
  final String email;
  final String photo;

  const EmployeeCard({
    super.key,
    required this.id,
    required this.name,
    required this.designation,
    required this.dob,
    required this.mobile,
    required this.email,
    required this.photo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          // PHOTO
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black12),
            ),
            child: ClipOval(
              child: photo.isNotEmpty
                  ? Image.network(
                      photo,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.person, color: Colors.grey),
                    )
                  : const Icon(Icons.person, color: Colors.grey),
            ),
          ),

          const SizedBox(width: 10),

          // DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 6),

                // ROW 1
                Row(
                  children: [
                    Expanded(child: _item(Icons.work, designation)),
                    Expanded(child: _item(Icons.cake, dob)),
                  ],
                ),

                const SizedBox(height: 4),

                // ROW 2
                Row(
                  children: [
                    Expanded(child: _item(Icons.call, mobile)),
                    Expanded(child: _item(Icons.email, email)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // SMALL EDIT BUTTON
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEmployeePage(employeeId: id, isEdit: true),
                ),
              );

              if (result == true) {
                final parentState = context
                    .findAncestorStateOfType<_EmployeeListPageState>();

                parentState?.fetchEmployees();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Employee Updated")),
                );
              }
            },
            child: Container(
              height: 28,
              width: 28,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit, size: 16, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.grey),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
