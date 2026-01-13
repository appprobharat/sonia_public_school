import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sonia_public_school/api_service.dart';

class TeacherChatScreen extends StatefulWidget {
  final int studentId;
  final String studentName;
  final String studentPhoto;

  const TeacherChatScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.studentPhoto,
  });

  @override
  State<TeacherChatScreen> createState() => _TeacherChatScreenState();
}

class _TeacherChatScreenState extends State<TeacherChatScreen> {
  List<dynamic> messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // ====================================================
  // 🔐 SAFE FETCH MESSAGES
  // ====================================================
  Future<void> fetchMessages({bool autoRefresh = false}) async {
    if (!mounted) return;

    try {
      final res = await ApiService.post(
        context,
        "/teacher/messages",
        body: {
          "StudentId": widget.studentId.toString(),
        },
      );

      // AuthHelper already handles 401 + logout
      if (res == null) return;

      debugPrint("📥 CHAT STATUS: ${res.statusCode}");
      debugPrint("📥 CHAT BODY: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (data['status'] == true) {
          final newMessages = data['messages'] ?? [];

          if (!listEquals(messages, newMessages)) {
            if (!mounted) return;
            setState(() {
              messages = List.from(newMessages);
              _isLoading = false;
            });

            if (!autoRefresh) _scrollToBottom();
          }
        }
      }
    } catch (e) {
      debugPrint("🚨 FETCH CHAT ERROR: $e");

      if (!autoRefresh && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ====================================================
  // 📤 SEND MESSAGE (SAFE)
  // ====================================================
  Future<void> sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending || !mounted) return;

    setState(() => _isSending = true);

    try {
      final res = await ApiService.post(
        context,
        "/teacher/message/send",
        body: {
          "receiver_id": widget.studentId.toString(),
          "message": text,
        },
      );

      if (res == null) return;

      debugPrint("📤 SEND STATUS: ${res.statusCode}");
      debugPrint("📤 SEND BODY: ${res.body}");

      if (res.statusCode == 200) {
        if (!mounted) return;

        setState(() {
          messages.add({
            "sender_type": "teacher",
            "message": text,
            "created_at": DateTime.now().toIso8601String(),
          });
        });

        _messageController.clear();
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("🚨 SEND MESSAGE ERROR: $e");
    } finally {
      if (!mounted) return;
      setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
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
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: widget.studentPhoto.isNotEmpty
                  ? NetworkImage(widget.studentPhoto)
                  : null,
              backgroundColor: Colors.grey.shade300,
            ),
            const SizedBox(width: 10),
            Text(
              widget.studentName,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => fetchMessages(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary),)
                : messages.isEmpty
                    ? const Center(child: Text("No messages yet"))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(10),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isTeacher =
                              msg['sender_type'] == "teacher";

                          return Align(
                            alignment: isTeacher
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: isTeacher
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isTeacher
                                        ? AppColors.primary.shade400
                                        : Colors.grey.shade300,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(12),
                                      topRight: const Radius.circular(12),
                                      bottomLeft: Radius.circular(
                                        isTeacher ? 12 : 0,
                                      ),
                                      bottomRight: Radius.circular(
                                        isTeacher ? 0 : 12,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    msg['message'] ?? '',
                                    style: TextStyle(
                                      color: isTeacher
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                if (msg['created_at'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 8,
                                      right: 8,
                                      bottom: 4,
                                    ),
                                    child: Text(
                                      DateFormat('dd MMM, hh:mm a').format(
                                        DateTime.parse(
                                          msg['created_at'],
                                        ).toLocal(),
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 22,
              child: _isSending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: sendMessage,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
