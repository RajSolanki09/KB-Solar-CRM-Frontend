import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/ServicesNavigation/service_cubit.dart';
import 'package:solar_project/Cubits/ServicesNavigation/service_state.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_cubit.dart';
import 'package:solar_project/Helper/common_widgets.dart';
import 'package:solar_project/data/Repository/service_repository.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/ui_helper.dart';
import 'package:solar_project/screens/Dashboards/Service_Dashboard/Home/service_dashboard_screen.dart';
import 'package:solar_project/screens/Dashboards/Service_Dashboard/Home/service_sidebar.dart';
import 'package:solar_project/screens/Dashboards/Service_Dashboard/MyServices/myservices_screen.dart';
import 'package:solar_project/screens/Dashboards/Service_Dashboard/History/service_history.dart';
import 'package:solar_project/screens/Dashboards/Service_Dashboard/Profile/services_profile.dart';

class ServiceDashboard extends StatelessWidget {
  const ServiceDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ServiceNavCubit()),
        BlocProvider(
          create: (_) => ServiceLeadCubit(repo: ServiceRepository()),
        ),
      ],
      child: const _DashboardContent(),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context) {
    final compactLayout = !Responsive.isDesktop(context);

    return Scaffold(
      bottomNavigationBar: compactLayout ? const _BottomNavBar() : null,
      body: SafeArea(
        child: compactLayout
            ? const _MobileLayout()
            : Row(
                children: [
                  const ServiceSidebar(),
                  const Expanded(child: _DesktopLayout()),
                ],
              ),
      ),
    );
  }
}

// ── KEY FIX: IndexedStack in both desktop and mobile ─────────────────────────
class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServiceNavCubit, ServiceNavPage>(
      builder: (_, page) => _buildIndexedStack(page),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServiceNavCubit, ServiceNavPage>(
      builder: (_, page) => _buildIndexedStack(page),
    );
  }
}

// Shared IndexedStack — pages built once, never destroyed
Widget _buildIndexedStack(ServiceNavPage page) {
  return IndexedStack(
    index: page.index,
    children: const[
      KeepAlivePage(child: ServiceDashboardPage()),
      KeepAlivePage(child: MyServicesPage()),
      KeepAlivePage(child: ServiceHistoryPage()),
      KeepAlivePage(child: ServiceProfilePage()),
    ],
  );
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServiceNavCubit, ServiceNavPage>(
      builder: (context, page) {
        return NavigationBar(
          indicatorColor: Colors.transparent,
          selectedIndex: page.index,
          onDestinationSelected: (i) => context
              .read<ServiceNavCubit>()
              .changePage(ServiceNavPage.values[i]),
          destinations: [
            NavigationDestination(
              icon: GlowIcon(
                  svgAsset: AppSvgAssets.dashboard,
                  isSelected: page.index == 0),
              selectedIcon:
                  GlowIcon(svgAsset: AppSvgAssets.dashboard, isSelected: true),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: GlowIcon(
                  svgAsset: AppSvgAssets.cog, isSelected: page.index == 1),
              selectedIcon:
                  GlowIcon(svgAsset: AppSvgAssets.cog, isSelected: true),
              label: 'My Services',
            ),
            NavigationDestination(
              icon: GlowIcon(
                  svgAsset: AppSvgAssets.history, isSelected: page.index == 2),
              selectedIcon:
                  GlowIcon(svgAsset: AppSvgAssets.history, isSelected: true),
              label: 'History',
            ),
            NavigationDestination(
              icon: GlowIcon(
                  svgAsset: AppSvgAssets.userRound,
                  isSelected: page.index == 3),
              selectedIcon: GlowIcon(
                  svgAsset: AppSvgAssets.userRound, isSelected: true),
              label: 'Profile',
            ),
          ],
        );
      },
    );
  }
}