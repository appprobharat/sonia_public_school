import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';

class FeeDetailsPage extends StatefulWidget {
  const FeeDetailsPage({super.key});

  @override
  State<FeeDetailsPage> createState() => _FeeDetailsPageState();
}

class _FeeDetailsPageState extends State<FeeDetailsPage> {
  

  final List<String> months = [
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
    'January',
    'February',
    'March',
  ];
  final List<String> monthApiKeys = [
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
    'Jan',
    'Feb',
    'Mar',
  ];

  int selectedMonthIndex = 0;
  bool isLoading = true;
  List<dynamic> feeData = [];

  @override
  void initState() {
    super.initState();
    fetchFeeData(monthApiKeys[selectedMonthIndex]);
  }

  Future<void> fetchFeeData(String monthKey) async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final response = await ApiService.post(
        context,
       "/student/fee",
        body: {'Month': monthKey},
      );

      // Token expired → AuthHelper already logout kara dega
      if (response == null) return;

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        setState(() {
          feeData = decoded is List ? decoded : [];
          isLoading = false;
        });
      } else {
        setState(() {
          feeData = [];
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to fetch fee details")),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        feeData = [];
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Network error")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xfff7f2f9),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text("Fee Details", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          SizedBox(
            height: 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: months.length,
              itemBuilder: (context, index) {
                final isSelected = index == selectedMonthIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(months[index]),
                    selected: isSelected,
                    checkmarkColor: Colors.white,
                    selectedColor: AppColors.primary,

                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                    onSelected: (selected) {
                      setState(() => selectedMonthIndex = index);
                      fetchFeeData(monthApiKeys[index]);
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : feeData.isEmpty
                ? const Center(child: Text("No fee records for this month"))
                : ListView.builder(
                    itemCount: feeData.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, index) {
                      final record = feeData[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.credit_card,
                            color: AppColors.primary,
                          ),
                          title: Text("₹${record['Fee']}"),
                          subtitle: Text("Mode: ${record['FeeName']}"),
                          trailing: Text(record['Date']),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
