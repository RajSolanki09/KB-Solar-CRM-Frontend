import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/Auth/auth_cubit.dart';
import 'package:solar_project/Cubits/Auth/auth_state.dart';
import 'package:solar_project/screens/Dashboards/Installation_Dashboard/installation_dashboard.dart';
import 'package:solar_project/screens/Dashboards/Sales_Dashboard/sales_dashboard.dart';
import 'package:solar_project/Cubits/AdminNavigation/admin_nav_cubit.dart';
import 'package:solar_project/screens/Dashboards/Admin_Dashboards/Dashboard/admin_dashboard_screen.dart';
import 'package:solar_project/screens/Dashboards/Service_Dashboard/service_dashboard.dart';
import 'package:solar_project/screens/Login/signin_screen.dart';
import 'package:solar_project/screens/Splash/splash_screen.dart';

class AppNavigator extends StatelessWidget {
  const AppNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppStateCubit, AppState>(
      builder: (context, state) {
        if (state is SplashState) {
          return const SplashScreen();
        }

        if (state is Unauthenticated) {
          return const LoginPage();
        }

        if (state is Authenticated) {
          switch (state.role) {
            case UserRole.admin:
              return BlocProvider(
                create: (context) => AdminNavCubit(),
                child: const AdminDashboardScreen(),
              );
            case UserRole.sales:
              return const SalesDashboard();
            case UserRole.service:
              return const ServiceDashboard();
            case UserRole.installation:
              return const InstallationDashboard();
          }
        }

        return const SizedBox.shrink();
      },
    );
  }
}
