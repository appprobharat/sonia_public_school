import 'dart:convert';
import 'package:sonia_public_school/admin/complaint/complaint_history.dart';
import 'package:flutter/material.dart';
import 'package:sonia_public_school/admin/complaint/add_complaint.dart';
import 'package:sonia_public_school/api_service.dart';

class AdminComplaintList extends StatefulWidget {
  const AdminComplaintList({super.key});

  @override
  State<AdminComplaintList> createState() => _AdminComplaintListState();
}

class _AdminComplaintListState extends State<AdminComplaintList> {
  final TextEditingController searchCtrl = TextEditingController();

  List complaints = [];
  List filteredComplaints = [];

  late String fromDate;
  late String toDate;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final oneMonthBack = DateTime(now.year, now.month - 1, now.day);

    fromDate = _formatDate(oneMonthBack);
    toDate = _formatDate(now);
    fetchComplaints();
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String _formatDisplayDate(String date) {
    final parts = date.split("-"); // yyyy-MM-dd
    if (parts.length == 3) {
      return "${parts[2]}-${parts[1]}-${parts[0]}";
    }
    return date;
  }

  Future<void> _pickDate(bool isFrom) async {
    DateTime initialDate = DateTime.parse(isFrom ? fromDate : toDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
    if (isFrom && picked.isAfter(DateTime.parse(toDate))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("From date cannot be after To date")),
      );
      return;
    }

    if (!isFrom && picked.isBefore(DateTime.parse(fromDate))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("To date cannot be before From date")),
      );
      return;
    }
      
      String formatted = _formatDate(picked);

      setState(() {
        if (isFrom) {
          fromDate = formatted;
        } else {
          toDate = formatted;
        }
      });

      fetchComplaints();
    }
  }

  // ================= FETCH API =================
  Future<void> fetchComplaints() async {
    setState(() => isLoading = true);

    final response = await ApiService.post(
      context,
      "/admin/complaint/list",
      body: {"from": fromDate, "to": toDate},
    );

    if (response == null) {
      print("Response is NULL");
      setState(() => isLoading = false);
      return;
    }

    print("Status Code: ${response.statusCode}");
    print("Raw Body: ${response.body}");

    try {
      final decoded = jsonDecode(response.body);
      print("Decoded Response: $decoded");

      if (response.statusCode == 200) {
        complaints = decoded;
        filteredComplaints = complaints;
        print("Total Complaints: ${complaints.length}");
      } else {
        print("API Error Response");
        complaints = [];
        filteredComplaints = [];
      }
    } catch (e) {
      print("JSON Decode Error: $e");
      complaints = [];
      filteredComplaints = [];
    }

    print("=========================================");

    setState(() => isLoading = false);
  }

  // ================= SEARCH =================
  void _onSearch(String query) {
    if (query.isEmpty) {
      filteredComplaints = complaints;
    } else {
      final q = query.toLowerCase();
      filteredComplaints = complaints.where((p) {
        final name = (p['Name'] ?? "").toString().toLowerCase();
        final phone = (p['ContactNo'] ?? "").toString();
        return name.contains(q) || phone.contains(q);
      }).toList();
    }
    setState(() {});
  }

 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4e9fb),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: BackButton(),
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          'Complaints',
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
                MaterialPageRoute(builder: (_) => const AdminAddComplaint()),
              );

              if (result == true) {
                fetchComplaints();
              }
            },
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                _dateField("From", fromDate, true),
                const SizedBox(width: 8),
                _dateField("To", toDate, false),
              ],
            ),
          ),
          _searchBar(context),

          const SizedBox(height: 8),

          // ================= LIST =================
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredComplaints.isEmpty
                ? const Center(child: Text("No complaints found"))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: filteredComplaints.length,
                    itemBuilder: (context, index) {
                      return _complaintCard(filteredComplaints[index], index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _dateField(String label, String date, bool isFrom) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _pickDate(isFrom),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _formatDisplayDate(date),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // SEARCH BAR
  Widget _searchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 5, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: searchCtrl,
                      onChanged: _onSearch,
                      decoration: const InputDecoration(
                        hintText: "Search by name or contact...",
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _complaintCard(Map data, int index) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminComplaintHistory(complaintId: data['id'],  complaintData: data,),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ===== ROW 1 : STUDENT NAME - CLASS + DATE =====
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "${data['Name']} - ${data['Class']}(${data['Section']})",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(data['Date'], style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              /// ===== ROW 2 : CONTACT + ADDED BY + EDIT =====
              Row(
                children: [
                  Icon(Icons.phone, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      data['ContactNo'].toString(),
                      style: const TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(width: 6),

                  Icon(Icons.person, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text("Added by ", style: const TextStyle(fontSize: 11)),
                  Expanded(
                    child: Text(
                      data['AddedBy'],
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(width: 6),
                ],
              ),

              const SizedBox(height: 8),

              /// ===== ROW 3 : DESCRIPTION + STATUS BADGE =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Description expands
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.description,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            data['Description'],
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _statusBadge(data['Status']),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(int status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status == 0 ? Colors.red : Colors.green,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status == 0 ? "Pending" : "Resolved",
        style: const TextStyle(fontSize: 10, color: Colors.white),
      ),
    );
  }
}
