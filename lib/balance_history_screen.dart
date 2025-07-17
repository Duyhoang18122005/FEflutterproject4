import 'package:flutter/material.dart';
import 'api_service.dart';

class BalanceHistoryScreen extends StatefulWidget {
  const BalanceHistoryScreen({super.key});

  @override
  State<BalanceHistoryScreen> createState() => _BalanceHistoryScreenState();
}
//dsdadad//

class _BalanceHistoryScreenState extends State<BalanceHistoryScreen> {
  List<dynamic> history = [];
  String search = '';
  String selectedType = 'Tất cả loại';
  String selectedStatus = 'Tất cả trạng thái';
  String selectedTime = 'Tất cả thời gian';

  final List<String> typeOptions = [
    'Tất cả loại',
    'Nạp tiền',
    'Rút tiền',
    'Thuê',
    'Donate',
  ];
  final List<String> statusOptions = [
    'Tất cả trạng thái',
    'Thành công',
    'Đang xử lý',
    'Thất bại',
  ];
  final List<String> timeOptions = [
    'Tất cả thời gian',
    '7 ngày gần nhất',
    '30 ngày gần nhất',
  ];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final data = await ApiService.fetchBalanceHistory();
    setState(() {
      history = data;
    });
  }

  Future<int?> _getCurrentUserId() async {
    try {
      final userInfo = await ApiService.getCurrentUser();
      return userInfo?['id'];
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử biến động số dư'),
        backgroundColor: const Color(0xFFF7F7F9),
      ),
      body: Column(
        children: [
          // Filter & Search
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm giao dịch',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onChanged: (v) => setState(() => search = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedTime,
                        items: timeOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() => selectedTime = v!),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedStatus,
                        items: statusOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() => selectedStatus = v!),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedType,
                        items: typeOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() => selectedType = v!),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _filteredHistory().length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = _filteredHistory()[index];
                return _buildHistoryItem(item);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: OutlinedButton.icon(
              onPressed: loadHistory,
              icon: const Icon(Icons.refresh),
              label: const Text('Xem thêm'),
            ),
          ),
        ],
      ),
    );
  }

  List<dynamic> _filteredHistory() {
    return history.where((item) {
      final matchSearch = search.isEmpty ||
          (item['id']?.toString().contains(search) ?? false);
      // Lọc theo trạng thái
      String status = (item['status'] ?? '').toString().toUpperCase();
      bool matchStatus = selectedStatus == 'Tất cả trạng thái' ||
        (selectedStatus == 'Thành công' && status == 'COMPLETED') ||
        (selectedStatus == 'Đang xử lý' && status == 'PENDING') ||
        (selectedStatus == 'Thất bại' && status == 'FAILED');
      // Lọc theo loại giao dịch
      String type = (item['type'] ?? '').toString().toUpperCase();
      bool matchType = selectedType == 'Tất cả loại' ||
        (selectedType == 'Nạp tiền' && type == 'TOPUP') ||
        (selectedType == 'Rút tiền' && type == 'WITHDRAW') ||
        (selectedType == 'Thuê' && type == 'HIRE') ||
        (selectedType == 'Donate' && type == 'DONATE');
      // Lọc theo thời gian
      DateTime? createdAt;
      try {
        createdAt = DateTime.tryParse(item['createdAt'] ?? item['dateTime'] ?? '');
      } catch (_) {}
      bool matchTime = true;
      if (createdAt != null && selectedTime != 'Tất cả thời gian') {
        final now = DateTime.now();
        if (selectedTime == '7 ngày gần nhất') {
          matchTime = createdAt.isAfter(now.subtract(const Duration(days: 7)));
        } else if (selectedTime == '30 ngày gần nhất') {
          matchTime = createdAt.isAfter(now.subtract(const Duration(days: 30)));
        }
      }
      return matchSearch && matchStatus && matchType && matchTime;
    }).toList();
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    return FutureBuilder<int?>(
      future: _getCurrentUserId(),
      builder: (context, snapshot) {
        // Map trạng thái nếu không có statusText
        String status = (item['status'] ?? '').toString().toUpperCase();
        String statusText = item['statusText'] ?? '';
        Color statusColor = Colors.grey;
        if (statusText.isEmpty) {
          switch (status) {
            case 'COMPLETED':
              statusText = 'Thành công';
              statusColor = Colors.green;
              break;
            case 'PENDING':
              statusText = 'Đang xử lý';
              statusColor = Colors.orange;
              break;
            case 'FAILED':
              statusText = 'Thất bại';
              statusColor = Colors.red;
              break;
            default:
              statusText = status;
              statusColor = Colors.grey;
          }
        } else if (item['statusColor'] != null) {
          try {
            statusColor = Color(int.parse(item['statusColor'].replaceFirst('#', '0xff')));
          } catch (_) {}
        }
        // Xác định loại giao dịch để hiển thị dấu và màu
        String type = (item['type'] ?? '').toString().toUpperCase();
        String method = (item['paymentMethod'] ?? '').toString().toUpperCase();
        bool isTopup = type == 'TOPUP';
        bool isWithdraw = type == 'WITHDRAW';
        bool isDonate = type == 'DONATE';
        String coinText = '';
        Color coinColor = Colors.amber;
        if (isTopup) {
          coinText = '+${item['coin']} xu';
          coinColor = Colors.green;
        } else if (isWithdraw) {
          coinText = '-${item['coin']} xu';
          coinColor = Colors.red;
        } else if (isDonate) {
          // Kiểm tra xem user hiện tại là người gửi hay nhận donate
          final currentUserId = snapshot.data;
          final paymentUserId = item['user']?['id'] ?? item['userId'];
          final paymentPlayerId = item['player']?['id'] ?? item['playerId'];
          
          if (currentUserId == paymentUserId) {
            // Người gửi donate: trừ xu, dấu -, màu đỏ
            coinText = '-${item['coin']} xu';
            coinColor = Colors.red;
          } else if (currentUserId == paymentPlayerId) {
            // Người nhận donate: cộng xu, dấu +, màu xanh
            coinText = '+${item['coin']} xu';
            coinColor = Colors.green;
          } else {
            // Trường hợp khác
            coinText = '${item['coin']} xu';
            coinColor = Colors.amber;
          }
        } else {
          coinText = '${item['coin']} xu';
          coinColor = Colors.amber;
        }
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item['createdAt'] ?? item['dateTime'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(coinText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: coinColor)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('Mã giao dịch: ${item['id']}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const Spacer(),
                  if (statusText.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
} 