import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import '../models/models.dart';
import 'logger_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings();

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
    } catch (e) {
      LoggerService.error('Failed to initialize notifications: $e',
          component: 'NotificationService');
      // Don't throw - notifications are non-critical
    }
  }

  Future<void> showNotification(String title, String body) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'parking_channel',
        'Parking Notifications',
        channelDescription: 'Notifications for parking availability',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails();

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        0,
        title,
        body,
        platformChannelSpecifics,
      );
    } catch (e) {
      LoggerService.error('Failed to show notification: $e',
          component: 'NotificationService');
      // Don't throw - notifications are non-critical
    }
  }

  void checkProximityAndNotify(Position position, List<ParkingZone> zones) {
    const double proximityRadius = 100; // meters

    for (final zone in zones) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        zone.latitude,
        zone.longitude,
      );

      if (distance <= proximityRadius) {
        if (zone.availableSlots == 0) {
          showNotification(
            'Parking Zone Full',
            'The parking zone near you is full.',
          );
        } else if (zone.availableSlots <= 2 && zone.confidenceScore > 0.7) {
          showNotification(
            'Limited Parking Available',
            'Only ${zone.availableSlots} spots left in nearby zone.',
          );
        }
      }
    }
  }
}
