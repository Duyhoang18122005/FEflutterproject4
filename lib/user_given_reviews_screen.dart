import 'package:flutter/material.dart';
import 'api_service.dart';

class UserGivenReviewsScreen extends StatefulWidget {
  const UserGivenReviewsScreen({Key? key}) : super(key: key);

  @override
  State<UserGivenReviewsScreen> createState() => _UserGivenReviewsScreenState();
}

class _UserGivenReviewsScreenState extends State<UserGivenReviewsScreen> {
  List<dynamic> reviews = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() { isLoading = true; error = null; });
    try {
      final fetched = await ApiService.getUserGivenReviews();
      setState(() {
        reviews = fetched ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Lỗi khi tải đánh giá: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.deepOrange),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Đánh giá đã viết',
          style: TextStyle(
            color: Colors.deepOrange,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.deepOrange),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : reviews.isEmpty
                  ? const Center(child: Text('Bạn chưa viết đánh giá nào.'))
                  : ListView.separated(
                      itemCount: reviews.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final review = reviews[index];
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundImage: (review['playerAvatar'] != null && review['playerAvatar'].toString().isNotEmpty)
                                          ? NetworkImage(review['playerAvatar'])
                                          : null,
                                      backgroundColor: Colors.deepOrange.shade50,
                                      child: (review['playerAvatar'] == null || review['playerAvatar'].toString().isEmpty)
                                          ? const Icon(Icons.person, color: Colors.deepOrange)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(review['playerName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          if (review['gameName'] != null && review['gameName'].toString().isNotEmpty)
                                            Text('Game: ${review['gameName']}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: List.generate(5, (i) => Icon(
                                        Icons.star,
                                        size: 20,
                                        color: i < (review['rating'] ?? 0) ? Colors.amber : Colors.grey[300],
                                      )),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (review['comment'] != null && review['comment'].toString().isNotEmpty)
                                  Text('"${review['comment']}"', style: const TextStyle(fontStyle: FontStyle.italic)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(review['createdAt'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
} 