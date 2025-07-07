import 'package:flutter/material.dart';
import 'api_service.dart';
import 'dart:async';
import 'utils/notification_helper.dart';
import 'rate_player_screen.dart';

class HireConfirmationScreen extends StatefulWidget {
  final String playerName;
  final String playerAvatarUrl;
  final String playerRank;
  final String game;
  final int hours;
  final int totalCoin;
  final String orderId;
  final String startTime;

  const HireConfirmationScreen({
    Key? key,
    required this.playerName,
    required this.playerAvatarUrl,
    required this.playerRank,
    required this.game,
    required this.hours,
    required this.totalCoin,
    required this.orderId,
    required this.startTime,
  }) : super(key: key);

  @override
  State<HireConfirmationScreen> createState() => _HireConfirmationScreenState();
}

class _HireConfirmationScreenState extends State<HireConfirmationScreen> {
  String? orderStatus;
  bool isLoading = true;
  Map<String, dynamic>? orderDetail;
  Timer? _countdownTimer;
  Duration? remainingTime;
  Map<String, dynamic>? currentUser;
  bool isPlayer = false;
  bool? isOrderReviewed;

  @override
  void initState() {
    super.initState();
    fetchOrder();
    ApiService.getCurrentUser().then((user) {
      setState(() {
        currentUser = user;
      });
    });
    _checkOrderReview();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchOrder() async {
    setState(() { isLoading = true; });
    final detail = await ApiService.fetchOrderDetail(widget.orderId);
    setState(() {
      orderDetail = detail;
      orderStatus = detail != null ? detail['status']?.toString() : null;
      isLoading = false;
    });
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    if (orderStatus != null && orderStatus != 'PENDING') return;
    final startTimeStr = orderDetail?['startTime']?.toString() ?? widget.startTime;
    DateTime? startTime;
    try {
      startTime = DateTime.parse(startTimeStr);
    } catch (_) {
      return;
    }
    void updateTime() {
      final now = DateTime.now();
      final diff = startTime!.difference(now);
      setState(() {
        remainingTime = diff.isNegative ? Duration.zero : diff;
      });
      if (diff.inSeconds <= 0 && (orderStatus == null || orderStatus == 'PENDING')) {
        _countdownTimer?.cancel();
        _rejectOrder();
      }
    }
    updateTime();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => updateTime());
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '--:--';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    } else {
      return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _confirmOrder() async {
    try {
      final success = await ApiService.confirmHire(widget.orderId);
      if (success == true) {
        setState(() { orderStatus = 'CONFIRMED'; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xác nhận đơn thành công!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xác nhận đơn thất bại!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  Future<void> _rejectOrder() async {
    try {
      final success = await ApiService.rejectHire(widget.orderId);
      if (success == true) {
        setState(() { orderStatus = 'REJECTED'; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã từ chối đơn thành công!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Từ chối đơn thất bại!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  Future<void> _checkOrderReview() async {
    try {
      final reviewResp = await ApiService.getOrderReview(widget.orderId);
      setState(() {
        isOrderReviewed = reviewResp != null && reviewResp['data'] != null;
      });
    } catch (e) {
      setState(() {
        isOrderReviewed = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy dữ liệu từ widget hoặc orderDetail nếu có
    final playerName = orderDetail?['playerName'] ?? widget.playerName;
    final playerAvatarUrl = orderDetail?['playerAvatarUrl'] ?? widget.playerAvatarUrl;
    final playerRank = orderDetail?['playerRank'] ?? widget.playerRank;
    final game = orderDetail?['game'] ?? widget.game;
    final hours = orderDetail?['hours'] ?? widget.hours;
    final totalCoin = orderDetail?['totalCoin'] ?? widget.totalCoin;
    final startTime = orderDetail?['startTime']?.toString() ?? widget.startTime;
    final specialRequest = orderDetail?['specialRequest'] ?? orderDetail?['description'] ?? 'Không có';
    final servicePrice = totalCoin;
    final hireTime = '';
    final hireDate = startTime.length >= 10 ? startTime.substring(0, 10) : startTime;
    final confirmTime = '26:50';

    // Xác định vai trò
    final userId = currentUser != null ? currentUser!['id']?.toString() : null;
    final orderUserId = orderDetail?['hirerId']?.toString();
    final orderPlayerId = orderDetail?['playerId']?.toString();
    final isCurrentPlayer = userId != null && (userId == orderPlayerId);
    final isCurrentUser = userId != null && (userId == orderUserId);

    // Format lại thời gian đặt đơn
    String formattedOrderTime = '';
    try {
      final dt = DateTime.parse(startTime);
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year.toString();
      formattedOrderTime = '$hour:$minute - $day/$month/$year';
    } catch (_) {
      formattedOrderTime = startTime;
    }

    // Format lại thời gian thuê
    String hireTimeDisplay = '';
    String hireDateDisplay = '';
    try {
      final dt = DateTime.parse(startTime);
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      hireTimeDisplay = '$hour:$minute';
      hireDateDisplay = '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      hireTimeDisplay = hireTime;
      hireDateDisplay = hireDate;
    }

    // Lấy tên hiển thị đúng vai trò
    String displayName = playerName;
    if (isCurrentPlayer) {
      displayName = orderDetail?['hirerName'] ?? '';
    } else if (isCurrentUser) {
      displayName = orderDetail?['playerName'] ?? '';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: Text(isCurrentPlayer ? 'Xác nhận đơn hàng' : 'Chi tiết đơn hàng'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.deepOrange),
        titleTextStyle: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 24),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Thông tin người chơi (luôn là player)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepOrange.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundImage: (playerAvatarUrl.isNotEmpty && playerAvatarUrl != 'null')
                              ? NetworkImage(playerAvatarUrl)
                              : null,
                          child: (playerAvatarUrl.isEmpty || playerAvatarUrl == 'null')
                              ? const Icon(Icons.person, size: 36, color: Colors.deepOrange)
                              : null,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.deepOrange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text('Đã xác thực', style: TextStyle(fontSize: 12, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('Đặt lúc: $formattedOrderTime', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Chi tiết đơn hàng
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepOrange.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.deepOrange.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.access_time, color: Colors.deepOrange),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Thời gian thuê', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(hireTimeDisplay, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            const Spacer(),
                            Text(hireDateDisplay, style: const TextStyle(color: Colors.grey, fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.deepOrange.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.emoji_events, color: Colors.deepOrange),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Loại game', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(game, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            const Text('Rank yêu cầu:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(width: 8),
                            Icon(Icons.verified, color: Colors.deepOrange, size: 20),
                            Text(' $playerRank', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text('Yêu cầu đặc biệt:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            (specialRequest != null && specialRequest.toString().trim().isNotEmpty)
                              ? specialRequest
                              : 'Không có',
                            style: const TextStyle(color: Colors.black87, fontSize: 15),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Giá mỗi giờ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text('${formatXu(servicePrice ~/ hours)} xu', style: const TextStyle(fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tổng thời gian:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text('$hours giờ', style: const TextStyle(fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tổng tiền:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange, fontSize: 17)),
                            Text('${formatXu(servicePrice)} xu', style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 17)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  // Lưu ý/nút xác nhận/từ chối chỉ cho player
                  if (isCurrentPlayer) ...[
                    if (orderStatus == 'PENDING' || orderStatus == null) ...[
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepOrange.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Lưu ý quan trọng', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange, fontSize: 17)),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.timer, color: Colors.red, size: 22),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Bạn cần xác nhận đơn hàng trong vòng ${_formatDuration(remainingTime)} để tránh mất đơn',
                                    style: const TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.w600),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text('Nếu từ chối đơn, vui lòng cung cấp lý do để chúng tôi hỗ trợ khách hàng tốt hơn.', style: TextStyle(fontSize: 14)),
                            const SizedBox(height: 6),
                            const Text('Sau khi xác nhận, bạn sẽ được kết nối với khách hàng qua ứng dụng chat.', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _rejectOrder,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.deepOrange,
                                side: const BorderSide(color: Colors.deepOrange, width: 2),
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('TỪ CHỐI ĐƠN'),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _confirmOrder,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('XÁC NHẬN ĐƠN'),
                            ),
                          ),
                        ],
                      ),
                    ]
                    else if (orderStatus == 'CONFIRMED') ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.check_circle_rounded, color: Colors.blue, size: 48),
                              SizedBox(height: 10),
                              Text(
                                'Đơn đã được xác nhận',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Bạn sẽ được kết nối với người chơi để bắt đầu!',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 15,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]
                    else if (orderStatus == 'REJECTED') ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.cancel_rounded, color: Colors.red, size: 48),
                              SizedBox(height: 10),
                              Text(
                                'Đơn đã bị hủy',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Rất tiếc, đơn hàng này đã bị hủy.',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 15,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]
                  ]
                  // Nếu là user: chỉ hiện trạng thái đơn
                  else ...[
                    const SizedBox(height: 12),
                    if (orderStatus == 'PENDING' || orderStatus == null)
                      Column(
                        children: [
                          Center(
                            child: Column(
                              children: const [
                                Icon(Icons.hourglass_empty, color: Colors.deepOrange, size: 64),
                                SizedBox(height: 12),
                                Text('Đơn đang chờ xác nhận', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 22)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _rejectOrder,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red, width: 2),
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('HỦY ĐƠN'),
                            ),
                          ),
                        ],
                      )
                    else if (orderStatus == 'CONFIRMED')
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.verified_rounded, color: Colors.green, size: 48),
                              SizedBox(height: 10),
                              Text(
                                'Đơn đã hoàn thành',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Cảm ơn bạn đã sử dụng dịch vụ!',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 15,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (orderStatus == 'REJECTED')
                      Center(
                        child: Column(
                          children: const [
                            Icon(Icons.cancel, color: Colors.red, size: 64),
                            SizedBox(height: 12),
                            Text('Đơn đã bị hủy', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 22)),
                          ],
                        ),
                      ),
                  ],
                  if (orderStatus == 'COMPLETED') ...[
                    if (isCurrentUser && isOrderReviewed == false)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: SizedBox(
                          width: 180,
                          height: 48,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.star, color: Colors.white),
                            label: const Text(
                              'Đánh giá',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RatePlayerScreen(
                                    playerName: playerName,
                                    playerId: orderDetail?['playerId']?.toString() ?? '',
                                    playerAvatarUrl: playerAvatarUrl,
                                    playerRank: playerRank,
                                    game: game,
                                  ),
                                ),
                              );
                              if (result == true) {
                                setState(() {
                                  isOrderReviewed = true;
                                });
                              }
                            },
                          ),
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Text('Đơn đã hoàn thành', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
} 