import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:solar_project/Helper/app_colors.dart';
import 'package:solar_project/Helper/app_provider.dart';
import 'package:solar_project/services/notification_service.dart';
import 'firebase_options.dart';
import 'package:solar_project/Helper/app_navigator.dart';
import 'package:solar_project/Helper/app_feedback.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.init();
  runApp(const KaaryaBookRoot());
}

class KaaryaBookRoot extends StatelessWidget {
  const KaaryaBookRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppProviders(child: KaaryaBookApp());
  }
}

class KaaryaBookApp extends StatelessWidget {
  const KaaryaBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      
      title: "KaaryaBook",
      scaffoldMessengerKey: AppFeedback.scaffoldMessengerKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.lightPurple, // Lighter Logo Purple

          primary: AppColors.lightPurple,

          // keep secondary as-is for now (not part of brand purple replacements)
          secondary: AppColors.primaryLight, // Secondary logo tint
          background: AppColors.purpleBg, // Lighter background tint
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: AppColors.lightPurple, 
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: AppColors.deepPurple),
        ),
        inputDecorationTheme: InputDecorationTheme(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.borderPrimary),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.borderPrimary),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.deepPurple, width: 2), 
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
             backgroundColor: AppColors.deepPurple, 
             foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16), // Rounded matching logo
            ),
            elevation: 0,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
           shadowColor: AppColors.deepPurple.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
         toggleButtonsTheme: const ToggleButtonsThemeData(
           selectedColor: Colors.white,
           fillColor: AppColors.deepPurple, 
         ),
         chipTheme: const ChipThemeData(
           backgroundColor: AppColors.purpleBg,
           secondarySelectedColor: AppColors.deepPurple,
           secondaryLabelStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
           labelStyle: TextStyle(fontWeight: FontWeight.w600),
         ),
      ),
      home: const AppNavigator(),
    );
  }
}




