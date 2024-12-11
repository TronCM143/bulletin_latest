import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';

import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await requestNotificationPermissions(); // Request notification permission
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppDate',
      home: LoginPage(),
    );
  }
}

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  _PermissionsScreenState createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    checkPermissions();
  }

  void checkPermissions() async {
    // Check storage and notification permissions
    var storageStatus = await Permission.storage.status;
    var notificationStatus = await Permission.notification.status;

    // Debugging logs
    print("Storage Permission: ${storageStatus.isGranted}");
    print("Notification Permission: ${notificationStatus.isGranted}");

    if (storageStatus.isGranted && notificationStatus.isGranted) {
      // All permissions granted, proceed to the LoginPage
      setState(() {
        _permissionsGranted = true;
      });
    } else {
      // Request permissions if not granted
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.notification,
      ].request();

      // Check again after requesting
      print("After requesting permissions:");
      print("Storage Permission: ${statuses[Permission.storage]?.isGranted}");
      print(
          "Notification Permission: ${statuses[Permission.notification]?.isGranted}");

      if (statuses[Permission.storage]!.isGranted &&
          statuses[Permission.notification]!.isGranted) {
        // Permissions granted, proceed to the LoginPage
        setState(() {
          _permissionsGranted = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionsGranted) {
      // Navigate to LoginPage when permissions are granted
      return LoginPage();
    }

    // Display a loading indicator while permissions are being checked
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

Future<void> requestNotificationPermissions() async {
  // FirebaseMessaging instance
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permission for notifications
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print("Notifications authorized");
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print("Provisional notifications authorized");
  } else {
    print("Notifications denied");
  }
}
