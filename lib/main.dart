import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:solar_project/Helper/app_provider.dart';
import 'package:solar_project/services/notification_service.dart';
import 'firebase_options.dart';
import 'package:solar_project/Helper/app_navigator.dart';
import 'package:solar_project/Helper/app_feedback.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.init();
  runApp(const SolarRoot());
}

class SolarRoot extends StatelessWidget {
  const SolarRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppProviders(child: SolarAdminApp());
  }
}

class SolarAdminApp extends StatelessWidget {
  const SolarAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "KaaryaBook",
      scaffoldMessengerKey: AppFeedback.scaffoldMessengerKey,
      theme: ThemeData(
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
      ),
      home: const AppNavigator(),
    );
  }
}
