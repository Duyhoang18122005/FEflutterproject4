import 'package:flutter/material.dart';
import 'player_profile_screen.dart';
import 'config/api_config.dart';

class MomentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> moment;
  const MomentDetailScreen({Key? key, required this.moment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageUrl = (moment['imageUrls'] as List).isNotEmpty
        ? '${ApiConfig.baseUrl}/moments/moment-images/' + (moment['imageUrls'][0] as String).split('/').last
        : null;
    final userId = moment['playerUserId']?.toString();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết khoảnh khắc', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.deepOrange),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: 260,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        height: 260,
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.broken_image, size: 80, color: Colors.grey)),
                      ),
                    )
                  : Container(
                      height: 260,
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.image, size: 80, color: Colors.grey)),
                    ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (userId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlayerProfileScreen(playerUserId: userId),
                        ),
                      );
                    }
                  },
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.deepOrange.withOpacity(0.1),
                    backgroundImage: userId != null
                        ? NetworkImage('${ApiConfig.baseUrl}/api/auth/avatar/$userId')
                        : null,
                    onBackgroundImageError: (_, __) {},
                    child: userId == null
                        ? const Icon(Icons.person, color: Colors.deepOrange)
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    moment['gamePlayerUsername'] ?? '',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                  ),
                ),
                Text(
                  moment['createdAt'] ?? '',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              moment['content'] ?? '',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.5),
            ),
            const SizedBox(height: 18),
            if (moment['gameName'] != null)
              Row(
                children: [
                  const Icon(Icons.sports_esports, color: Colors.deepOrange, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    moment['gameName'],
                    style: const TextStyle(fontSize: 15, color: Colors.deepOrange, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
} 