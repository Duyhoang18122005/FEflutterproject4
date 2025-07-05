import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'api_service.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final value = newValue.text.replaceAll('.', '');
    final number = int.tryParse(value);
    if (number == null) {
      return oldValue;
    }

    final formatted = number.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class RegisterPlayerScreen extends StatefulWidget {
  const RegisterPlayerScreen({super.key});

  @override
  State<RegisterPlayerScreen> createState() => _RegisterPlayerScreenState();
}

class _RegisterPlayerScreenState extends State<RegisterPlayerScreen> {
  final _formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final rankController = TextEditingController();
  final roleController = TextEditingController();
  final serverController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  // Thông tin user và game
  int? userId;
  int? selectedGameId;
  String? selectedGameName;
  List<dynamic> games = [];
  List<String> availableRoles = [];
  List<String> availableRanks = [];
  bool hasRoles = false;

  final List<String> serverList = [
    'Asia', 'VN', 'KR', 'NA', 'EU',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserAndGames();
  }

  Future<void> _loadUserAndGames() async {
    final user = await ApiService.getCurrentUser();
    final gameList = await ApiService.fetchGames();
    setState(() {
      userId = user?['id'];
      games = gameList;
    });
  }

  String formatPrice(String price) {
    if (price.isEmpty) return '';
    final number = int.tryParse(price.replaceAll('.', ''));
    if (number == null) return price;
    return number.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
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
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Đóng',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> handleRegister() async {
    try {
      setState(() { errorMessage = null; });
      if (!_formKey.currentState!.validate()) {
        showErrorSnackBar('Vui lòng kiểm tra lại thông tin đăng ký');
        return;
      }
      if (userId == null) {
        showErrorSnackBar('Không tìm thấy thông tin người dùng.');
        return;
      }
      if (selectedGameId == null) {
        showErrorSnackBar('Vui lòng chọn game.');
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xác nhận đăng ký'),
          content: const Text('Bạn có chắc chắn muốn đăng ký làm player không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
              ),
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      setState(() => isLoading = true);
      final data = {
        "userId": userId,
        "gameId": selectedGameId,
        "username": usernameController.text.trim(),
        "rank": rankController.text.trim(),
        "role": hasRoles ? roleController.text.trim() : null,
        "server": serverController.text.trim(),
        "pricePerHour": double.tryParse(priceController.text.replaceAll('.', '')) ?? 0,
        "description": descriptionController.text.trim(),
      };
      print('Sending registration data: $data');
      final error = await ApiService.registerPlayer(data);
      if (!mounted) return;
      setState(() => isLoading = false);
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Đăng ký player thành công!'),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(8),
          ),
        );
        Navigator.pop(context);
      } else {
        setState(() { errorMessage = error; });
        showErrorSnackBar(error);
      }
    } catch (e) {
      print('Error during registration: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Đã xảy ra lỗi: ${e.toString()}';
      });
      showErrorSnackBar('Đã xảy ra lỗi không mong muốn. Vui lòng thử lại sau.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepOrange.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new),
                          color: Colors.deepOrange,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Đăng ký làm Player',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ],
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: TextStyle(color: Colors.red[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepOrange.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Game dropdown
                          DropdownButtonFormField<int>(
                            value: selectedGameId,
                            decoration: InputDecoration(
                              labelText: 'Chọn game',
                              prefixIcon: const Icon(Icons.sports_esports),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[200]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.deepOrange),
                              ),
                            ),
                            items: games.map<DropdownMenuItem<int>>((game) {
                              return DropdownMenuItem<int>(
                                value: game['id'],
                                child: Text(game['name'] ?? ''),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedGameId = value;
                                final game = games.firstWhere((g) => g['id'] == value);
                                selectedGameName = game['name'];
                                hasRoles = (game['availableRoles'] as List?)?.isNotEmpty == true;
                                availableRoles = (game['availableRoles'] as List?)?.map((e) => e.toString()).toList() ?? [];
                                availableRanks = (game['availableRanks'] as List?)?.map((e) => e.toString()).toList() ?? [];
                                roleController.clear();
                                rankController.clear();
                                print('Roles for $selectedGameName: $availableRoles');
                              });
                            },
                            validator: (v) => v == null ? 'Vui lòng chọn game' : null,
                          ),
                          const SizedBox(height: 16),
                          // Username field
                          TextFormField(
                            controller: usernameController,
                            maxLength: 50,
                            decoration: InputDecoration(
                              labelText: 'Tên tài khoản',
                              hintText: 'Nhập tên tài khoản của bạn',
                              prefixIcon: const Icon(Icons.person_outline),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[200]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.deepOrange),
                              ),
                            ),
                            validator: (v) {
                              if (v!.isEmpty) return 'Vui lòng nhập tên tài khoản';
                              if (v.length < 3) return 'Tên tài khoản phải có ít nhất 3 ký tự';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Rank dropdown (dynamic)
                          DropdownButtonFormField<String>(
                            value: rankController.text.isEmpty ? null : rankController.text,
                            decoration: InputDecoration(
                              labelText: 'Rank',
                              hintText: 'Chọn rank của bạn',
                              prefixIcon: const Icon(Icons.emoji_events),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[200]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.deepOrange),
                              ),
                            ),
                            items: availableRanks.map((rank) => DropdownMenuItem(
                              value: rank,
                              child: Text(rank),
                            )).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                rankController.text = value;
                              }
                            },
                            validator: (v) => v == null ? 'Vui lòng chọn rank' : null,
                          ),
                          const SizedBox(height: 16),
                          // Role dropdown (dynamic)
                          if (hasRoles)
                            DropdownButtonFormField<String>(
                              value: roleController.text.isEmpty ? null : roleController.text,
                              decoration: InputDecoration(
                                labelText: 'Role',
                                hintText: 'Chọn role bạn chơi',
                                prefixIcon: const Icon(Icons.person),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[200]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.deepOrange),
                                ),
                              ),
                              items: availableRoles.map((role) => DropdownMenuItem(
                                value: role,
                                child: Text(role),
                              )).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  roleController.text = value;
                                }
                              },
                              validator: (v) => v == null ? 'Vui lòng chọn role' : null,
                            ),
                          if (hasRoles) const SizedBox(height: 16),
                          // Server dropdown
                          DropdownButtonFormField<String>(
                            value: serverController.text.isEmpty ? null : serverController.text,
                            decoration: InputDecoration(
                              labelText: 'Server',
                              hintText: 'Chọn server bạn chơi',
                              prefixIcon: const Icon(Icons.language),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[200]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.deepOrange),
                              ),
                            ),
                            items: serverList.map((server) => DropdownMenuItem(
                              value: server,
                              child: Text(server),
                            )).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                serverController.text = value;
                              }
                            },
                            validator: (v) => v == null ? 'Vui lòng chọn server' : null,
                          ),
                          const SizedBox(height: 16),
                          // Price field
                          TextFormField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              ThousandsSeparatorInputFormatter(),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Giá/giờ (xu)',
                              hintText: 'Nhập số xu bạn muốn nhận',
                              prefixIcon: const Icon(Icons.monetization_on, color: Colors.amber),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[200]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.deepOrange),
                              ),
                            ),
                            validator: (v) {
                              if (v!.isEmpty) return 'Vui lòng nhập giá';
                              final price = int.tryParse(v.replaceAll('.', ''));
                              if (price == null) return 'Giá không hợp lệ';
                              if (price < 1000) return 'Giá tối thiểu là 1.000 xu/giờ';
                              if (price > 1000000) return 'Giá tối đa là 1.000.000 xu/giờ';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Description field
                          TextFormField(
                            controller: descriptionController,
                            maxLines: 3,
                            maxLength: 500,
                            decoration: InputDecoration(
                              labelText: 'Mô tả',
                              hintText: 'Mô tả về kỹ năng và kinh nghiệm của bạn',
                              prefixIcon: const Icon(Icons.description),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[200]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.deepOrange),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text(
                          'Đăng ký',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 