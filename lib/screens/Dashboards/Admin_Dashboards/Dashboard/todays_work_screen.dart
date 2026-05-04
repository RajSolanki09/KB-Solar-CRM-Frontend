import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_cubit.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_state.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_cubit.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_state.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_state.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/data/Models/service_request_model.dart';
import 'package:solar_project/data/Models/solar_leads_model.dart';
import 'package:solar_project/data/Models/sprinkler_lead_model.dart';
import 'package:solar_project/services/api_service.dart';
import 'package:solar_project/Helper/app_colors.dart';

class TodaysWorkScreen extends StatefulWidget {
  const TodaysWorkScreen({super.key});

  @override
  State<TodaysWorkScreen> createState() => _TodaysWorkScreenState();
}

class _TodaysWorkScreenState extends State<TodaysWorkScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _materialCustomers = const [];

  @override
  void initState() {
    super.initState();
    _loadMaterialCustomers();
  }

  Future<void> _loadMaterialCustomers() async {
    try {
      final customers = await _apiService.getMaterialCustomers();
      if (mounted) {
        setState(() => _materialCustomers = customers);
      }
    } catch (_) {}
  }

  bool _isSameDay(DateTime? date, DateTime dayStart) {
    if (date == null) return false;
    final local = date.toLocal();
    return DateTime(
      local.year,
      local.month,
      local.day,
    ).isAtSameMomentAs(dayStart);
  }

  DateTime? _solarInstallationDate(SolarLeadsModel lead) {
    return lead.installationData.completedDate ??
        lead.installationData.startDate ??
        lead.installationAssignData.scheduledDate;
  }

  DateTime? _sprinklerInstallationDate(SprinklerLeadModel lead) {
    return lead.installationData.completedAt ??
        lead.installationData.startedAt ??
        lead.installationAssignData.scheduledDate;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SolarLeadCubit, SolarLeadState>(
      builder: (ctx, solarState) {
        return BlocBuilder<SprinklerLeadCubit, SprinklerLeadState>(
          builder: (ctx2, sprinklerState) {
            return BlocBuilder<ServiceLeadCubit, ServiceLeadState>(
              builder: (ctx3, serviceState) {
                final solarLeads = solarState is SolarLeadsLoaded
                    ? solarState.leads
                    : <SolarLeadsModel>[];
                final sprinklerLeads = sprinklerState is SprinklerLeadsLoaded
                    ? sprinklerState.leads
                    : <SprinklerLeadModel>[];
                final services = serviceState is ServiceLeadsLoaded
                    ? serviceState.services
                    : <ServiceRequestModel>[];

                final now = DateTime.now();
                final todayMid = DateTime(now.year, now.month, now.day);
                final dateFormat = DateFormat('dd MMM, hh:mm a');

                String formatDate(DateTime? d) {
                  if (d == null) return '-';
                  return dateFormat.format(d.toLocal());
                }

                final followupRows = <List<String>>[
                  ...solarLeads
                      .where((l) => _isSameDay(l.nextFollowupDate, todayMid))
                      .map(
                        (l) => [
                          'Solar',
                          l.customerName,
                          l.mobile,
                          solarStepToDisplay(l.currentStep),
                          formatDate(l.nextFollowupDate),
                          l.salesAssigned ?? l.createdBy ?? '-',
                        ],
                      ),
                  ...sprinklerLeads
                      .where((l) => _isSameDay(l.nextFollowupDate, todayMid))
                      .map(
                        (l) => [
                          'Sprinkler',
                          l.customerName,
                          l.phone,
                          sprinklerStepToDisplay(l.currentStep),
                          formatDate(l.nextFollowupDate),
                          l.assignedToName ?? '-',
                        ],
                      ),
                  ..._materialCustomers
                      .where((c) {
                        final pipeline = c['pipeline'];
                        if (pipeline is! Map<String, dynamic>) return false;
                        final followUp = pipeline['followUp'];
                        if (followUp is! Map<String, dynamic>) return false;
                        final followUpAt = followUp['followUpAt'];
                        if (followUpAt == null ||
                            followUpAt.toString().trim().isEmpty) return false;
                        final date = DateTime.tryParse(followUpAt.toString());
                        return _isSameDay(date, todayMid);
                      })
                      .map((c) {
                        final pipeline =
                            c['pipeline'] as Map<String, dynamic>? ?? {};
                        final followUp =
                            pipeline['followUp'] as Map<String, dynamic>? ?? {};
                        final date = DateTime.tryParse(
                          followUp['followUpAt'].toString(),
                        );
                        final assignedTo = followUp['assignedTo'];
                        final assignedName = assignedTo is Map
                            ? (assignedTo['name'] ??
                                      assignedTo['fullName'] ??
                                      '-')
                                  .toString()
                            : (assignedTo?.toString().isNotEmpty == true
                                  ? assignedTo.toString()
                                  : '-');
                        return [
                          'Material',
                          (c['customerName'] ?? '-').toString(),
                          (c['mobile'] ?? c['phone'] ?? '-').toString(),
                          (pipeline['status'] ?? 'Follow-up').toString(),
                          formatDate(date),
                          assignedName,
                        ];
                      }),
                ];

                final serviceRows = services
                    .where((s) {
                      final eventDate = s.serviceDate ?? s.createdAt;
                      return _isSameDay(eventDate, todayMid);
                    })
                    .map((s) {
                      final eventDate = s.serviceDate ?? s.createdAt;
                      return [
                        'Service',
                        s.customerName,
                        s.phone,
                        s.status,
                        formatDate(eventDate),
                        s.assignedToName ?? '-',
                      ];
                    })
                    .toList();

                final installationRows = <List<String>>[
                  ...solarLeads
                      .where((l) {
                        final installDate = _solarInstallationDate(l);
                        return l.currentStep.index >=
                                SolarStep.installationAssigned.index &&
                            _isSameDay(installDate, todayMid);
                      })
                      .map((l) {
                        final installDate = _solarInstallationDate(l);
                        final names = l.installationTeamMemberNames;
                        return [
                          'Solar',
                          l.customerName,
                          l.mobile,
                          solarStepToDisplay(l.currentStep),
                          formatDate(installDate),
                          names.isNotEmpty
                              ? names.join(', ')
                              : (l.installationTeam ?? '-'),
                        ];
                      }),
                  ...sprinklerLeads
                      .where((l) {
                        final installDate = _sprinklerInstallationDate(l);
                        return l.currentStep.index >=
                                SprinklerStep.installationAssigned.index &&
                            _isSameDay(installDate, todayMid);
                      })
                      .map((l) {
                        final installDate = _sprinklerInstallationDate(l);
                        return [
                          'Sprinkler',
                          l.customerName,
                          l.phone,
                          sprinklerStepToDisplay(l.currentStep),
                          formatDate(installDate),
                          l.effectiveInstallerNamesString ??
                              l.effectiveInstallerName ??
                              '-',
                        ];
                      }),
                ];

                final siteVisitRows = <List<String>>[
                  ...solarLeads
                      .where((l) => _isSameDay(l.visitDate, todayMid))
                      .map(
                        (l) => [
                          'Solar',
                          l.customerName,
                          l.mobile,
                          solarStepToDisplay(l.currentStep),
                          formatDate(l.visitDate),
                          l.salesAssigned ?? '-',
                        ],
                      ),
                  ...sprinklerLeads
                      .where((l) => _isSameDay(l.visitDate, todayMid))
                      .map(
                        (l) => [
                          'Sprinkler',
                          l.customerName,
                          l.phone,
                          sprinklerStepToDisplay(l.currentStep),
                          formatDate(l.visitDate),
                          l.salesPerson ?? '-',
                        ],
                      ),
                ];

                return Scaffold(
                  backgroundColor: AppColors.primaryLightest,
                  appBar: AppBar(
                    title: const Text('Today\'s Work'),
                    backgroundColor: AppColors.accent1,
                    foregroundColor: Colors.white,
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
                  ),
                  body: RefreshIndicator(
                    color: AppColors.accent1,
                    onRefresh: () async {
                      context.read<SolarLeadCubit>().fetchAllLeads();
                      context.read<SprinklerLeadCubit>().fetchAllLeads();
                      context.read<ServiceLeadCubit>().fetchAllServices();
                      await _loadMaterialCustomers();
                    },
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _TodayWorkTable(
                          title: 'Today Follow Up',
                          rows: followupRows,
                          emptyText: 'No follow up scheduled for today.',
                        ),
                        const SizedBox(height: 14),
                        _TodayWorkTable(
                          title: 'Today Services',
                          rows: serviceRows,
                          emptyText: 'No services for today.',
                        ),
                        const SizedBox(height: 14),
                        _TodayWorkTable(
                          title: 'Today Site Visits',
                          rows: siteVisitRows,
                          emptyText: 'No site visits scheduled for today.',
                        ),
                        const SizedBox(height: 14),
                        _TodayWorkTable(
                          title: 'Today Solar/Sprinkler Installation',
                          rows: installationRows,
                          emptyText: 'No installation work for today.',
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _TodayWorkTable extends StatelessWidget {
  final String title;
  final List<List<String>> rows;
  final String emptyText;

  const _TodayWorkTable({
    required this.title,
    required this.rows,
    required this.emptyText,
  });

  Widget _typeBadge(String type) {
    const color = AppColors.accent1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        type,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.accent1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1000;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (rows.isEmpty) const SizedBox(height: 2),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                emptyText,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      showCheckboxColumn: false,
                      headingRowHeight: 44,
                      dataRowMinHeight: 46,
                      dataRowMaxHeight: 56,
                      horizontalMargin: isDesktop ? 12 : 8,
                      columnSpacing: isDesktop ? 14 : 8,
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0XFFEDFDF9),
                      ),
                      headingTextStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0XFF0D9488).withValues(alpha: 0.8),
                      ),
                      dataTextStyle: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                      border: TableBorder(
                        horizontalInside: BorderSide(
                          color: Colors.blueGrey.shade50,
                        ),
                        bottom: BorderSide(color: Colors.blueGrey.shade100),
                        top: BorderSide(color: Colors.blueGrey.shade100),
                      ),
                      columns: const [
                        DataColumn(label: Text('Type')),
                        DataColumn(label: Text('Customer')),
                        DataColumn(label: Text('Phone')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Date/Time')),
                        DataColumn(label: Text('Assigned To')),
                      ],
                      rows: rows.map((r) {
                        return DataRow(
                          cells: [
                            DataCell(_typeBadge(r[0])),
                            ...r
                                .sublist(1)
                                .map(
                                  (v) => DataCell(
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        minWidth: 90,
                                        maxWidth: 170,
                                      ),
                                      child: Text(
                                        v,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}