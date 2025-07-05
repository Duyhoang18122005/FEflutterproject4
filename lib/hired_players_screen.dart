import 'package:flutter/material.dart';
import 'api_service.dart';
import 'hire_confirmation_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> notifications = [];
  List<dynamic> filteredNotifications = [];
  bool isLoading = true;

  // Bộ lọc
  DateTime? selectedDate;
  int? selectedMonth;
  int? selectedYear;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    fetchAllNotifications();
  }

  Future<void> fetchAllNotifications() async {
    final data = await ApiService.fetchNotifications();
    // Lọc bỏ thông báo tin nhắn
    final filtered = data.where((n) => n['type'] != 'message').toList();
    // Sắp xếp theo thời gian mới nhất
    filtered.sort((a, b) {
      final aTime = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(1970);
      final bTime = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(1970);
      return bTime.compareTo(aTime);
    });
    setState(() {
      notifications = filtered;
      isLoading = false;
    });
    applyFilters();
  }

  void applyFilters() {
    List<dynamic> result = List.from(notifications);
    if (selectedDate != null) {
      result = result.where((n) {
        final dt = DateTime.tryParse(n['createdAt'] ?? '');
        return dt != null && dt.year == selectedDate!.year && dt.month == selectedDate!.month && dt.day == selectedDate!.day;
      }).toList();
    }
    if (selectedMonth != null && selectedYear != null) {
      result = result.where((n) {
        final dt = DateTime.tryParse(n['createdAt'] ?? '');
        return dt != null && dt.year == selectedYear && dt.month == selectedMonth;
      }).toList();
    }
    if (selectedTime != null) {
      result = result.where((n) {
        final dt = DateTime.tryParse(n['createdAt'] ?? '');
        return dt != null && dt.hour == selectedTime!.hour && dt.minute == selectedTime!.minute;
      }).toList();
    }
    setState(() {
      filteredNotifications = result;
    });
  }

  void clearFilters() {
    setState(() {
      selectedDate = null;
      selectedMonth = null;
      selectedYear = null;
      selectedTime = null;
    });
    applyFilters();
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'system':
        return Icons.info_outline;
      case 'rent':
        return Icons.sports_esports;
      case 'promotion':
        return Icons.card_giftcard;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.red),
            tooltip: 'Xóa tất cả',
            onPressed: () async {
              for (final n in notifications) {
                await ApiService.deleteNotification(n['id']);
              }
              fetchAllNotifications();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Bộ lọc
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Lọc theo ngày
                        OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(selectedDate == null ? 'Ngày' : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                selectedDate = picked;
                                selectedMonth = null;
                                selectedYear = null;
                              });
                              applyFilters();
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        // Lọc theo tháng
                        OutlinedButton.icon(
                          icon: const Icon(Icons.date_range, size: 18),
                          label: Text(selectedMonth == null ? 'Tháng' : '${selectedMonth!}/${selectedYear ?? DateTime.now().year}'),
                          onPressed: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime(selectedYear ?? now.year, selectedMonth ?? now.month),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              helpText: 'Chọn tháng',
                              initialEntryMode: DatePickerEntryMode.calendarOnly,
                            );
                            if (picked != null) {
                              setState(() {
                                selectedMonth = picked.month;
                                selectedYear = picked.year;
                                selectedDate = null;
                              });
                              applyFilters();
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        // Lọc theo giờ
                        OutlinedButton.icon(
                          icon: const Icon(Icons.access_time, size: 18),
                          label: Text(selectedTime == null ? 'Giờ' : '${selectedTime!.format(context)}'),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: selectedTime ?? TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                selectedTime = picked;
                              });
                              applyFilters();
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        // Xóa filter
                        if (selectedDate != null || selectedMonth != null || selectedTime != null)
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.red),
                            tooltip: 'Xóa bộ lọc',
                            onPressed: clearFilters,
                          ),
                      ],
                    ),
                  ),
                ),
                // Danh sách thông báo
                Expanded(
                  child: filteredNotifications.isEmpty
              ? const Center(child: Text('Không có thông báo nào!'))
              : ListView.builder(
                          itemCount: filteredNotifications.length,
                  itemBuilder: (context, index) {
                            final item = filteredNotifications[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: ListTile(
                        leading: Icon(_iconForType(item['type']), color: Colors.deepOrange),
                        title: Text(item['title'] ?? ''),
                        subtitle: Text(item['message'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(item['createdAt'] != null ? item['createdAt'].toString().substring(0, 16).replaceAll('T', ' ') : ''),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Xóa thông báo',
                              onPressed: () async {
                                await ApiService.deleteNotification(item['id']);
                                fetchAllNotifications();
                              },
                            ),
                          ],
                        ),
                        onTap: () async {
                          // Chỉ xử lý nếu là thông báo thuê mới hoặc đã gửi yêu cầu thuê và có orderId
                          if ((item['type'] == 'rent' || item['type'] == 'rent_request') && item['orderId'] != null) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(child: CircularProgressIndicator()),
                            );
                            final order = await ApiService.fetchOrderDetail(item['orderId'].toString());
                            Navigator.pop(context); // Đóng loading
                            if (order != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HireConfirmationScreen(
                                    playerName: order['playerName'] ?? '',
                                    playerAvatarUrl: order['playerAvatarUrl'] ?? '',
                                    playerRank: order['playerRank'] ?? '',
                                    game: order['game'] ?? '',
                                    hours: order['hours'] ?? 0,
                                    totalCoin: order['totalCoin'] ?? 0,
                                    orderId: order['id'].toString(),
                                    startTime: order['startTime']?.toString() ?? '',
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Không lấy được thông tin đơn thuê!')),
                              );
                            }
                          }
                        },
                      ),
                    );
                  },
                        ),
                ),
              ],
                ),
    );
  }
} 