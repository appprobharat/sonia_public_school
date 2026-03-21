import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sonia_public_school/admin/enquiry/add_enquiry.dart';
import 'package:sonia_public_school/api_service.dart';

class AdmissionEnquiryPage extends StatefulWidget {
  const AdmissionEnquiryPage({super.key});

  @override
  State<AdmissionEnquiryPage> createState() => _AdmissionEnquiryPageState();
}

class _AdmissionEnquiryPageState extends State<AdmissionEnquiryPage> {
  List<dynamic> enquiryList = [];
  bool isLoading = false;

  List<dynamic> filteredList = [];
  final TextEditingController searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchEnquiries();
  }

  Future<void> fetchEnquiries() async {
    setState(() => isLoading = true);

    print("🔵 Calling Enquiry List API...");

    final response = await ApiService.post(
      context,
      "/admin/student/enquiry/list",
    );

    print("🟡 Status Code: ${response?.statusCode}");
    print("🟡 Raw Response: ${response?.body}");

    if (response != null && response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      print("🟢 Decoded Type: ${decoded.runtimeType}");
      print("🟢 Decoded Length: ${decoded.length}");

      setState(() {
        enquiryList = decoded;
        filteredList = decoded;
        isLoading = false;
      });
    } else {
      print("🔴 API FAILED");
      setState(() => isLoading = false);
    }
  }

  void filterSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredList = enquiryList;
      });
    } else {
      setState(() {
        filteredList = enquiryList.where((enquiry) {
          final fatherName = (enquiry['FatherName'] ?? "")
              .toString()
              .toLowerCase();
          return fatherName.contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5ECF9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: BackButton(),
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          'Admission Enquiry',
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
                MaterialPageRoute(builder: (_) => const AddEnquiryPage()),
              );

              if (result == true) {
                fetchEnquiries();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // SEARCH + ADD
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: searchCtrl,
                onChanged: filterSearch,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  icon: Icon(Icons.search, size: 18, color: Colors.grey),
                  hintText: "Search by father name...",
                  hintStyle: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),

          // LIST
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : enquiryList.isEmpty
                ? const Center(child: Text("No enquiries found"))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filteredList.length,

                    itemBuilder: (context, index) {
                      final enquiry = filteredList[index];
                      List<String> classes = [];
                      if (enquiry['students'] != null) {
                        for (var student in enquiry['students']) {
                          final childName = student['ChildName'] ?? "N/A";
                          final childClass = student['Class'] ?? "N/A";

                          classes.add("$childName ($childClass)");
                        }
                      }

                      return EnquiryCard(
                        enquiryId: enquiry['id'],
                        index: (index + 1).toString(),
                        father: enquiry['FatherName'] ?? '',
                        mother: enquiry['MotherName'] ?? '',
                        mobile: enquiry['MobileNo'] ?? '',
                        enquiryDate: enquiry['EnquiryDate'] ?? '',
                        followUpDate: enquiry['FollowUpDate'] ?? '',
                        classes: classes,
                        address: enquiry['Address'] ?? '',
                        status: enquiry['Status'] ?? '',
                        remarks: enquiry['Remark'] ?? '',

                        onEdit: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddEnquiryPage(enquiryId: enquiry['id']),
                            ),
                          );

                          if (result == true) {
                            fetchEnquiries();
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class EnquiryCard extends StatelessWidget {
  final String index;
  final String mother;
  final String father;
  final String mobile;
  final String enquiryDate;
  final String followUpDate;
  final List<String> classes;
  final String address;
  final String status;
  final int enquiryId;
  final VoidCallback onEdit;
  final String remarks;

  const EnquiryCard({
    super.key,
    required this.index,
    required this.mother,
    required this.father,
    required this.mobile,
    required this.enquiryDate,
    required this.followUpDate,
    required this.classes,
    required this.address,
    required this.status,
    required this.enquiryId,
    required this.onEdit,
    required this.remarks,
  });
  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case "confirmed":
        statusColor = Colors.green;
        break;
      case "pending":
        statusColor = Colors.orange;
        break;
      case "cancelled":
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔹 Row 1 → Father (Mother) + Edit
          Row(
            children: [
              Expanded(
                child: Text(
                  "$father ($mother)",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xffE8E1F0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 14,
                    color: Color(0xff4A90E2),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          /// 🔹 Row 2 → Contact + Status
          Row(
            children: [
              const Icon(Icons.call, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  "$mobile | Remark: $remarks",
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          /// 🔹 Row 3 → Enquiry + FollowUp
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  "Enquiry: $enquiryDate | Follow: $followUpDate ",
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          /// 🔹 Row 4 → Address
          if (address.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(address, style: const TextStyle(fontSize: 11)),
                ),
              ],
            ),

          const SizedBox(height: 6),

          /// 🔹 Row 5 → Children
          if (classes.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: classes.where((e) => !e.contains("N/A")).map((e) {
                  final formatted = e
                      .replaceAll("(", " - ")
                      .replaceAll(")", "");
                  return Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      formatted,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
