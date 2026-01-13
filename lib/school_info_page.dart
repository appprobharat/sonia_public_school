import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sonia_public_school/api_service.dart';


class SchoolInfoPage extends StatefulWidget {
  @override
  State<SchoolInfoPage> createState() => _SchoolInfoPageState();
}

class _SchoolInfoPageState extends State<SchoolInfoPage> {
  String schoolName = "My School";
  String schoolLogo = "";
  String qrCode = "";
  Map<String, String> schoolDetails = {};
  bool isLoading = true;
  bool isDownloading = false;

  @override
  void initState() {
    super.initState();
    fetchSchoolInfo();
  }

  Future<void> fetchSchoolInfo() async {
    try {
      final response = await ApiService.post(
        context,
        '/school',
      );

      if (response == null) {
        // auto-logout already handled
        if (mounted) setState(() => isLoading = false);
        return;
      }

      if (response.statusCode != 200) {
        debugPrint("❌ School API failed: ${response.statusCode}");
        if (mounted) setState(() => isLoading = false);
        return;
      }

      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        schoolLogo = data['SchoolLogo'] ?? '';
        qrCode = data['QRCode'] ?? '';
        schoolName = data['SchoolName'] ?? 'My School';
        schoolDetails = {
          "Email": data['SchEmail'] ?? '',
          "Website": data['Website'] ?? '',
          "Address": data['Address'] ?? '',
          "Principal": data["PrincipalName"] ?? '',
          "Contact": data["ContactNo"]?.toString() ?? '',
        };
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ School info exception: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// ✅ iOS + Android safe (no permission required)
  Future<void> downloadQrCode() async {
    if (qrCode.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("QR code not available")));
      return;
    }

    try {
      setState(() => isDownloading = true);

      final normalizedUrl = qrCode.startsWith('http')
          ? qrCode
          : 'https://school.edusathi.in/$qrCode';

      final response = await http.get(Uri.parse(normalizedUrl));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw Exception("Download failed");
      }

      final fileName = 'School_QR_${DateTime.now().millisecondsSinceEpoch}.png';

      // ================= ANDROID =================
      if (Platform.isAndroid) {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        final file = File('${downloadsDir.path}/$fileName');

        await file.writeAsBytes(response.bodyBytes, flush: true);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ QR saved to Downloads folder")),
        );
      }

      // ================= iOS =================
      if (Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');

        await file.writeAsBytes(response.bodyBytes, flush: true);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ QR saved in Files app")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to download QR Code")),
      );
    } finally {
      if (mounted) setState(() => isDownloading = false);
    }
  }

  ImageProvider _safeImage(String url) {
    if (url.isEmpty) {
      return const AssetImage("assets/images/logo.png");
    }
    return NetworkImage(
      url.startsWith('http') ? url : 'https://school.edusathi.in/$url',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "School Information",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        leading: const BackButton(color: Colors.white),
      ),
      backgroundColor: AppColors.primary[50],
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary),)
          : SingleChildScrollView(
              child: Card(
                margin: const EdgeInsets.all(16),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Column(
                        children: [
                          Image(
                            image: _safeImage(schoolLogo),
                            height: 100,
                            errorBuilder: (_, __, ___) => Image.asset(
                              "assets/images/logo.png",
                              height: 100,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            schoolName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          border: const Border(
                            left: BorderSide(color: Colors.blue, width: 4),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Text(
                            "School Details",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      ...schoolDetails.entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  e.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(flex: 5, child: Text(e.value)),
                            ],
                          ),
                        ),
                      ),

                      if (qrCode.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Divider(),
                        const Text(
                          "Payment QR Code",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Image(
                          image: _safeImage(qrCode),
                          height: 150,
                          width: 150,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: isDownloading ? null : downloadQrCode,
                          icon: isDownloading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.download, color: Colors.white),
                          label: Text(
                            isDownloading
                                ? "Downloading..."
                                : "Download QR Code",
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
