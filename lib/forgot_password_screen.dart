import 'package:flutter/material.dart';
import 'api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  bool isLoading = false;
  bool isNotRobot = false;
  String? emailError;

  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void validateInputs() {
    setState(() {
      emailError = !isValidEmail(emailController.text.trim()) ? 'Email không hợp lệ' : null;
    });
  }

  Future<void> handleSendEmail() async {
    validateInputs();
    if (emailError != null || !isNotRobot) {
      if (!isNotRobot) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng xác nhận bạn không phải robot')),
        );
      }
      return;
    }

    setState(() => isLoading = true);
    try {
      await ApiService.forgotPassword(emailController.text.trim());
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email khôi phục mật khẩu đã được gửi')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xảy ra lỗi: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QUÊN MẬT KHẨU'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.deepOrange,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined),
                  hintText: 'Email khôi phục mật khẩu',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  errorText: emailError,
                ),
              ),
              const SizedBox(height: 32),
              // reCAPTCHA giả lập
              Row(
                children: [
                  Checkbox(
                    value: isNotRobot,
                    onChanged: (v) => setState(() => isNotRobot = v ?? false),
                  ),
                  const Text("I'm not a robot"),
                  const Spacer(),
                  Icon(Icons.security, color: Colors.blue, size: 32),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: isLoading ? null : handleSendEmail,
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Gửi email', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text('Quay lại đăng nhập', style: TextStyle(color: Colors.deepOrange)),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 