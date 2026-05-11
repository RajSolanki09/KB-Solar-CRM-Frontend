// lib/screens/Dashboards/Sales_Dashboard/sales_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/SalesNavigation/sales_nav_state.dart';
import 'package:solar_project/Cubits/SalesNavigation/sales_nav_cubit.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_cubit.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_cubit.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/common_widgets.dart';
import 'package:solar_project/Helper/ui_helper.dart';
import 'package:solar_project/core/network/dio_client.dart';
import 'package:solar_project/data/Repository/solar_leads_repository.dart';
import 'package:solar_project/screens/Dashboards/Followups/followup_list_screen.dart';
import 'package:solar_project/screens/Dashboards/Leads/all_leads.dart';
import 'package:solar_project/screens/Dashboards/Sales_Dashboard/Home/sales_dashboard_screen.dart';
import 'package:solar_project/screens/Dashboards/Sales_Dashboard/Home/sales_sidebar.dart';
import 'package:solar_project/screens/Dashboards/Sales_Dashboard/Profile/sales_profile.dart';

class SalesDashboard extends StatefulWidget {
  const SalesDashboard({super.key});
  @override
  State<SalesDashboard> createState() => _SalesDashboardState();
}
class _SalesDashboardState extends State<SalesDashboard> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SalesNavCubit()),
        BlocProvider(
          create: (_) => SolarLeadCubit(SolarLeadRepository(DioClient())),
        ),
        BlocProvider(
          create: (_) => SprinklerLeadCubit(),
        ),
        BlocProvider(
          create: (_) => ServiceLeadCubit(),  // ← no args needed
        ),
      ],
      child: Builder(
        builder: (context) {
          final compactLayout = !Responsive.isDesktop(context);
          return Scaffold(
            bottomNavigationBar: compactLayout ? _bottomNav(context) : null,
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
          );
        },
      ),
    );
  }

  Widget _desktopLayout(BuildContext context) => Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFCBC4CF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Expanded(child: _pageBody(context))],
        ),
      );

  Widget _mobileLayout(BuildContext context) =>
      Column(children: [Expanded(child: _pageBody(context))]);

  Widget _pageBody(BuildContext context) {
    return BlocBuilder<SalesNavCubit, SalesNavPage>(
      builder: (context, page) {
        return IndexedStack(
          index: page.index,
          children: const [
            KeepAlivePage(child: SalesDashboardScreen()),
            KeepAlivePage(child: SalesLeadScreen()),
            KeepAlivePage(child: FollowupListScreen()),
            KeepAlivePage(child: SalesProfilePage()),
          ],
        );
      },
    );
  }

  Widget _bottomNav(BuildContext context) {
    return BlocBuilder<SalesNavCubit, SalesNavPage>(
      builder: (context, page) {
        return NavigationBar(
          indicatorColor: Colors.transparent,
          selectedIndex: page.index,
          onDestinationSelected: (i) => context
              .read<SalesNavCubit>()
              .changePage(SalesNavPage.values[i]),
          destinations: [
            NavigationDestination(
              icon: GlowIcon(svgAsset: AppSvgAssets.dashboard, isSelected: page.index == 0),
              selectedIcon: GlowIcon(svgAsset: AppSvgAssets.dashboard, isSelected: true),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: GlowIcon(svgAsset: AppSvgAssets.sun, isSelected: page.index == 1),
              selectedIcon: GlowIcon(svgAsset: AppSvgAssets.sun, isSelected: true),
              label: 'Leads',
            ),
            NavigationDestination(
              icon: GlowIcon(svgAsset: AppSvgAssets.chartNoAxisCombined, isSelected: page.index == 2),
              selectedIcon: GlowIcon(svgAsset: AppSvgAssets.chartNoAxisCombined, isSelected: true),
              label: 'FollowUps',
            ),
            NavigationDestination(
              icon: GlowIcon(svgAsset: AppSvgAssets.userRound, isSelected: page.index == 3),
              selectedIcon: GlowIcon(svgAsset: AppSvgAssets.userRound, isSelected: true),
              label: 'Profile',
            ),
          ],
        );
      },
    );
  }
}