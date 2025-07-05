import 'package:flutter/material.dart';
import 'api_service.dart';
import 'hire_confirmation_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<dynamic> orders = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() { isLoading = true; error = null; });
    try {
      final user = await ApiService.getCurrentUser();
      final userId = user?['id'];
      if (userId == null) {
        setState(() { error = 'Không tìm thấy thông tin người dùng.'; isLoading = false; });
        return;
      }
      final fetchedOrders = await ApiService.getAllUserOrders(userId);
      setState(() {
        orders = fetchedOrders ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Lỗi khi tải đơn hàng: $e';
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
          'Đơn hàng của tôi',
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
              : orders.isEmpty
                  ? const Center(child: Text('Bạn chưa có đơn hàng nào.'))
                  : RefreshIndicator(
                      onRefresh: _fetchOrders,
                      child: ListView.separated(
                        itemCount: orders.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HireConfirmationScreen(
                                      playerName: order['playerName'] ?? '',
                                      playerAvatarUrl: order['playerAvatarUrl'] ?? '',
                                      playerRank: order['playerRank'] ?? '',
                                      game: order['game'] ?? '',
                                      hours: order['hours'] is int ? order['hours'] : int.tryParse(order['hours']?.toString() ?? '') ?? 0,
                                      totalCoin: order['price'] is int ? order['price'] : int.tryParse(order['price']?.toString() ?? '') ?? 0,
                                      orderId: order['id'].toString(),
                                      startTime: order['hireTime'] ?? '',
                                    ),
                                  ),
                                );
                              },
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.event_note, color: Colors.deepOrange, size: 32),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        'Đơn #${order['id']} - ${order['game'] ?? ''}',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${order['price']} xu',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.deepOrange,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text('Người thuê: ${order['renterName']}', style: const TextStyle(fontSize: 14)),
                                                Text('Player: ${order['playerName']}', style: const TextStyle(fontSize: 14)),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        '${order['hireTime']}',
                                                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text('Trạng thái: ${order['statusLabel']}', style: const TextStyle(fontSize: 13, color: Colors.deepOrange)),
                                                Text('Loại đơn: ${order['orderType'] == 'HIRED' ? 'Tôi thuê' : 'Tôi được thuê'}', style: const TextStyle(fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
} 