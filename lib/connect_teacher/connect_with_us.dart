import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sonia_public_school/api_service.dart';

class ConnectWithUsPage extends StatefulWidget {
  final int teacherId;
  final String teacherName;
  final String teacherPhoto;

  const ConnectWithUsPage({
    super.key,
    required this.teacherId,
    required this.teacherName,
    required this.teacherPhoto,
  });

  ConnectWithUsPage.normal()
    : teacherId = 0,
      teacherName = "",
      teacherPhoto = "";

  @override
  State<ConnectWithUsPage> createState() => _ConnectWithUsPageState();
}

class _ConnectWithUsPageState extends State<ConnectWithUsPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool isSending = false;
  bool isLoading = true;

  int teacherId = 0;
  String teacherName = "";
  String teacherPhoto = "";

  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    teacherId = widget.teacherId;
    teacherName = widget.teacherName;
    teacherPhoto = widget.teacherPhoto;
    fetchMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ====================================================
  // 🔐 FETCH MESSAGES (SAFE)
  // ====================================================
  Future<void> fetchMessages({bool autoRefresh = false}) async {
    if (!mounted) return;

    try {
      final res = await ApiService.post(
        context,
        "/student/messages",
      );

      if (res == null) return;

      debugPrint("📥 CHAT STATUS: ${res.statusCode}");
      debugPrint("📥 CHAT BODY: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (data['status'] == true) {
          teacherId = data['id'] ?? teacherId;
          teacherName = data['name'] ?? teacherName;
          teacherPhoto = data['photo'] ?? teacherPhoto;

          final List<Map<String, dynamic>> newMessages =
              List<Map<String, dynamic>>.from(
                (data['messages'] ?? []).map((m) {
                  return {
                    "sender": m['sender_type'] == 'student'
                        ? 'user'
                        : 'teacher',
                    "text": m['message'] ?? '',
                    "time": m['created_at'],
                  };
                }),
              );

          if (!mounted) return;
          setState(() {
            messages = newMessages;
          });

          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint("🚨 FETCH MESSAGE ERROR: $e");
    } finally {
      if (!mounted) return;
      if (!autoRefresh) setState(() => isLoading = false);
    }
  }

  // ====================================================
  // 🚀 SEND MESSAGE (SAFE)
  // ====================================================
  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || teacherId == 0) return;

    if (!mounted) return;
    setState(() => isSending = true);

    try {
      final res = await ApiService.post(
        context,
        "/student/message/send",
        body: {"receiver_id": teacherId.toString(), "message": text},
      );

      if (res == null) return;

      debugPrint("📤 SEND STATUS: ${res.statusCode}");
      debugPrint("📤 SEND BODY: ${res.body}");

      if (res.statusCode == 200) {
        _messageController.clear();
        fetchMessages(autoRefresh: true);
      }
    } catch (e) {
      debugPrint("🚨 SEND MESSAGE ERROR: $e");
    } finally {
      if (!mounted) return;
      setState(() => isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ====================================================
  // 🧱 UI (UNCHANGED)
  // ====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: teacherPhoto.isNotEmpty
                  ? NetworkImage(teacherPhoto)
                  : const AssetImage("assets/images/default_avatar.png")
                        as ImageProvider,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacherName.isNotEmpty ? teacherName : "Teacher Name",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  "Class Teacher",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => fetchMessages(),
          ),
        ],
        backgroundColor: AppColors.primary,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary),)
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isUser = msg['sender'] == 'user';

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isUser
                                ? AppColors.primary.shade100
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: isUser
                                  ? const Radius.circular(12)
                                  : Radius.zero,
                              bottomRight: isUser
                                  ? Radius.zero
                                  : const Radius.circular(12),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: isUser
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(msg['text']),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat(
                                  'dd MMM, hh:mm a',
                                ).format(DateTime.parse(msg['time']).toLocal()),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // INPUT
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: "Type your message...",
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: isSending ? null : _handleSendMessage,
                        child: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: isSending
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                )
                              : const Icon(Icons.send, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
