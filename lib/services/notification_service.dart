import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
final FirebaseMessaging _fcm = FirebaseMessaging.instance;

final FlutterLocalNotificationsPlugin _localNotifications =
FlutterLocalNotificationsPlugin();

Future<void> init() async {
// Request permission
await _fcm.requestPermission();

// Setup local notifications
const AndroidInitializationSettings initializationSettingsAndroid =
AndroidInitializationSettings('@mipmap/ic_launcher');

const InitializationSettings initializationSettings =
InitializationSettings(
android: initializationSettingsAndroid,
);

await _localNotifications.initialize(initializationSettings);

// Handle background messages
FirebaseMessaging.onBackgroundMessage(
_firebaseMessagingBackgroundHandler,
);

// Handle foreground messages
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
_showNotification(message);
});
}

static Future<void> _firebaseMessagingBackgroundHandler(
RemoteMessage message,
) async {
debugPrint(
'Handling a background message: ${message.messageId}',
);
}

Future<void> _showNotification(RemoteMessage message) async {
const AndroidNotificationDetails androidPlatformChannelSpecifics =
AndroidNotificationDetails(
'orders_channel',
'Orders Notifications',
importance: Importance.max,
priority: Priority.high,
);

const NotificationDetails platformChannelSpecifics =
NotificationDetails(
android: androidPlatformChannelSpecifics,
);

await _localNotifications.show(
0,
message.notification?.title ?? 'طلب جديد',
message.notification?.body ?? 'لديك تحديث جديد على طلبك',
platformChannelSpecifics,
);
}

Future<String?> getToken() async {
return await _fcm.getToken();
}
}