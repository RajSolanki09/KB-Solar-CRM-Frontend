import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:solar_project/Helper/app_provider.dart';
import 'package:solar_project/services/notification_service.dart';
import 'firebase_options.dart';
import 'package:solar_project/Helper/app_navigator.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/core/app_colors.dart';

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
      title: 'KaaryaBook Solar CRM',
      scaffoldMessengerKey: AppFeedback.scaffoldMessengerKey,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.solar,
          background: AppColors.background,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.solar,
          foregroundColor: AppColors.surface,
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppColors.primary),
            borderRadius: BorderRadius.circular(10),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppColors.divider),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const AppNavigator(),
    );
  }
}
