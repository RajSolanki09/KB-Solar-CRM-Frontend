import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/AdminNavigation/admin_nav_cubit.dart';
import 'package:solar_project/Cubits/AdminNavigation/admin_nav_state.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/app_colors.dart';

class AdminBottomNavBar extends StatelessWidget {
  const AdminBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminNavCubit, AdminNavPage>(
      builder: (context, activePage) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.textSecondary.withValues(alpha:(0.3)),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: activePage.index,
            onTap: (index) {
              context.read<AdminNavCubit>().changePage(AdminNavPage.values[index]);
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.deepPurple,
            unselectedItemColor: AppColors.textSecondary,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
            items: [
              _buildNavItem(
                page: AdminNavPage.dashboard,
                activePage: activePage,
                label: 'Dashboard',
                icon: AppSvgAssets.home,
              ),
              _buildNavItem(
                page: AdminNavPage.leads,
                activePage: activePage,
                label: 'Leads',
                icon: AppSvgAssets.users,
              ),
              _buildNavItem(
                page: AdminNavPage.service,
                activePage: activePage,
                label: 'Service',
                icon: AppSvgAssets.cog,
              ),
               _buildNavItem(
                 page: AdminNavPage.reports,
                 activePage: activePage,
                 label: 'Reports',
                 icon: AppSvgAssets.chartNoAxisCombined,
               ),
              _buildNavItem(
                page: AdminNavPage.profile,
                activePage: activePage,
                label: 'Profile',
                icon: AppSvgAssets.userRound,
              ),
            ],
          ),
        );
      },
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required AdminNavPage page,
    required AdminNavPage activePage,
    required String label,
    required String icon,
  }) {
    final bool isActive = page == activePage;
    return BottomNavigationBarItem(
      icon: AppSvgIcon(
        icon,
        color: isActive ? AppColors.deepPurple : AppColors.textSecondary,
      ),
      label: label,
    );
  }
}

