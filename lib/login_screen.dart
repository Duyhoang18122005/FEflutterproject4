import 'package:flutter/material.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'main.dart';
import 'api_service.dart';
import 'utils/notification_helper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  String? usernameError;
  String? passwordError;

  void validateInputs() {
    setState(() {
      usernameError = usernameController.text.trim().isEmpty ? 'Vui lòng nhập tên đăng nhập' : null;
      passwordError = passwordController.text.trim().isEmpty ? 'Vui lòng nhập mật khẩu' : null;
    });
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(8),
        duration: const Duration(seconds: 3),
      ),
    );
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

  Future<void> handleLogin() async {
    validateInputs();
    if (usernameError != null || passwordError != null) return;

    setState(() => isLoading = true);
    try {
      final username = usernameController.text.trim();
      final password = passwordController.text.trim();
      
      // Kiểm tra kết nối internet
      if (!await ApiService.checkConnection()) {
        if (!mounted) return;
        showErrorSnackBar('Không có kết nối internet');
        return;
      }

      final error = await ApiService.login(username, password);
      if (!mounted) return;

      if (error == null) {
        // Sau khi login thành công, lấy thông tin user
        final user = await ApiService.getCurrentUser();
        if (user != null) {
          // Cập nhật device token nếu cần
          String? deviceToken = await FirebaseMessaging.instance.getToken();
          if (deviceToken != null) {
            await ApiService.updateDeviceToken(deviceToken);
          }
          
          showSuccessSnackBar('Đăng nhập thành công!');
          await Future.delayed(const Duration(milliseconds: 500));
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigation()),
          );
        } else {
          showErrorSnackBar('Không lấy được thông tin người dùng!');
        }
      } else {
        showErrorSnackBar(error);
      }
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar('Đã xảy ra lỗi: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                // Logo và tên app
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sports_esports, color: Colors.deepOrange, size: 48),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'PLAYERDUO',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
                        ),
                        Text(
                          'GAME COMMUNITY',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Hình minh họa
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Icon(Icons.computer, size: 100, color: Colors.orange),
                  ),
                ),
                const SizedBox(height: 32),
                // Form đăng nhập
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.person_outline),
                    hintText: 'Tên đăng nhập',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    errorText: usernameError,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.vpn_key_outlined),
                    hintText: 'Mật khẩu',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    errorText: passwordError,
                  ),
                ),
                const SizedBox(height: 24),
                // Nút đăng nhập
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: isLoading ? null : handleLogin,
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Đăng nhập', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 12),
                // Nút đăng nhập Facebook
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1877F3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    icon: const Icon(Icons.facebook, color: Colors.white),
                    onPressed: () {},
                    label: const Text('Đăng nhập bằng Facebook', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),
                // Quên mật khẩu
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                    );
                  },
                  child: const Text(
                    'Quên mật khẩu',
                    style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.w500, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 24),
                // Đăng ký và bỏ qua đăng nhập
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Bạn chưa có tài khoản? '),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: const Text(
                        'Đăng ký ngay!',
                        style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 