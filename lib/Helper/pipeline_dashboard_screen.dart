// lib/Helper/pipeline_dashboard_screen.dart
import 'dart:math' as math;
import 'package:solar_project/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/Auth/auth_cubit.dart';
import 'package:solar_project/Cubits/Auth/auth_state.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_cubit.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_state.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_state.dart';
import 'package:solar_project/data/Models/solar_leads_model.dart';
import 'package:solar_project/data/Models/sprinkler_lead_model.dart';
import 'package:solar_project/Helper/lead_themes.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/screens/Dashboards/Leads/Solar/solar_lead_detail_screen.dart';
import 'package:solar_project/screens/Dashboards/Leads/Sprinkler/sprinkler_lead_detail_screen.dart';

//  Filter types
enum PipelineFilter { pendingQuotation, dealDone, todayVisits, completed }

//  Design constants
const double _kTableMinWidth = 900;
const double _kTableMinHeight = 180;
const Color _kTableHeaderBg = Color(0xFFCBD5DF);
const Color _kTableHeaderText = Color(0xFF2F3B47);
const Color _kTableAccentBlue = Color(0xFF1E88E5);
const Color _kTableBodyText = AppColors.textDark;
const Color _kTableMutedText = AppColors.textGray;

//  Shared date formatting
const List<String> _kMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')} ${_kMonths[d.month - 1]} ${d.year}';

String _fmtAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inDays == 0) return 'Today';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return _fmtDate(d);
}

//  Assignment filter helpers
bool _solarAssignedToMe(SolarLeadsModel l, String userName) {
  final assigned = (l.salesAssigned ?? '').trim().toLowerCase();
  if (assigned.isEmpty || userName.isEmpty) return true;
  return assigned == userName;
}

bool _spkAssignedToMe(SprinklerLeadModel l, String userId, String userName) {
  final assignedId = (l.assignedToId ?? '').trim().toLowerCase();
  final assigned = (l.salesPerson ?? l.assignedToName ?? '')
      .trim()
      .toLowerCase();
  if (assignedId.isNotEmpty && userId.isNotEmpty) {
    return assignedId == userId;
  }
  if (assigned.isEmpty || userName.isEmpty) return true;
  return assigned == userName;
}

// For visit-specific filtering: prioritise siteVisit.salesPerson name over
// the lead-level assignedToId so that admin-assigned visits appear correctly
// in the designated salesperson's dashboard.
bool _spkVisitAssignedToMe(
  SprinklerLeadModel l,
  String userId,
  String userName,
) {
  final visitPerson = (l.salesPerson ?? '').trim().toLowerCase();
  if (visitPerson.isNotEmpty) {
    if (userName.isEmpty) return true;
    return visitPerson == userName;
  }
  return _spkAssignedToMe(l, userId, userName);
}

//  Unified visit entry
class _VisitEntry {
  final String type;
  final String name, phone, address;
  final DateTime visitDate;
  final String? visitTimeStr;
  final String? assignedTo;
  final Color typeColor;
  final VoidCallback onTap;

  const _VisitEntry({
    required this.type,
    required this.name,
    required this.phone,
    required this.address,
    required this.visitDate,
    this.visitTimeStr,
    this.assignedTo,
    required this.typeColor,
    required this.onTap,
  });

  String get dateLabel => _fmtDate(visitDate.toLocal());

  String? get timeLabel {
    if (visitTimeStr != null && visitTimeStr!.isNotEmpty) {
      // Convert 24-hour time string to 12-hour AM/PM format (e.g. "14:30" → "2:30 PM")
      try {
        final parts = visitTimeStr!.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          final minute = parts[1];
          final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
          final ampm = hour >= 12 ? 'PM' : 'AM';
          return '$h:$minute $ampm';
        }
      } catch (_) {}
      return visitTimeStr;
    }
    if (visitDate.hour == 0 && visitDate.minute == 0) return null;
    final h = visitDate.hour > 12
        ? visitDate.hour - 12
        : (visitDate.hour == 0 ? 12 : visitDate.hour);
    final m = visitDate.minute.toString().padLeft(2, '0');
    final ampm = visitDate.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
}

//  Unified general entry
class _GeneralEntry {
  final String type;
  final String name, phone;
  final String? address;
  final String status;
  final double? amount;
  final DateTime date;
  final Color typeColor;
  final VoidCallback onTap;

  const _GeneralEntry({
    required this.type,
    required this.name,
    required this.phone,
    this.address,
    required this.status,
    this.amount,
    required this.date,
    required this.typeColor,
    required this.onTap,
  });
}

//  Entry point
class PipelineLeadsScreen extends StatelessWidget {
  final PipelineFilter filter;
  const PipelineLeadsScreen({super.key, required this.filter});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SolarLeadCubit, SolarLeadState>(
      builder: (context, solarState) {
        return BlocBuilder<SprinklerLeadCubit, SprinklerLeadState>(
          builder: (context, spkState) {
            final allSolar = solarState is SolarLeadsLoaded
                ? solarState.leads
                : <SolarLeadsModel>[];
            final allSpk = spkState is SprinklerLeadsLoaded
                ? spkState.leads
                : <SprinklerLeadModel>[];

            final isLoading =
                solarState is SolarLeadLoading ||
                spkState is SprinklerLeadLoading;

            final auth = context.read<AppStateCubit>().state;
            final userId = auth is Authenticated
                ? auth.userId.trim().toLowerCase()
                : '';
            final userName = auth is Authenticated
                ? auth.userName.trim().toLowerCase()
                : '';

            if (filter == PipelineFilter.todayVisits) {
              return _VisitScheduleScreen(
                allSolar: allSolar,
                allSpk: allSpk,
                isLoading: isLoading,
                userId: userId,
                userName: userName,
              );
            }

            return _FilteredLeadsScreen(
              filter: filter,
              allSolar: allSolar,
              allSpk: allSpk,
              isLoading: isLoading,
              userId: userId,
              userName: userName,
            );
          },
        );
      },
    );
  }
}

//  Filtered leads (Pending / Deal Done / Completed) — TABLE VIEW
class _FilteredLeadsScreen extends StatelessWidget {
  final PipelineFilter filter;
  final List<SolarLeadsModel> allSolar;
  final List<SprinklerLeadModel> allSpk;
  final bool isLoading;
  final String userId, userName;

  const _FilteredLeadsScreen({
    required this.filter,
    required this.allSolar,
    required this.allSpk,
    required this.isLoading,
    required this.userId,
    required this.userName,
  });

  String get _title => switch (filter) {
    PipelineFilter.pendingQuotation => 'Pending Quotations',
    PipelineFilter.dealDone => 'Deal Done',
    PipelineFilter.completed => 'Completed Projects',
    _ => '',
  };

  Color get _color => switch (filter) {
    PipelineFilter.pendingQuotation => const Color(0xFFF4511E),
    PipelineFilter.dealDone => const Color(0xFF43A047),
    PipelineFilter.completed => const Color(0xFFFB8C00),
    _ => AppColors.primaryDark,
  };

  String get _svgIcon => switch (filter) {
    PipelineFilter.pendingQuotation => AppSvgAssets.fileText,
    PipelineFilter.dealDone => AppSvgAssets.handshake,
    PipelineFilter.completed => AppSvgAssets.circleCheckBig,
    _ => AppSvgAssets.calendarDays,
  };

  List<_GeneralEntry> _buildEntries(BuildContext context) {
    final entries = <_GeneralEntry>[];

    final solarList = switch (filter) {
      PipelineFilter.pendingQuotation => allSolar.where(
        (l) =>
            (l.currentStep == SolarStep.technicalVisit ||
                l.currentStep == SolarStep.followup) &&
            _solarAssignedToMe(l, userName),
      ),
      PipelineFilter.dealDone => allSolar.where(
        (l) =>
            l.currentStep == SolarStep.dealDone &&
            _solarAssignedToMe(l, userName),
      ),
      PipelineFilter.completed => allSolar.where(
        (l) => l.isCompleted && _solarAssignedToMe(l, userName),
      ),
      _ => const Iterable<SolarLeadsModel>.empty(),
    };

    for (final l in solarList) {
      entries.add(
        _GeneralEntry(
          type: 'Solar',
          name: l.customerName,
          phone: l.mobile,
          address: l.address,
          status: l.status,
          amount: l.finalAmount ?? l.totalAmount,
          date: l.createdAt,
          typeColor: LeadTheme.primary,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<SolarLeadCubit>(),
                child: SolarLeadDetailScreen(lead: l),
              ),
            ),
          ),
        ),
      );
    }

    final spkList = switch (filter) {
      PipelineFilter.pendingQuotation => allSpk.where(
        (l) =>
            (l.currentStep == SprinklerStep.siteVisit ||
                l.currentStep == SprinklerStep.followup) &&
            _spkAssignedToMe(l, userId, userName),
      ),
      PipelineFilter.dealDone => allSpk.where(
        (l) =>
            l.currentStep == SprinklerStep.dealDone &&
            _spkAssignedToMe(l, userId, userName),
      ),
      PipelineFilter.completed => allSpk.where(
        (l) => l.isCompleted && _spkAssignedToMe(l, userId, userName),
      ),
      _ => const Iterable<SprinklerLeadModel>.empty(),
    };

    for (final l in spkList) {
      entries.add(
        _GeneralEntry(
          type: 'Sprinkler',
          name: l.customerName,
          phone: l.phone,
          address: l.address,
          status: l.status,
          amount: l.totalAmount,
          date: l.createdAt,
          typeColor: LeadTheme.secondary,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<SprinklerLeadCubit>(),
                child: SprinklerLeadDetailScreen(lead: l),
              ),
            ),
          ),
        ),
      );
    }

    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final entries = _buildEntries(context);

    return Scaffold(
      backgroundColor:  AppColors.background,
      appBar: _PipelineAppBar(
        title: _title,
        subtitle: isLoading
            ? 'Loading...'
            : '${entries.length} lead${entries.length != 1 ? "s" : ""}',
        color: _color,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : entries.isEmpty
          ? _EmptyState(svgIcon: _svgIcon, label: _title)
          : _GeneralTableSection(entries: entries, accentColor: _color),
    );
  }
}

//  Visit schedule screen
class _VisitScheduleScreen extends StatelessWidget {
  final List<SolarLeadsModel> allSolar;
  final List<SprinklerLeadModel> allSpk;
  final bool isLoading;
  final String userId, userName;

  const _VisitScheduleScreen({
    required this.allSolar,
    required this.allSpk,
    required this.isLoading,
    required this.userId,
    required this.userName,
  });

  bool _isToday(DateTime? date) {
    if (date == null) return false;
    final local = date.toLocal();
    final now = DateTime.now();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }

  bool _isUpcoming(DateTime? date) {
    if (date == null) return false;
    final local = date.toLocal();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final dateStart = DateTime(local.year, local.month, local.day);
    return dateStart.isAfter(todayStart);
  }

  @override
  Widget build(BuildContext context) {
    _VisitEntry solarEntry(SolarLeadsModel l) => _VisitEntry(
      type: 'Solar',
      name: l.customerName,
      phone: l.mobile,
      address: l.address,
      visitDate: l.visitDate!,
      assignedTo: l.salesAssigned,
      typeColor: LeadTheme.primary,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<SolarLeadCubit>(),
            child: SolarLeadDetailScreen(lead: l),
          ),
        ),
      ),
    );

    _VisitEntry spkEntry(SprinklerLeadModel l) => _VisitEntry(
      type: 'Sprinkler',
      name: l.customerName,
      phone: l.phone,
      address: l.address,
      visitDate: l.visitDate!,
      visitTimeStr: l.siteVisitData.visitTime,
      assignedTo: l.siteVisitData.salesPerson,
      typeColor: LeadTheme.secondary,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<SprinklerLeadCubit>(),
            child: SprinklerLeadDetailScreen(lead: l),
          ),
        ),
      ),
    );

    final todayEntries = <_VisitEntry>[
      ...allSolar
          .where(
            (l) => _isToday(l.visitDate) && _solarAssignedToMe(l, userName),
          )
          .map(solarEntry),
      ...allSpk
          .where(
            (l) =>
                _isToday(l.visitDate) &&
                _spkVisitAssignedToMe(l, userId, userName),
          )
          .map(spkEntry),
    ]..sort((a, b) => a.visitDate.compareTo(b.visitDate));

    final upcomingEntries = <_VisitEntry>[
      ...allSolar
          .where(
            (l) => _isUpcoming(l.visitDate) && _solarAssignedToMe(l, userName),
          )
          .map(solarEntry),
      ...allSpk
          .where(
            (l) =>
                _isUpcoming(l.visitDate) &&
                _spkVisitAssignedToMe(l, userId, userName),
          )
          .map(spkEntry),
    ]..sort((a, b) => a.visitDate.compareTo(b.visitDate));

    final total = todayEntries.length + upcomingEntries.length;

    return Scaffold(
      backgroundColor:  AppColors.background,
      appBar: _PipelineAppBar(
        title: 'Visits Schedule',
        subtitle: isLoading
            ? 'Loading...'
            : '$total visit${total != 1 ? "s" : ""}',
        color: AppColors.primary,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _VisitSectionWidget(
                    label: "Today's Visits",
                    svgAsset: AppSvgAssets.calendarDays,
                    accentColor: AppColors.primary,
                    entries: todayEntries,
                  ),
                  const SizedBox(height: 28),
                  _VisitSectionWidget(
                    label: 'Upcoming Visits',
                    svgAsset: AppSvgAssets.clock,
                    accentColor: AppColors.primaryDark,
                    entries: upcomingEntries,
                  ),
                ],
              ),
            ),
    );
  }
}

//  Visit section widget
class _VisitSectionWidget extends StatelessWidget {
  final String label;
  final String svgAsset;
  final Color accentColor;
  final List<_VisitEntry> entries;

  const _VisitSectionWidget({
    required this.label,
    required this.svgAsset,
    required this.accentColor,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionChip(
          label: label,
          svgAsset: svgAsset,
          color: accentColor,
          count: entries.length,
        ),
        const SizedBox(height: 14),
        if (entries.isEmpty)
          _EmptyTablePlaceholder(label: label)
        else
          LayoutBuilder(
            builder: (ctx, constraints) {
              return _VisitTable(
                entries: entries,
                accentColor: accentColor,
                availableWidth: constraints.maxWidth,
              );
            },
          ),
      ],
    );
  }
}

//  General table section (full-screen)
class _GeneralTableSection extends StatelessWidget {
  final List<_GeneralEntry> entries;
  final Color accentColor;

  const _GeneralTableSection({
    required this.entries,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final width = constraints.maxWidth;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 48),
          child: _GeneralTable(
            entries: entries,
            accentColor: accentColor,
            availableWidth: width - 32,
          ),
        );
      },
    );
  }
}

//
// VISIT TABLE — full-width proportional columns
//

class _VisitTable extends StatelessWidget {
  final List<_VisitEntry> entries;
  final Color accentColor;
  final double availableWidth;

  const _VisitTable({
    required this.entries,
    required this.accentColor,
    required this.availableWidth,
  });

  @override
  Widget build(BuildContext context) {
    const double wNum = 32;
    const double wType = 76;
    const double kRowHPad = 32.0;
    final double tableWidth = math.max(availableWidth, _kTableMinWidth);
    final double flexPool = tableWidth - wNum - wType - kRowHPad;
    final double maxTableHeight = MediaQuery.sizeOf(context).height * 0.52;
    final double rowsHeight = entries.length * 50;
    final double bodyHeight = math.max(
      _kTableMinHeight,
      math.min(maxTableHeight, rowsHeight),
    );
    // Flex: Name(3), Phone(2), Address(3), Date(2), Time(1.5), Assigned(2) = 13.5
    final double unit = flexPool / 13.5;
    final wName = unit * 3;
    final wPhone = unit * 2;
    final wAddress = unit * 3;
    final wDate = unit * 2;
    final wTime = unit * 1.5;
    final wAssigned = unit * 2;

    return Container(
      width: double.infinity,
      decoration: _tableDecor(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TableHeader(
                  color: accentColor,
                  cells: [
                    _HeaderCell(label: '#', width: wNum),
                    _HeaderCell(label: 'Type', width: wType),
                    _HeaderCell(label: 'Customer Name', width: wName),
                    _HeaderCell(label: 'Phone', width: wPhone),
                    _HeaderCell(label: 'Address', width: wAddress),
                    _HeaderCell(label: 'Visit Date', width: wDate),
                    _HeaderCell(label: 'Time', width: wTime),
                    _HeaderCell(label: 'Assigned To', width: wAssigned),
                  ],
                ),
                SizedBox(
                  height: bodyHeight,
                  child: SingleChildScrollView(
                    child: Column(
                      children: entries.asMap().entries.map((e) {
                        final idx = e.key;
                        final entry = e.value;
                        return _TableRowWidget(
                          isOdd: idx.isOdd,
                          isLast: idx == entries.length - 1,
                          onTap: entry.onTap,
                          cells: [
                            SizedBox(
                              width: wNum,
                              child: Text(
                                '${idx + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: wType,
                              child: _TypeBadge(
                                type: entry.type,
                                color: entry.typeColor,
                              ),
                            ),
                            SizedBox(
                              width: wName,
                              child: Text(
                                entry.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _kTableBodyText,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(
                              width: wPhone,
                              child: Text(
                                entry.phone,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _kTableMutedText,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(
                              width: wAddress,
                              child: Text(
                                entry.address.isNotEmpty ? entry.address : '—',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _kTableMutedText,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(
                              width: wDate,
                              child: Text(
                                entry.dateLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _kTableAccentBlue,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(
                              width: wTime,
                              child: Text(
                                entry.timeLabel ?? '—',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _kTableMutedText,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(
                              width: wAssigned,
                              child: Text(
                                entry.assignedTo?.isNotEmpty == true
                                    ? entry.assignedTo!
                                    : '—',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _kTableMutedText,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//
// GENERAL TABLE — full-width proportional columns
//

class _GeneralTable extends StatelessWidget {
  final List<_GeneralEntry> entries;
  final Color accentColor;
  final double availableWidth;

  const _GeneralTable({
    required this.entries,
    required this.accentColor,
    required this.availableWidth,
  });

  @override
  Widget build(BuildContext context) {
    const double wNum = 32;
    const double wType = 76;
    const double kRowHPad = 32.0;
    final double tableWidth = math.max(availableWidth, _kTableMinWidth);
    final double flexPool = tableWidth - wNum - wType - kRowHPad;
    final double maxTableHeight = MediaQuery.sizeOf(context).height * 0.58;
    final double rowsHeight = entries.length * 50;
    final double bodyHeight = math.max(
      _kTableMinHeight,
      math.min(maxTableHeight, rowsHeight),
    );
    // Flex: Name(3), Phone(2), Address(3), Status(2), Amount(2), Date(1.5) = 13.5
    final double unit = flexPool / 13.5;
    final wName = unit * 3;
    final wPhone = unit * 2;
    final wAddress = unit * 3;
    final wStatus = unit * 2;
    final wAmount = unit * 2;
    final wDate = unit * 1.5;

    return Container(
      width: double.infinity,
      decoration: _tableDecor(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TableHeader(
                  color: accentColor,
                  cells: [
                    _HeaderCell(label: '#', width: wNum),
                    _HeaderCell(label: 'Type', width: wType),
                    _HeaderCell(label: 'Customer Name', width: wName),
                    _HeaderCell(label: 'Phone', width: wPhone),
                    _HeaderCell(label: 'Address', width: wAddress),
                    _HeaderCell(label: 'Status', width: wStatus),
                    _HeaderCell(label: 'Amount (Rs.)', width: wAmount),
                    _HeaderCell(label: 'Date', width: wDate),
                  ],
                ),
                SizedBox(
                  height: bodyHeight,
                  child: SingleChildScrollView(
                    child: Column(
                      children: entries.asMap().entries.map((e) {
                        final idx = e.key;
                        final entry = e.value;
                        return _TableRowWidget(
                          isOdd: idx.isOdd,
                          isLast: idx == entries.length - 1,
                          onTap: entry.onTap,
                          cells: [
                            SizedBox(
                              width: wNum,
                              child: Text(
                                '${idx + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: wType,
                              child: _TypeBadge(
                                type: entry.type,
                                color: entry.typeColor,
                              ),
                            ),
                            SizedBox(
                              width: wName,
                              child: Text(
                                entry.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _kTableBodyText,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(
                              width: wPhone,
                              child: Text(
                                entry.phone,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _kTableMutedText,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(
                              width: wAddress,
                              child: Text(
                                entry.address?.isNotEmpty == true
                                    ? entry.address!
                                    : '—',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _kTableMutedText,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(
                              width: wStatus,
                              child: _StatusChip(
                                status: entry.status,
                                color: accentColor,
                              ),
                            ),
                            SizedBox(
                              width: wAmount,
                              child: Text(
                                entry.amount != null && entry.amount! > 0
                                    ? LeadTheme.formatAmount(entry.amount!)
                                    : '—',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      entry.amount != null && entry.amount! > 0
                                      ? _kTableAccentBlue
                                      : AppColors.textLight,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(
                              width: wDate,
                              child: Text(
                                _fmtAgo(entry.date),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _kTableMutedText,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//
// SHARED TABLE BUILDING BLOCKS
//

BoxDecoration _tableDecor() => BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: const Color(0xFFCDD6E0)),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ],
);

class _HeaderCell {
  final String label;
  final double width;
  const _HeaderCell({required this.label, required this.width});
}

class _TableHeader extends StatelessWidget {
  final Color color;
  final List<_HeaderCell> cells;
  const _TableHeader({required this.color, required this.cells});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kTableHeaderBg,
        border: Border(
          bottom: const BorderSide(color: Color(0xFFB8C4D1), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: cells
            .map(
              (c) => SizedBox(
                width: c.width,
                child: Text(
                  c.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kTableHeaderText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TableRowWidget extends StatelessWidget {
  final bool isOdd, isLast;
  final VoidCallback onTap;
  final List<Widget> cells;

  const _TableRowWidget({
    required this.isOdd,
    required this.isLast,
    required this.onTap,
    required this.cells,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: isOdd ? const Color(0xFFF9FBFD) : AppColors.surface,
          child: InkWell(
            onTap: onTap,
            splashColor: const Color(0xFFE3EEF9),
            highlightColor: const Color(0xFFF2F7FC),
            hoverColor: const Color(0xFFF4F8FC),
            mouseCursor: SystemMouseCursors.click,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: Row(children: cells),
            ),
          ),
        ),
        if (!isLast)
          const Divider(height: 1, thickness: 1, color: Color(0xFFE6EDF5)),
      ],
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  final Color color;
  const _TypeBadge({required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            type,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusChip({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _kTableAccentBlue.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kTableAccentBlue.withValues(alpha: 0.35)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _kTableAccentBlue,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

//
// SHARED UI COMPONENTS
//

class _PipelineAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title, subtitle;
  final Color color;
  const _PipelineAppBar({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: color,
      elevation: 0,
      leading: IconButton(
        icon: const AppSvgIcon(
          AppSvgAssets.chevronLeft,
          color: AppColors.surface,
          size: 18,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.surface,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.surface),
          ),
        ],
      ),
    );
  }
}

class _SectionChip extends StatelessWidget {
  final String label, svgAsset;
  final Color color;
  final int count;
  const _SectionChip({
    required this.label,
    required this.svgAsset,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE6EEF7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: AppSvgIcon(svgAsset, size: 15, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color:  AppColors.textDark,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F1FB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _kTableAccentBlue,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String svgIcon, label;
  const _EmptyState({required this.svgIcon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppSvgIcon(svgIcon, size: 64, color: AppColors.divider),
          const SizedBox(height: 12),
          Text(
            'No $label',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Assigned leads will appear here',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade300),
          ),
        ],
      ),
    );
  }
}

class _EmptyTablePlaceholder extends StatelessWidget {
  final String label;
  const _EmptyTablePlaceholder({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        'No leads for $label',
        style: TextStyle(fontSize: 13, color: AppColors.textLight),
      ),
    );
  }
}
