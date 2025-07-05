import 'package:flutter/material.dart';
import 'api_service.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> player; // Thông tin người chơi
  final Map<String, dynamic> user;   // Thông tin người dùng hiện tại
  const ChatScreen({super.key, required this.player, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  List<dynamic> messages = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadConversation();
  }

  Future<void> loadConversation() async {
    setState(() => isLoading = true);
    // Lấy ID người dùng từ thông tin người chơi
    final receiverUserId = widget.player['user']['id'];
    messages = await ApiService.getConversation(receiverUserId);
    setState(() => isLoading = false);
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;
    
    // Lấy ID người dùng từ thông tin người chơi
    final receiverUserId = widget.player['user']['id'];
    final sent = await ApiService.sendMessage(
      receiverId: receiverUserId,
      content: text,
    );
    if (sent != null) {
      messageController.clear();
      await loadConversation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    final user = widget.user;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.deepOrange),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: player['user']['avatarUrl'] != null
                  ? NetworkImage(player['user']['avatarUrl'])
                  : null,
              child: player['user']['avatarUrl'] == null
                  ? const Icon(Icons.person, color: Colors.deepOrange)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                player['user']['username'] ?? '',
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF7F7F9),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[messages.length - 1 - index];
                      final isMe = msg['senderId'] == widget.user['id'];
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.deepOrange : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 16),
                            ),
                            boxShadow: [
                              if (!isMe)
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                            ],
                          ),
                          child: Text(
                            msg['content'] ?? '',
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(
              left: 12,
              right: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
              top: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.deepOrange,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: sendMessage,
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