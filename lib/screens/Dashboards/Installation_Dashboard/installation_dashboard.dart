import 'package:flutter/material.dart';
import 'package:solar_project/Cubits/Auth/auth_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/InstallationNavigation/installation_nav_cubit.dart';
import 'package:solar_project/Cubits/InstallationNavigation/installation_nav_state.dart';
import 'package:solar_project/Cubits/Installation/installation_cubit.dart';
import 'package:solar_project/core/app_colors.dart';
import 'package:solar_project/data/Repository/installation_repository.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/common_widgets.dart';
import 'package:solar_project/Helper/ui_helper.dart';
import 'package:solar_project/screens/Dashboards/Installation_Dashboard/Dashboard/installation_dashboard_screen.dart';
import 'package:solar_project/screens/Dashboards/Installation_Dashboard/Dashboard/installation_sidebar.dart';
import 'package:solar_project/screens/Dashboards/Installation_Dashboard/History/complete_installation.dart';
import 'package:solar_project/screens/Dashboards/Installation_Dashboard/MyInstallations/assigned_installation_screen.dart';
import 'package:solar_project/screens/Dashboards/Installation_Dashboard/Profile/installation_profile_screen.dart';

class InstallationDashboard extends StatefulWidget {
  const InstallationDashboard({super.key});

  @override
  State<InstallationDashboard> createState() => _InstallationDashboardState();
}

class _InstallationDashboardState extends State<InstallationDashboard> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => InstallationNavCubit()),
        BlocProvider(
          create: (ctx) => InstallationCubit(
            repo: InstallationRepository(),
            authCubit: ctx.read<AppStateCubit>(),
          ),
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
                        const InstallationSidebar(),
                        Expanded(
                          child: _desktopLayout(context),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  // ── Desktop ────────────────────────────────────────────────────────────────
  Widget _desktopLayout(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color:   AppColors.grayCustom),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Expanded(child: _pageBody())],
      ),
    );
  }

  // ── Mobile ─────────────────────────────────────────────────────────────────
  Widget _mobileLayout(BuildContext context) {
    return Column(children: [Expanded(child: _pageBody())]);
  }

  // ── Page Router ────────────────────────────────────────────────────────────
  Widget _pageBody() {
    return BlocBuilder<InstallationNavCubit, InstallationNavPage>(
      builder: (context, page) {
        switch (page) {
          case InstallationNavPage.dashboard:
            return const InstallationDashboardScreen();
          case InstallationNavPage.myInstallations:
            return const AssignedInstallationsScreen();
          case InstallationNavPage.history:
            return const CompletedInstallationsScreen();
          case InstallationNavPage.profile:
            return const InstallationProfileScreen();
        }
      },
    );
  }

  // ── Bottom Navigation Bar (mobile) ────────────────────────────────────────
  Widget _bottomNav(BuildContext context) {
    return BlocBuilder<InstallationNavCubit, InstallationNavPage>(
      builder: (context, page) {
        return NavigationBar(
          indicatorColor: Colors.transparent,
          selectedIndex: page.index,
          onDestinationSelected: (index) {
            context.read<InstallationNavCubit>().changePage(
              InstallationNavPage.values[index],
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
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: GlowIcon(
                svgAsset: AppSvgAssets.hammer,
                isSelected: page.index == 1,
              ),
              selectedIcon: GlowIcon(
                svgAsset: AppSvgAssets.hammer,
                isSelected: page.index == 1,
              ),
              label: 'My Jobs',
            ),
            NavigationDestination(
              icon: GlowIcon(
                svgAsset: AppSvgAssets.history,
                isSelected: page.index == 2,
              ),
              selectedIcon: GlowIcon(
                svgAsset: AppSvgAssets.history,
                isSelected: page.index == 2,
              ),
              label: 'History',
            ),
            NavigationDestination(
              icon: GlowIcon(
                svgAsset: AppSvgAssets.userRound,
                isSelected: page.index == 3,
              ),
              selectedIcon: GlowIcon(
                svgAsset: AppSvgAssets.userRound,
                isSelected: page.index == 3,
              ),
              label: 'Profile',
            ),
          ],
        );
      },
    );
  }
}

