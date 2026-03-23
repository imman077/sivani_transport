import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class SystemNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');
    const initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    
    await _plugin.initialize(settings: initializationSettings);

    const androidChannel = AndroidNotificationChannel(
      'sivani_channel', 'Sivani Notifications',
      description: 'Trip and System Updates',
      importance: Importance.max,
    );

    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  static Future<void> showNotification({required String title, required String body}) async {
    final androidDetails = AndroidNotificationDetails(
      'sivani_channel', 'Sivani Notifications',
      importance: Importance.max, priority: Priority.high,
      showWhen: true,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'New Update',
      ),
    );
    final notificationDetails = NotificationDetails(android: androidDetails);
    
    await _plugin.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  static Future<void> requestPermission() async {
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static void initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service',
        channelName: 'Foreground Service Notification',
        channelDescription: 'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<ServiceRequestResult> startForegroundTask() async {
    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.restartService();
    } else {
      return FlutterForegroundTask.startService(
        notificationTitle: 'Sivani Transport',
        notificationText: 'Monitoring trip updates...',
        notificationIcon: null,
        callback: startCallback,
      );
    }
  }

  static Future<ServiceRequestResult> stopForegroundTask() {
    return FlutterForegroundTask.stopService();
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isStopped) async {}
}
