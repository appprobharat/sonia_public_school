import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:sonia_public_school/admin/notice/add_notice.dart';
import 'package:sonia_public_school/api_service.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class NoticeListPage extends StatefulWidget {
  const NoticeListPage({super.key});

  @override
  State<NoticeListPage> createState() => _NoticeListPageState();
}

class _NoticeListPageState extends State<NoticeListPage> {
  DateTime fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime toDate = DateTime.now();
  TextEditingController searchCtrl = TextEditingController();
  List<Map<String, dynamic>> filteredNoticeList = [];
  List<Map<String, dynamic>> noticeList = [];
  bool isLoading = false;
  bool isDownloading = false;
  String formatDateApi(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }

  // For UI (dd-mm-yyyy)
  String formatDateUi(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year}";
  }

  @override
  void initState() {
    super.initState();
    loadNotices();
  }

  Future<void> loadNotices() async {
    setState(() => isLoading = true);

    try {
      debugPrint("FROM: ${formatDateApi(fromDate)}");
      debugPrint("TO: ${formatDateApi(toDate)}");

      final response = await ApiService.post(
        context,
        "/admin/notice/list",
        body: {"from": formatDateApi(fromDate), "to": formatDateApi(toDate)},
      );

      debugPrint("STATUS: ${response?.statusCode}");
      debugPrint("BODY: ${response?.body}");

      if (response != null && response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        debugPrint("LIST LENGTH: ${data.length}");

        noticeList = List<Map<String, dynamic>>.from(data);
        filteredNoticeList = noticeList;
      }
    } catch (e) {
      debugPrint("Notice error: $e");
    }

    setState(() => isLoading = false);
  }

  void filterNotices(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredNoticeList = noticeList;
      });
    } else {
      setState(() {
        filteredNoticeList = noticeList.where((notice) {
          final title = notice['Title']?.toString().toLowerCase() ?? '';
          return title.contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  Widget _addButtonBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: Row(
        children: [
          Expanded(
            child: _dateBox(
              label: formatDateUi(fromDate),
              title: "From",
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: fromDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (picked != null) {
                  setState(() => fromDate = picked);
                  loadNotices();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _dateBox(
              label: formatDateUi(toDate),
              title: "To",
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: toDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (picked != null) {
                  setState(() => toDate = picked);
                  loadNotices();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateBox({
    required String label,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 14),
            const SizedBox(width: 6),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6ECFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: BackButton(),
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          'Notices',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddNoticePage()),
                );

                if (result == true) {
                  loadNotices();
                }
              },
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            _addButtonBar(context),

            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: searchCtrl,
                      onChanged: filterNotices,
                      style: const TextStyle(fontSize: 12),
                      textAlignVertical: TextAlignVertical.center,
                      decoration: const InputDecoration(
                        isDense: true,
                        prefixIcon: Icon(
                          Icons.search,
                          size: 18,
                          color: Colors.grey,
                        ),
                        hintText: 'Search by title...',
                        hintStyle: TextStyle(fontSize: 12),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              )
            else if (noticeList.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text("No notices found"),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredNoticeList.length,

                itemBuilder: (context, index) {
                  final n = filteredNoticeList[index];

                  return _noticeCard(
                    noticeId: n['id'].toString(),
                    title: n['Title'] ?? "",
                    description: n['Description'] ?? "",
                    by: n['AddedBy'] ?? "",
                    issue: n['Date'] ?? "",
                    valid: n['ValidDate'] ?? "",
                    noticeFor: n['NoticeFor'] ?? "",
                    attachment: n['Attachment'] ?? "",
                  );
                },
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ---------------- notice card ----------------
  Widget _noticeCard({
    required String noticeId,
    required String title,
    required String description,
    required String attachment,
    required String by,
    required String issue,
    required String valid,
    required String noticeFor,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ⭐ Row 1 → Title + Notice by
          _twoIconRow(Icons.campaign, title, Icons.person, by),

          const Divider(height: 14),

          /// ⭐ Row 2 → Issue + Valid
          _twoIconRow(Icons.date_range, issue, Icons.event_available, valid),

          /// ⭐ Row 3 → Description + Notice for
          _twoIconRow(Icons.description, description, Icons.group, noticeFor),

          /// ⭐ Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _iconBtn(Icons.edit, Colors.blue, () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddNoticePage(noticeId: noticeId),
                  ),
                );

                if (result == true) {
                  loadNotices();
                }
              }),

              if (attachment.isNotEmpty) ...[
                const SizedBox(width: 8),
                _iconBtn(Icons.download, Colors.green, () {
                  downloadFile(context, attachment);
                }),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Future<void> downloadFile(BuildContext context, String filePath) async {
    if (isDownloading) return;
    isDownloading = true;

    final fullUrl = filePath.toString();

    try {
      final fileName = fullUrl.split('/').last;
      final dio = Dio();
      late String savePath;

      // ================= ANDROID =================
      if (Platform.isAndroid) {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        savePath = '${downloadsDir.path}/$fileName';

        await dio.download(fullUrl, savePath);

        // ✅ Preview open
        await OpenFile.open(savePath);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("📥 Downloaded & Preview opened")),
          );
        }
      }

      // ================= iOS =================
      if (Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        savePath = '${dir.path}/$fileName';

        await dio.download(fullUrl, savePath);

        // ✅ Preview open
        await OpenFile.open(savePath);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("❌ Download failed")));
      }
    } finally {
      isDownloading = false;
    }
  }

  BoxDecoration _box() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
  );
}

Widget _twoIconRow(IconData i1, String v1, IconData i2, String v2) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(i1, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  v1,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            children: [
              Icon(i2, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  v2,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
