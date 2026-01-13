import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:sonia_public_school/api_service.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
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
      final response = await ApiService.post(context, "/student/payment");

      // 🔐 token invalid → auto logout already handled
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
          const SnackBar(content: Text("Failed to load payment records")),
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

  // ---------------- DOWNLOAD RECEIPT ----------------
  Future<void> downloadReceipt(dynamic paymentId) async {
    try {
      // 🔹 Step 1: Get receipt URL
      final response = await ApiService.post(
        context,
        "/student/receipt",
        body: {'payment_id': paymentId.toString()},
      );

      if (response == null || response.statusCode != 200) {
        throw Exception("Failed to fetch receipt");
      }

      final data = jsonDecode(response.body);

      if (data['status'] != true || data['url'] == null) {
        throw Exception(data['message'] ?? 'Invalid receipt response');
      }

      final String url = data['url'];
      final String fileName = url.split('/').last;

      final dio = Dio();

      // ================= ANDROID =================
      if (Platform.isAndroid) {
        // ✅ REAL Downloads folder (visible)
        final downloadsDir = Directory('/storage/emulated/0/Download');
        final filePath = '${downloadsDir.path}/$fileName';

        await dio.download(url, filePath);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Receipt saved to Downloads folder")),
        );
      }

      // ================= iOS =================
      if (Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/$fileName';

        await dio.download(url, filePath);

        if (!mounted) return;
        await OpenFile.open(filePath); // Files app
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Receipt download failed")));
    }
  }

  // ---------------- UI (UNCHANGED) ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Payments", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : ListView.builder(
              itemCount: payments.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final payment = payments[index];
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
                        height: 210,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: RotatedBox(
                          quarterTurns: -1,
                          child: Text(
                            'Receipt No.\n${payment['RefNo']}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            Padding(
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
                                    "Total Discount",
                                    "${payment['Discount']}",
                                  ),
                                  _buildDetailRow(
                                    "Penalty",
                                    "${payment['Penalty']}",
                                  ),
                                  _buildDetailRow(
                                    "Total Paid",
                                    "${payment['Paid']}",
                                  ),
                                  _buildDetailRow(
                                    "Total Balance",
                                    "${payment['Balance']}",
                                  ),
                                  _buildDetailRow(
                                    "Payment Mode",
                                    "${payment['PayMode']}",
                                  ),
                                  _buildDetailRow(
                                    "Remark",
                                    payment['Remark'] ?? '-',
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.download,
                                  color: AppColors.primary,
                                ),
                                onPressed: () => downloadReceipt(payment['id']),
                              ),
                            ),
                          ],
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
          SizedBox(width: 140, child: Text("$title :")),
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
