import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';


class PaymentTeacherScreen extends StatefulWidget {
  const PaymentTeacherScreen({super.key});

  @override
  State<PaymentTeacherScreen> createState() => _PaymentTeacherScreenState();
}

class _PaymentTeacherScreenState extends State<PaymentTeacherScreen> {

  List<dynamic> payments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPayments();
  }

  // ---------------- FETCH PAYMENTS ----------------
  Future<void> fetchPayments() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final response = await ApiService.post(
        context,
       "/teacher/payment" , // already full URL
      );

      // 🔐 If token invalid → auto logout already handled
      if (response == null) {
        if (!mounted) return;
        setState(() {
          payments = [];
          isLoading = false;
        });
        return;
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (!mounted) return;
        setState(() {
          payments = decoded is List ? decoded : [];
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          payments = [];
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to load teacher payment records"),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        payments = [];
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Network error: $e")));
    }
  }

  // ---------------- HELPERS ----------------
  Color getBackgroundColor(String? particular) {
    if (particular == "Employee Payment") {
      return Colors.green;
    }
    return Colors.red;
  }

  // ---------------- UI (UNCHANGED) ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Teacher Payments",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : payments.isEmpty
          ? const Center(child: Text("No payments found."))
          : ListView.builder(
              itemCount: payments.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final payment = payments[index];
                final color = getBackgroundColor(payment['Particular']);

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 150,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: RotatedBox(
                          quarterTurns: -1,
                          child: Text(
                            (payment['Particular']
                                    ?.toString()
                                    .split(' ')
                                    .last ??
                                ''),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "📅 ${payment['Date']}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildDetailRow(
                                payment['Particular'] == "Employee Salary"
                                    ? "Amount"
                                    : "Received",
                                payment['Paid'] ?? '0',
                              ),
                              _buildDetailRow(
                                "Pay Mode",
                                payment['PayMode'] ?? '-',
                              ),
                              _buildDetailRow(
                                "Remark",
                                payment['Remark'] ?? '-',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text("$title :")),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
