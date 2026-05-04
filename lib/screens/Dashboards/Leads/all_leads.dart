import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/Auth/auth_cubit.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_cubit.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_state.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_state.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/Helper/role_helper.dart';
import 'package:solar_project/screens/Dashboards/Leads/Solar/add_solar_lead_screen.dart';
import 'package:solar_project/screens/Dashboards/Leads/Solar/solar_leads_list_screen.dart';
import 'package:solar_project/screens/Dashboards/Leads/Sprinkler/add_sprinkler_lead_screen.dart';
import 'package:solar_project/screens/Dashboards/Leads/Sprinkler/sprinkler_leads_list_screen.dart';
import 'package:solar_project/Helper/app_colors.dart';

class SalesLeadScreen extends StatefulWidget {
  final int initialTabIndex;
  const SalesLeadScreen({super.key, this.initialTabIndex = 0});

  @override
  State<SalesLeadScreen> createState() => _SalesLeadScreenState();
}

class _SalesLeadScreenState extends State<SalesLeadScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final safeInitialTab = widget.initialTabIndex.clamp(0, 1);
    _tabController = TabController(length: 2, vsync: this)
      ..index = safeInitialTab
      ..addListener(() {
        if (mounted) setState(() {});
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SolarLeadCubit>().fetchAllLeads();
      context.read<SprinklerLeadCubit>().fetchAllLeads();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshCurrentTab() {
    if (_tabController.index == 0) {
      context.read<SolarLeadCubit>().fetchAllLeads();
    } else {
      context.read<SprinklerLeadCubit>().fetchAllLeads();
    }
  }

  Future<void> _addLead() async {
    if (_tabController.index == 0) {
      final cubit = context.read<SolarLeadCubit>();
      final added = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: cubit,
            child: const AddSolarLeadScreen(),
          ),
        ),
      );
      if (!mounted) return;
      if (added == true) await cubit.fetchAllLeads();
      return;
    }

    final cubit = context.read<SprinklerLeadCubit>();
    final added = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: const AddSprinklerLeadScreen(),
        ),
      ),
    );
    if (!mounted) return;
    if (added != null) await cubit.fetchAllLeads();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _tabController.index == 0
        ? LeadTheme.warning
        : LeadTheme.secondary;

    return Scaffold(
      backgroundColor: AppColors.primaryLightest),
      appBar: AppBar(
        backgroundColor: AppColors.primaryLightest),
        elevation: 0,
        titleSpacing: 16,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const AppSvgIcon(
                  AppSvgAssets.chevronLeft,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Row(
          children: [
            AppSvgIcon(
              AppSvgAssets.layoutList,
              color: AppColors.accent2),
              size: 18,
            ),
            SizedBox(width: 8),
            const Text(
              'All Leads',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.accent2),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const AppSvgIcon(
              AppSvgAssets.refreshCw,
              color: AppColors.accent2),
            ),
            onPressed: _refreshCurrentTab,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: activeColor,
              indicatorWeight: 2.5,
              labelColor: activeColor,
              unselectedLabelColor: AppColors.textTertiary),
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(
                  child: BlocBuilder<SolarLeadCubit, SolarLeadState>(
                    builder: (context, state) {
                      final count = state is SolarLeadsLoaded
                          ? state.leads.length
                          : 0;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const AppSvgIcon(AppSvgAssets.sun, size: 14),
                          const SizedBox(width: 5),
                          const Text('Project'),
                          if (count > 0) ...[
                            const SizedBox(width: 5),
                            _CountChip(count, LeadTheme.warning),
                          ],
                        ],
                      );
                    },
                  ),
                ),
                Tab(
                  child: BlocBuilder<SprinklerLeadCubit, SprinklerLeadState>(
                    builder: (context, state) {
                      final count = state is SprinklerLeadsLoaded
                          ? state.leads.length
                          : 0;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const AppSvgIcon(AppSvgAssets.droplet, size: 14),
                          const SizedBox(width: 5),
                          const Text('Sprinkler'),
                          if (count > 0) ...[
                            const SizedBox(width: 5),
                            _CountChip(count, LeadTheme.secondary),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Builder(
        builder: (context) {
          final role = RoleHelper.roleFrom(context.read<AppStateCubit>().state);
          if (!RoleHelper.canAddLead(role)) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            backgroundColor: activeColor,
            onPressed: _addLead,
            icon: const AppSvgIcon(
              AppSvgAssets.plus,
              color: Colors.white,
              size: 18,
            ),
            label: Text(
              _tabController.index == 0 ? 'Project Lead' : 'Sprinkler Lead',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            elevation: 4,
          );
        },
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SolarLeadsListScreen(embedded: true),
          SprinklerLeadsListScreen(embedded: true),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final int count;
  final Color color;
  const _CountChip(this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}





