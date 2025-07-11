import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'message_list_screen.dart';
import 'hired_players_screen.dart' as hired_players;
import 'hired_players_screen.dart' show NotificationScreen;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'explore_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
  
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;
  
  if (notification != null && android != null) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'Thông báo',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Khởi tạo Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Thiết lập xử lý tin nhắn nền
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Khởi tạo thông báo cục bộ
    const AndroidInitializationSettings initializationSettingsAndroid = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = 
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    
    runApp(const PlayerDuoApp());
  } catch (e) {
    print('Lỗi khi khởi tạo ứng dụng: $e');
  }
}

class PlayerDuoApp extends StatelessWidget {
  const PlayerDuoApp({super.key});

  @override
  Widget build(BuildContext context) {
    setupFCM();
    return MaterialApp(
      title: 'PlayerDuo Clone',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: Colors.black,
          displayColor: Colors.black,
        ).copyWith(
          bodyLarge: const TextStyle(fontWeight: FontWeight.w600),
          bodyMedium: const TextStyle(fontWeight: FontWeight.w600),
          bodySmall: const TextStyle(fontWeight: FontWeight.w600),
          titleLarge: const TextStyle(fontWeight: FontWeight.w700),
          titleMedium: const TextStyle(fontWeight: FontWeight.w700),
          titleSmall: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

void setupFCM() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    
    // Kiểm tra và yêu cầu quyền thông báo
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    print('Trạng thái quyền thông báo: ${settings.authorizationStatus}');
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Lấy token thiết bị
      String? token = await messaging.getToken();
      if (token != null) {
        print('Token thiết bị: $token');
        // Lưu token vào secure storage
        final storage = FlutterSecureStorage();
        await storage.write(key: 'fcm_token', value: token);
      }
      
      // Thiết lập xử lý tin nhắn khi app đang chạy
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Nhận tin nhắn khi ứng dụng đang chạy!');
        print('Dữ liệu tin nhắn: ${message.data}');

        if (message.notification != null) {
          print('Tin nhắn có chứa thông báo: ${message.notification}');
          RemoteNotification notification = message.notification!;
          AndroidNotification? android = message.notification?.android;
          
          if (android != null) {
            flutterLocalNotificationsPlugin.show(
              notification.hashCode,
              notification.title,
              notification.body,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  'high_importance_channel',
                  'Thông báo',
                  importance: Importance.max,
                  priority: Priority.high,
                  icon: '@mipmap/ic_launcher',
                ),
              ),
            );
          }
        }
      });
      
      // Xử lý khi người dùng mở app từ thông báo
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('App được mở từ thông báo: ${message.messageId}');
        // Xử lý navigation nếu cần
      });
    }
  } catch (e) {
    print('Lỗi khi thiết lập FCM: $e');
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = <Widget>[
    HomeScreen(),
    ExploreScreen(), // Thay thế Placeholder bằng trang khám phá
    MessageListScreen(), // Chat tab
    NotificationScreen(), // Notification tab: tất cả thông báo (trừ tin nhắn)
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_esports),
            label: 'PD',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore), // Đổi icon khám phá
            label: 'Khám Phá',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            label: 'Thông báo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepOrange,
        onTap: _onItemTapped,
      ),
    );
  }
}
