// lib/app_providers.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/Auth/auth_cubit.dart';
import 'package:solar_project/Cubits/AdminNavigation/admin_nav_cubit.dart';
import 'package:solar_project/Cubits/SalesNavigation/sales_nav_cubit.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_cubit.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_cubit.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart';
import 'package:solar_project/Cubits/Revenue/revenue_cubit.dart';
import 'package:solar_project/data/Repository/solar_leads_repository.dart';
import 'package:solar_project/data/Repository/revenue_repository.dart';

import 'package:solar_project/core/network/dio_client.dart';

class AppProviders extends StatelessWidget {
  final Widget child;
  const AppProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final dioClient = DioClient();

    return MultiBlocProvider(
      providers: [
        // 🔐 Auth
        BlocProvider<AppStateCubit>(create: (_) => AppStateCubit()),

        // 🧭 Admin Navigation
        BlocProvider<AdminNavCubit>(create: (_) => AdminNavCubit()),

        // 🧭 Sales Navigation
        BlocProvider<SalesNavCubit>(create: (_) => SalesNavCubit()),

        // 🔧 Service Leads
        BlocProvider<ServiceLeadCubit>(create: (_) => ServiceLeadCubit()),

        // ☀️ Solar Leads
        BlocProvider<SolarLeadCubit>(
          create: (_) => SolarLeadCubit(SolarLeadRepository(dioClient)),
        ),

        // 💧 Sprinkler Leads
        BlocProvider<SprinklerLeadCubit>(create: (_) => SprinklerLeadCubit()),

        // 📊 Revenue
        BlocProvider<RevenueCubit>(
          create: (_) => RevenueCubit(RevenueRepository(dioClient)),
        ),
      ],
      child: child,
    );
  }
}
