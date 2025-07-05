import 'dart:async';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'chat_screen.dart';

class MessageListScreen extends StatefulWidget {
  const MessageListScreen({super.key});

  @override
  State<MessageListScreen> createState() => _MessageListScreenState();
}

class _MessageListScreenState extends State<MessageListScreen> {
  List<dynamic> conversations = [];
  bool isLoading = true;
  int currentUserId = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    loadConversations();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      loadConversations();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> loadConversations() async {
    final user = await ApiService.getCurrentUser();
    currentUserId = user?['id'] ?? 0;
    conversations = await ApiService.getConversations();
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tin nhắn')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conv = conversations[index];
                final messages = conv['messages'] as List<dynamic>? ?? [];
                if (messages.isEmpty) return const SizedBox();
                final lastMessage = messages.last;
                final otherUserId = conv['conversationId'];
                final title = conv['otherName'] ?? 'Người dùng #$otherUserId';
                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person, color: Colors.deepOrange),
                  ),
                  title: Text(title),
                  subtitle: Text(lastMessage['content'] ?? ''),
                  trailing: Text(_formatTime(lastMessage['timestamp'])),
                  onTap: () async {
                    final user = { 'id': otherUserId, 'username': title };
                    final player = { 'user': user };
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(player: player, user: user),
                      ),
                    );
                    await loadConversations();
                  },
                );
              },
            ),
    );
  }

  String _formatTime(String? isoTime) {
    if (isoTime == null) return '';
    final dt = DateTime.tryParse(isoTime);
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays > 0) return '${diff.inDays} ngày trước';
    if (diff.inHours > 0) return '${diff.inHours} giờ trước';
    if (diff.inMinutes > 0) return '${diff.inMinutes} phút trước';
    return 'Vừa xong';
  }
} 