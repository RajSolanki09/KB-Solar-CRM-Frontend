import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/AdminNavigation/admin_nav_cubit.dart';
import 'package:solar_project/Cubits/AdminNavigation/admin_nav_state.dart';
import 'package:solar_project/Cubits/Revenue/revenue_cubit.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_cubit.dart';
import 'package:solar_project/core/app_colors.dart';
import 'package:solar_project/core/network/dio_client.dart';
import 'package:solar_project/data/Repository/revenue_repository.dart';
import 'package:solar_project/data/Repository/service_repository.dart';
import 'package:solar_project/screens/Dashboards/Admin_Dashboards/Dashboard/admin_sidebar.dart';
import 'package:solar_project/screens/Dashboards/Admin_Dashboards/Dashboard/admin_dashboard_screen.dart';
import 'package:solar_project/screens/Dashboards/Admin_Dashboards/Dashboard/business_report.dart';
import 'package:solar_project/screens/Dashboards/Admin_Dashboards/Profile/admin_profile.dart';
import 'package:solar_project/screens/Dashboards/Admin_Dashboards/Dashboard/service_request.dart';
import 'package:solar_project/screens/Dashboards/Leads/all_leads.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/ui_helper.dart';
import '../../../Helper/common_widgets.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AdminNavCubit()),
        // ✅ Single shared ServiceLeadCubit for ALL admin screens
        // AdminDashboardScreen + ServiceRequestPage now share the same data
        BlocProvider(
          create: (_) => ServiceLeadCubit(repo: ServiceRepository()),
        ),
      ],
      child: Builder(
        builder: (context) {
          final compactLayout = !Responsive.isDesktop(context);
          return WillPopScope(
            onWillPop: () async {
              final navCubit = context.read<AdminNavCubit>();
              final currentPage = navCubit.state;
              if (currentPage != AdminNavPage.dashboard) {
                navCubit.changePage(AdminNavPage.dashboard);
                return false;
              }
              return true;
            },
            child: Scaffold(
              bottomNavigationBar: compactLayout ? _bottomNav() : null,
              body: SafeArea(
                child: compactLayout
                    ? _mobileLayout(context)
                    : Row(
                        children: [
                          const Sidebar(),
                          Expanded(child: _desktopLayout(context)),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _desktopLayout(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color:    AppColors.grayCustom),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Expanded(child: _pageBody())],
      ),
    );
  }

  Widget _pageBody() {
    return BlocBuilder<AdminNavCubit, AdminNavPage>(
      builder: (context, page) {
        switch (page) {
          case AdminNavPage.dashboard:
            return AdminDashboardScreen();
          case AdminNavPage.leads:
            return SalesLeadScreen();
          case AdminNavPage.service:
            return ServiceRequestPage();
          case AdminNavPage.reports:
            return BlocProvider(
              // 👈 yahan replace karo
              create: (_) => RevenueCubit(RevenueRepository(DioClient())),
              child: const AdminRevenueSummaryPage(),
            );
          case AdminNavPage.profile:
            return OwnerProfilePage();
        }
      },
    );
  }

  Widget _mobileLayout(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: BlocBuilder<AdminNavCubit, AdminNavPage>(
            builder: (context, page) {
              switch (page) {
                case AdminNavPage.dashboard:
                  return AdminDashboardScreen();
                case AdminNavPage.leads:
                  return SalesLeadScreen();
                case AdminNavPage.service:
                  return ServiceRequestPage();
                case AdminNavPage.reports:
                  return BlocProvider(
                    create: (_) => RevenueCubit(RevenueRepository(DioClient())),
                    child: const AdminRevenueSummaryPage(),
                  );
                case AdminNavPage.profile:
                  return OwnerProfilePage();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _bottomNav() {
    return BlocBuilder<AdminNavCubit, AdminNavPage>(
      builder: (context, page) {
        return NavigationBar(
          indicatorColor: Colors.transparent,
          selectedIndex: page.index,
          onDestinationSelected: (index) {
            context.read<AdminNavCubit>().changePage(
              AdminNavPage.values[index],
            );
          },
          destinations: [
            NavigationDestination(
              icon: GlowIcon(
                svgAsset: AppSvgAssets.dashboard,
                isSelected: page.index == 0,
              ),
              selectedIcon: GlowIcon(
                svgAsset: AppSvgAssets.dashboard,
                isSelected: page.index == 0,
              ),
              label: 'DashBoard',
            ),
            NavigationDestination(
              icon: GlowIcon(
                svgAsset: AppSvgAssets.sun,
                isSelected: page.index == 1,
              ),
              selectedIcon: GlowIcon(
                svgAsset: AppSvgAssets.sun,
                isSelected: page.index == 1,
              ),
              label: 'Leads',
            ),
            NavigationDestination(
              icon: GlowIcon(
                svgAsset: AppSvgAssets.cog,
                isSelected: page.index == 2,
              ),
              selectedIcon: GlowIcon(
                svgAsset: AppSvgAssets.cog,
                isSelected: page.index == 2,
              ),
              label: 'Services',
            ),
            NavigationDestination(
              icon: GlowIcon(
                svgAsset: AppSvgAssets.chartNoAxisCombined,
                isSelected: page.index == 3,
              ),
              selectedIcon: GlowIcon(
                svgAsset: AppSvgAssets.chartNoAxisCombined,
                isSelected: page.index == 3,
              ),
              label: 'Reports',
            ),
            NavigationDestination(
              icon: GlowIcon(
                svgAsset: AppSvgAssets.userRound,
                isSelected: page.index == 4,
              ),
              selectedIcon: GlowIcon(
                svgAsset: AppSvgAssets.userRound,
                isSelected: page.index == 4,
              ),
              label: 'Profile',
            ),
          ],
        );
      },
    );
  }
}

