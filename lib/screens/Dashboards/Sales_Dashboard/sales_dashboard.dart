// lib/screens/Dashboards/Sales_Dashboard/sales_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/SalesNavigation/sales_nav_state.dart';
import 'package:solar_project/Cubits/SalesNavigation/sales_nav_cubit.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/common_widgets.dart';
import 'package:solar_project/Helper/ui_helper.dart';
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
    return BlocProvider(
      create: (_) => SalesNavCubit(),
      child: Builder(
        builder: (context) {
          final compactLayout = !Responsive.isDesktop(context);
          return Scaffold(
            bottomNavigationBar: compactLayout ? _bottomNav() : null,
            body: SafeArea(
              child: compactLayout
                  ? _mobileLayout()
                  : Row(
                      children: [
                        const Sidebar(),
                        Expanded(child: _desktopLayout()),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _desktopLayout() => Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFCBC4CF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Expanded(child: _pageBody())],
        ),
      );

  Widget _mobileLayout() =>
      Column(children: [Expanded(child: _pageBody())]);

  // ── KEY FIX: IndexedStack keeps pages alive ───────────────────────────────
  Widget _pageBody() {
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

  Widget _bottomNav() {
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
              icon: GlowIcon(
                  svgAsset: AppSvgAssets.dashboard,
                  isSelected: page.index == 0),
              selectedIcon:
                  GlowIcon(svgAsset: AppSvgAssets.dashboard, isSelected: true),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: GlowIcon(
                  svgAsset: AppSvgAssets.sun, isSelected: page.index == 1),
              selectedIcon:
                  GlowIcon(svgAsset: AppSvgAssets.sun, isSelected: true),
              label: 'Leads',
            ),
            NavigationDestination(
              icon: GlowIcon(
                  svgAsset: AppSvgAssets.chartNoAxisCombined,
                  isSelected: page.index == 2),
              selectedIcon: GlowIcon(
                  svgAsset: AppSvgAssets.chartNoAxisCombined, isSelected: true),
              label: 'FollowUps',
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