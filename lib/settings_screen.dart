import 'package:flutter/material.dart';
import 'register_player_screen.dart';
import 'login_screen.dart';
import 'api_service.dart';
import 'utils/notification_helper.dart';
import 'update_profile_screen.dart';
import 'update_player_screen.dart';
import 'policy_screen.dart';
import 'change_password_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'orders_screen.dart';
import 'user_given_reviews_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String userId = '';
  bool isLoading = true;
  double? coinBalance;
  bool isLoadingBalance = true;
  bool _showUpdateOptions = false;
  bool isPlayer = false;
  bool _didCheckPlayer = false;
  bool _isCheckingPlayer = false;
  String? playerId;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadWalletBalance();
    _checkIsPlayer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didCheckPlayer) {
      _checkIsPlayer();
      _didCheckPlayer = true;
    }
  }

  @override
  void deactivate() {
    _didCheckPlayer = false;
    super.deactivate();
  }

  Future<void> _loadUserInfo() async {
    final userInfo = await ApiService.getCurrentUser();
    if (mounted) {
      setState(() {
        userId = userInfo?['id']?.toString() ?? '';
        isLoading = false;
      });
    }
  }

  Future<void> _loadWalletBalance() async {
    final balance = await ApiService.fetchWalletBalance();
    if (mounted) {
      setState(() {
        coinBalance = balance?.toDouble();
        isLoadingBalance = false;
      });
    }
  }

  Future<void> _checkIsPlayer() async {
    if (userId.isEmpty) return;
    final players = await ApiService.fetchPlayersByUser(int.tryParse(userId) ?? 0);
    if (mounted) {
      setState(() {
        isPlayer = players.isNotEmpty;
        if (isPlayer) {
          playerId = players[0]['id'].toString();
        } else {
          playerId = null;
        }
      });
    }
  }

  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(8),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> handleLogout() async {
    final shouldLogout = await NotificationHelper.showConfirmDialog(
      context,
      title: 'Xác nhận đăng xuất',
      content: 'Bạn có chắc chắn muốn đăng xuất?',
      confirmText: 'Đăng xuất',
    );

    if (shouldLogout != true) return;

    await ApiService.logout();
    if (!mounted) return;

    NotificationHelper.showSuccess(context, 'Đăng xuất thành công!');
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null || playerId == null) return;
    try {
      final token = await ApiService.storage.read(key: 'jwt');
      final dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';
      final url = 'http://10.0.2.2:8080/api/game-players/$playerId/images';
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(_selectedImage!.path, filename: _selectedImage!.path.split('/').last),
      });
      final response = await dio.post(url, data: formData);
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tải ảnh lên thành công!')),
          );
        }
        setState(() {
          _selectedImage = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${response.statusMessage}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi upload ảnh: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kiểm tra trạng thái player mỗi lần build nếu cần
    if (!_isCheckingPlayer && userId.isNotEmpty && !isPlayer) {
      _isCheckingPlayer = true;
      _checkIsPlayer().then((_) {
        _isCheckingPlayer = false;
      });
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Avatar + nút đổi avatar
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 54,
                    backgroundColor: Colors.deepOrange[100],
                    child: const Text(
                      "🍄",
                      style: TextStyle(fontSize: 54),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.deepOrange,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.add_a_photo, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Thông tin
              Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Thông tin", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black54)),
                    const SizedBox(height: 16),
                    _InfoRow(
                      icon: Icons.monetization_on,
                      label: "Số dư xu",
                      value: isLoadingBalance
                        ? null
                        : (coinBalance != null ? '${coinBalance!.toStringAsFixed(0)} xu' : 'Lỗi'),
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(icon: Icons.balance, label: "Biến động số dư"),
                    const SizedBox(height: 8),
                    isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : _InfoRow(
                          icon: Icons.info, 
                          label: "ID", 
                          value: userId,
                          isLink: true
                        ),
                    const SizedBox(height: 8),
                    _InfoRow(icon: Icons.share, label: "Chia sẻ link"),
                    const SizedBox(height: 24),
                    const Text("Cài đặt", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black54)),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const OrdersScreen()),
                        );
                      },
                      child: _SettingRow(
                        icon: Icons.shopping_bag,
                        label: 'Đơn hàng',
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const UserGivenReviewsScreen()),
                        );
                      },
                      child: _SettingRow(
                        icon: Icons.star,
                        label: 'Đánh giá',
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showUpdateOptions = !_showUpdateOptions;
                        });
                      },
                      child: _SettingRow(
                        icon: Icons.settings,
                        label: 'Cập nhật thông tin',
                      ),
                    ),
                    if (_showUpdateOptions) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 48, top: 4, bottom: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.person, color: Colors.deepOrange, size: 22),
                              title: const Text('Cập nhật thông tin', style: TextStyle(fontSize: 15)),
                              subtitle: const Text('Thay đổi avatar, tên, url...', style: TextStyle(fontSize: 12)),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const UpdateProfileScreen()),
                                );
                              },
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.sports_esports, color: Colors.amber[800], size: 22),
                              title: const Text('Cập nhật player', style: TextStyle(fontSize: 15)),
                              subtitle: const Text('Chỉnh sửa thông tin player, giá thuê...', style: TextStyle(fontSize: 12)),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const UpdatePlayerScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                        );
                      },
                      child: _SettingRow(icon: Icons.lock, label: "Đổi mật khẩu", color: Colors.purple),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PolicyScreen()),
                        );
                      },
                      child: _SettingRow(icon: Icons.policy, label: "Chính sách", color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    if (isPlayer)
                      GestureDetector(
                        onTap: _pickImage,
                        child: _SettingRow(
                          icon: Icons.cloud_upload,
                          label: 'Tải ảnh lên',
                          color: Colors.blue,
                        ),
                      ),
                    if (_selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 48, top: 4, bottom: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.image, color: Colors.blue, size: 20),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_selectedImage!.path.split('/').last)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _uploadImage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange,
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Tải lên', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isPlayer)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: Colors.deepOrange.withOpacity(0.08),
                    leading: const Icon(Icons.sports_esports, color: Colors.deepOrange),
                    title: const Text('Đăng ký làm player', style: TextStyle(fontWeight: FontWeight.w500)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPlayerScreen()),
                      ).then((_) => _checkIsPlayer());
                    },
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: handleLogout,
                  child: const Text('Đăng xuất', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final bool isLink;
  const _InfoRow({
    required this.icon,
    required this.label,
    this.value,
    this.isLink = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.deepOrange[100],
          child: Icon(icon, color: Colors.deepOrange, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              if (value != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    value!,
                    style: TextStyle(
                      fontSize: 15,
                      color: isLink ? Colors.deepOrange : Colors.black87,
                      decoration: isLink ? TextDecoration.underline : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final Color? color;
  const _SettingSwitch({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: (color is MaterialColor)
              ? (color as MaterialColor).shade100
              : (color ?? Colors.blue).withOpacity(0.15),
          child: Icon(icon, color: color ?? Colors.blue, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ),
        Switch(
          value: value,
          onChanged: (v) {},
          activeColor: Colors.deepOrange,
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _SettingRow({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: (color is MaterialColor)
              ? (color as MaterialColor).shade100
              : (color ?? Colors.yellow).withOpacity(0.15),
          child: Icon(icon, color: color ?? Colors.yellow[800], size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
} 