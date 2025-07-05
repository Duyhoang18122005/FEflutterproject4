import 'package:flutter/material.dart';
import 'api_service.dart';

class DepositHistoryScreen extends StatefulWidget {
  const DepositHistoryScreen({super.key});

  @override
  State<DepositHistoryScreen> createState() => _DepositHistoryScreenState();
}

class _DepositHistoryScreenState extends State<DepositHistoryScreen> {
  List<dynamic> history = [];
  String search = '';
  String selectedStatus = 'Tất cả trạng thái';
  String selectedTime = 'Tất cả thời gian';

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final data = await ApiService.fetchTopupHistory();
    setState(() {
      history = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử nạp xu'),
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
                        items: [
                          'Tất cả thời gian',
                        ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
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
                        items: [
                          'Tất cả trạng thái',
                          'Thành công',
                          'Đang xử lý',
                          'Thất bại',
                        ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() => selectedStatus = v!),
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
      final matchStatus = selectedStatus == 'Tất cả trạng thái' ||
          (selectedStatus == 'Thành công' && item['statusText'] == 'Thành công') ||
          (selectedStatus == 'Đang xử lý' && item['statusText'] == 'Đang xử lý') ||
          (selectedStatus == 'Thất bại' && item['statusText'] == 'Thất bại');
      return matchSearch && matchStatus;
    }).toList();
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    Color statusColor = Colors.grey;
    String statusText = item['statusText'] ?? '';
    if (item['statusColor'] != null) {
      try {
        statusColor = Color(int.parse(item['statusColor'].replaceFirst('#', '0xff')));
      } catch (_) {}
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
          Text(item['dateTime'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text('${item['coin']} xu', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amber)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('Mã giao dịch: ${item['id']}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const Spacer(),
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
  }
} 