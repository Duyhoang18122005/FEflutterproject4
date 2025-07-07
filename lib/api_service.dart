import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config/api_config.dart';
import 'package:logger/logger.dart';

class ApiService {
  static const storage = FlutterSecureStorage();
  static Map<String, dynamic>? _currentUser;
  static const timeout = Duration(seconds: 10);
  static final logger = Logger();

  // Kiểm tra kết nối internet
  static Future<bool> checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  // Lấy headers với token
  static Future<Map<String, String>> get _headersWithToken async {
    final token = await storage.read(key: 'jwt');
    return {
      ...ApiConfig.defaultHeaders,
      'Authorization': 'Bearer $token',
    };
  }

  // Refresh token
  static Future<String?> refreshToken() async {
    try {
      final refreshToken = await storage.read(key: 'refresh_token');
      if (refreshToken == null) return null;

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.refreshToken}'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await storage.write(key: 'jwt', value: data['token']);
        await storage.write(key: 'refresh_token', value: data['refreshToken']);
        return data['token'];
      }
      return null;
    } catch (e) {
      logger.e('Error refreshing token: $e');
      return null;
    }
  }

  // Login
  static Future<String?> login(String username, String password) async {
    if (!await checkConnection()) {
      return 'Không có kết nối internet';
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await storage.write(key: 'jwt', value: data['token']);
        await storage.write(key: 'refresh_token', value: data['refreshToken']);
        await storage.write(key: 'user', value: jsonEncode(data));
        _currentUser = data;
        return null;
      } else {
        final error = jsonDecode(response.body);
        return error['message'] ?? 'Đăng nhập thất bại';
      }
    } catch (e) {
      logger.e('Login error: $e');
      return 'Lỗi kết nối: $e';
    }
  }

  // Register
  static Future<String?> register(Map<String, dynamic> userData) async {
    if (!await checkConnection()) {
      return 'Không có kết nối internet';
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.register}'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode(userData),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return null;
      } else {
        final error = jsonDecode(response.body);
        return error['message'] ?? 'Đăng ký thất bại';
      }
    } catch (e) {
      logger.e('Register error: $e');
      return 'Lỗi kết nối: $e';
    }
  }

  // Logout
  static Future<void> logout() async {
    try {
      final headers = await _headersWithToken;
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.logout}'),
        headers: headers,
      );
    } catch (e) {
      logger.e('Logout error: $e');
    } finally {
      await storage.delete(key: 'jwt');
      await storage.delete(key: 'refresh_token');
      await storage.delete(key: 'user');
      await storage.delete(key: 'device_token_sent');
      _currentUser = null;
    }
  }

  // Get current user info
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    if (!await checkConnection()) {
      return null;
    }

    try {
      final headers = await _headersWithToken;
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.me}'),
        headers: headers,
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = data;
        return data;
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final newToken = await refreshToken();
        if (newToken != null) {
          return getCurrentUser(); // Retry with new token
        }
      }
      return null;
    } catch (e) {
      logger.e('Get current user error: $e');
      return null;
    }
  }

  // Update device token
  static Future<bool> updateDeviceToken(String deviceToken) async {
    if (!await checkConnection()) {
      return false;
    }

    try {
      final headers = await _headersWithToken;
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.deviceToken}'),
        headers: headers,
        body: jsonEncode({'deviceToken': deviceToken}),
      ).timeout(timeout);

      return response.statusCode == 200;
    } catch (e) {
      logger.e('Update device token error: $e');
      return false;
    }
  }

  // Get User Info
  static Future<Map<String, dynamic>?> getUserInfo() async {
    if (!await checkConnection()) {
      return null;
    }

    try {
      logger.d('Bắt đầu lấy thông tin user');
      final headers = await _headersWithToken;
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.userInfo}'),
        headers: headers,
      ).timeout(timeout);

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data != null && data is Map<String, dynamic>) {
          return data;
        }
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final newToken = await refreshToken();
        if (newToken != null) {
          return getUserInfo(); // Retry with new token
        }
      }
      return null;
    } catch (e) {
      logger.e('Lỗi khi đọc thông tin người dùng: $e');
      return null;
    }
  }

  // Send Message
  static Future<Map<String, dynamic>?> sendMessage({
    required int receiverId,
    required String content,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.messages}/send/$receiverId'),
        headers: await _headersWithToken,
        body: jsonEncode({'content': content}),
      ).timeout(timeout);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data != null && data is Map<String, dynamic>) {
          return data;
        }
      }
      return null;
    } catch (e) {
      print('Lỗi gửi tin nhắn: $e');
      return null;
    }
  }

  // Get Conversation
  static Future<List<dynamic>> getConversation(int userId) async {
    try {
      print('==============================');
      print('[Flutter] BẮT ĐẦU LẤY LỊCH SỬ TIN NHẮN');
      print('URL: ${ApiConfig.baseUrl}${ApiConfig.messages}/conversation/$userId');
      final headers = await _headersWithToken;
      print('Headers:');
      headers.forEach((k, v) => print('  $k: $v'));

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.messages}/conversation/$userId'),
        headers: headers,
      ).timeout(timeout);

      print('[Flutter] ĐÃ NHẬN RESPONSE TỪ BACKEND');
      print('Status code: ${response.statusCode}');
      print('Response headers:');
      response.headers.forEach((k, v) => print('  $k: $v'));
      print('Response body: ${response.body}');
      print('==============================');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data != null && data is Map && data.containsKey('messages')) {
          return data['messages'];
        }
        if (data != null && data is List) {
          return data;
        }
      }
      return [];
    } catch (e) {
      print('Lỗi lấy hội thoại: $e');
      return [];
    }
  }

  // Get Conversations
  static Future<List<dynamic>> getConversations() async {
    try {
      print('==============================');
      print('[Flutter] BẮT ĐẦU LẤY DANH SÁCH HỘI THOẠI');
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.messages}/all-conversations');
      final headers = await _headersWithToken;
      print('Headers:');
      headers.forEach((k, v) => print('  $k: $v'));

      final response = await http.get(
        url,
        headers: headers,
      ).timeout(timeout);

      print('[Flutter] ĐÃ NHẬN RESPONSE TỪ BACKEND');
      print('Status code: ${response.statusCode}');
      print('Response headers:');
      response.headers.forEach((k, v) => print('  $k: $v'));
      print('Response body: ${response.body}');
      print('==============================');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data != null && data is List) {
          return data;
        }
      }
      return [];
    } catch (e) {
      print('Lỗi lấy danh sách hội thoại: $e');
      return [];
    }
  }

  static Future<List<dynamic>> fetchGames() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.games}');
      final response = await http.get(url).timeout(timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<String?> registerPlayer(Map<String, dynamic> data) async {
    try {
      final token = await storage.read(key: 'jwt');
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.gamePlayers}');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          return null;
        } else {
          return result['message'] ?? 'Đăng ký player thất bại';
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          return error['message'] ?? 'Đăng ký player thất bại';
        } catch (e) {
          return response.body.isNotEmpty ? response.body : 'Đăng ký player thất bại';
        }
      }
    } catch (e) {
      return 'Đã xảy ra lỗi: ${e.toString()}';
    }
  }

  static Future<List<dynamic>> fetchAllPlayers() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.gamePlayers}');
      final response = await http.get(url).timeout(timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] as List;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> fetchPlayerById(int id) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.gamePlayers}/$id');
      final response = await http.get(url).timeout(timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Nạp tiền (topup)
  static Future<String?> topUp(int coin) async {
    try {
      final token = await storage.read(key: 'jwt');
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.payments}/topup');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'coin': coin,
        }),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return null; // Thành công
      } else {
        final error = jsonDecode(response.body);
        return error['message'] ?? 'Nạp coin thất bại';
      }
    } catch (e) {
      print('Lỗi khi nạp coin: ${e.toString()}');
      return 'Đã xảy ra lỗi: ${e.toString()}';
    }
  }

  // Nạp tiền qua QR/bank (deposit)
  static Future<Map<String, dynamic>?> deposit(double amount, String method) async {
    final token = await storage.read(key: 'jwt');
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.payments}/deposit');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'amount': amount,
        'method': method,
      }),
    ).timeout(timeout);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return jsonDecode(response.body);
    }
  }

  // Lấy số dư ví
  static Future<int?> fetchWalletBalance() async {
    try {
      final token = await storage.read(key: 'jwt');
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.payments}/wallet-balance');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(timeout);

      if (response.statusCode == 200) {
        // BE trả về số xu (long)
        return int.tryParse(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> processPayment(String transactionId) async {
    try {
      final token = await storage.read(key: 'jwt');
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.payments}/process');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'transactionId': transactionId,
        }),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Xử lý thanh toán thất bại');
      }
    } catch (e) {
      print('Lỗi khi xử lý thanh toán: ${e.toString()}');
      return null;
    }
  }

  static Future<int> fetchFollowerCount(int playerId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.players}/$playerId/followers/count');
    final response = await http.get(url).timeout(timeout);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['followerCount'] ?? 0;
    }
    return 0;
  }

  static Future<int> fetchHireHours(int playerId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.players}/$playerId/hire-hours');
    final response = await http.get(url).timeout(timeout);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['totalHireHours'] ?? 0;
    }
    return 0;
  }

  static Future<bool> followPlayer(int playerId) async {
    final token = await storage.read(key: 'jwt');
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.players}/$playerId/follow');
    print('[LOG] Gửi POST follow tới $url với token: ${token != null}');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(timeout);
    print('[LOG] Response followPlayer: statusCode=${response.statusCode}, body=${response.body}');
    return response.statusCode == 200;
  }

  static Future<bool> checkFollowing(int playerId) async {
    final token = await storage.read(key: 'jwt');
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.players}/$playerId/is-following');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(timeout);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['isFollowing'] == true;
    }
    return false;
  }

  static Future<bool> unfollowPlayer(int playerId) async {
    final token = await storage.read(key: 'jwt');
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.players}/$playerId/unfollow');
    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(timeout);
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>?> getUserById(int userId) async {
    if (!await checkConnection()) {
      return null;
    }

    try {
      final headers = await _headersWithToken;
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users/$userId'),
        headers: headers,
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      logger.e('Get user by ID error: $e');
      return null;
    }
  }

  static Future<String?> updateUserProfile(Map<String, dynamic> data) async {
    try {
      final token = await storage.read(key: 'jwt');
      // Map gender về đúng format BE
      String? gender = data['gender'];
      if (gender == 'Nam') gender = 'MALE';
      if (gender == 'Nữ') gender = 'FEMALE';
      if (gender == 'Khác') gender = 'OTHER';
      final body = {
        'fullName': data['fullName'],
        'dateOfBirth': data['dateOfBirth'],
        'phoneNumber': data['phoneNumber'],
        'address': data['address'],
        'bio': data['bio'],
        'gender': gender,
      };
      final url = Uri.parse('${ApiConfig.baseUrl}/api/auth/update');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(timeout);
      if (response.statusCode == 200) {
        return null;
      } else {
        final error = jsonDecode(response.body);
        return error['message'] ?? 'Cập nhật thất bại';
      }
    } catch (e) {
      return 'Lỗi: [31m${e.toString()}[0m';
    }
  }

  static Future<List<dynamic>> fetchPlayersByUser(int userId) async {
    try {
      final token = await storage.read(key: 'jwt');
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.gamePlayers}/user/$userId');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('data')) {
          return data['data'] as List;
        }
        if (data is List) {
          return data;
        }
        return [];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<String?> updatePlayer(int playerId, Map<String, dynamic> data) async {
    try {
      final token = await storage.read(key: 'jwt');
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.gamePlayers}/$playerId');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          return null;
        } else {
          return result['message'] ?? 'Cập nhật player thất bại';
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          return error['message'] ?? 'Cập nhật player thất bại';
        } catch (e) {
          return response.body.isNotEmpty ? response.body : 'Cập nhật player thất bại';
        }
      }
    } catch (e) {
      return 'Đã xảy ra lỗi: ${e.toString()}';
    }
  }

  static Future<List<dynamic>> fetchTopupHistory() async {
    try {
      final token = await storage.read(key: 'jwt');
      final url = Uri.parse('${ApiConfig.baseUrl}/api/payments/topup-history');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(timeout);
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
      }
      return [];
    } catch (e) {
      print('Lỗi lấy lịch sử nạp xu: $e');
      return [];
    }
  }

  // Thuê player (API mới)
  static Future<Map<String, dynamic>?> hirePlayer({
    required int playerId,
    required int coin,
    required DateTime startTime,
    required DateTime endTime,
    int? hours,
    int? userId, // nếu cần truyền userId, lấy từ token hoặc truyền vào
    String? specialRequest,
  }) async {
    final token = await storage.read(key: 'jwt');
    final url = Uri.parse('${ApiConfig.baseUrl}/api/game-players/$playerId/hire');
    final now = DateTime.now();
    final body = {
      'userId': userId, // cần truyền userId, nếu không có thì cần lấy từ token
      'hours': hours ?? ((endTime.difference(startTime).inMinutes / 60).round()),
      'coin': coin,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      if (specialRequest != null && specialRequest.isNotEmpty) 'specialRequest': specialRequest,
    };
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    ).timeout(timeout);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'message': 'Thuê player thất bại'};
      }
    }
  }

  static Future<List<dynamic>> fetchPlayersHiredByMe() async {
    final token = await storage.read(key: 'jwt');
    final url = Uri.parse('${ApiConfig.baseUrl}/api/game-players/hired-by-me');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(timeout);
    if (response.statusCode == 200 && response.body.isNotEmpty) {
      final data = jsonDecode(response.body);
      if (data is Map && data['data'] is List) {
        return data['data'];
      }
    }
    return [];
  }

  // Lấy tất cả thông báo (trừ tin nhắn sẽ lọc ở UI)
  static Future<List<dynamic>> fetchNotifications() async {
    final token = await storage.read(key: 'jwt');
    final url = Uri.parse('${ApiConfig.baseUrl}/api/notifications/user');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(timeout);
    if (response.statusCode == 200 && response.body.isNotEmpty) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
      if (data is Map && data['data'] is List) return data['data'];
    }
    return [];
  }

  // Lấy chi tiết đơn thuê theo orderId
  static Future<Map<String, dynamic>?> fetchOrderDetail(String orderId) async {
    final token = await storage.read(key: 'jwt');
    final url = Uri.parse('${ApiConfig.baseUrl}/api/orders/detail/$orderId');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(timeout);
    if (response.statusCode == 200 && response.body.isNotEmpty) {
      final data = jsonDecode(response.body);
      if (data != null) {
        return data;
      }
    }
    return null;
  }

  static Future<bool> confirmHire(String orderId) async {
    final token = await storage.read(key: 'jwt');
    final url = Uri.parse('${ApiConfig.baseUrl}/api/game-players/order/$orderId/confirm');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(timeout);
    return response.statusCode == 200;
  }

  static Future<bool> rejectHire(String orderId) async {
    final token = await storage.read(key: 'jwt');
    final url = Uri.parse('${ApiConfig.baseUrl}/api/game-players/order/$orderId/cancel');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(timeout);
    return response.statusCode == 200;
  }

  static Future<bool> deleteNotification(int notificationId) async {
    final token = await storage.read(key: 'jwt');
    final url = Uri.parse('${ApiConfig.baseUrl}/api/notifications/$notificationId');
    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(timeout);
    return response.statusCode == 200;
  }

  static Future<bool> forgotPassword(String email) async {
    final url = Uri.parse('http://10.0.2.2:8080/api/auth/forgot-password');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      // Nếu backend trả về message lỗi dạng Map
      try {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? body['message'] ?? response.body);
      } catch (_) {
        throw Exception(response.body);
      }
    }
  }

  static Future<String?> changePassword(String oldPassword, String newPassword) async {
    if (!await checkConnection()) {
      return 'Không có kết nối internet';
    }
    try {
      final headers = await _headersWithToken;
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/change-password'),
        headers: headers,
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      ).timeout(timeout);
      if (response.statusCode == 200) {
        return null;
      } else {
        final error = jsonDecode(response.body);
        return error['message'] ?? error['error'] ?? 'Đổi mật khẩu thất bại';
      }
    } catch (e) {
      logger.e('Change password error: $e');
      return 'Lỗi kết nối: $e';
    }
  }

  static Future<Map<String, dynamic>?> createVnPayPayment({
    required int amount,
    required String orderInfo,
    required int userId,
  }) async {
    final token = await storage.read(key: 'jwt');
    final url = Uri.parse('${ApiConfig.baseUrl}/api/payments/vnpay/create');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'amount': amount.toString(),
        'orderInfo': orderInfo,
        'userId': userId.toString(),
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  static Future<List<dynamic>?> getAllUserOrders(int userId) async {
    final token = await storage.read(key: 'jwt');
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/api/orders/user-all/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List;
    }
    return null;
  }

  static Future<bool> submitOrderReview({
    required String orderId,
    required int rating,
    String? comment,
  }) async {
    final token = await storage.read(key: 'jwt');
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8080/api/order-reviews/$orderId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'rating': rating,
        'comment': comment ?? '',
      }),
    );
    return response.statusCode == 200;
  }

  static Future<List<dynamic>?> getUserGivenReviews() async {
    final token = await storage.read(key: 'jwt');
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/api/order-reviews/user/given-reviews'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['reviews'] as List?;
    }
    return null;
  }

  static Future<bool> deleteOrderReview(String orderId) async {
    final token = await storage.read(key: 'jwt');
    final response = await http.delete(
      Uri.parse('http://10.0.2.2:8080/api/order-reviews/$orderId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return response.statusCode == 200;
  }

  static Future<List<dynamic>?> getPlayerReviews(String playerId) async {
    final token = await storage.read(key: 'jwt');
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/api/order-reviews/player/$playerId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['reviews'] as List?;
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getPlayerRatingSummary(String playerId) async {
    final token = await storage.read(key: 'jwt');
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/api/order-reviews/rating-summary/player/$playerId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] as Map<String, dynamic>?;
    }
    return null;
  }

  static Future<List<String>> getPlayerImages(String playerId) async {
    final token = await storage.read(key: 'jwt');
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/api/game-players/$playerId/images'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final images = data['data']['images'] as List?;
      if (images != null) {
        return images.map((img) => img['imageUrl'] as String).toList();
      }
    }
    return [];
  }

  static Future<Map<String, dynamic>?> getOrderReview(String orderId) async {
    final token = await storage.read(key: 'jwt');
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/api/order-reviews/$orderId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }
}