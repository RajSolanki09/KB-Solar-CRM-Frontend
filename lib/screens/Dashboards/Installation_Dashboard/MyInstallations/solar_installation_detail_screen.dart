// lib/screens/Dashboards/Installation_Dashboard/MyInstallations/installation_detail_screen.dart
//
// ── How API calls work ────────────────────────────────────────────────────────
// This screen calls InstallationCubit.updateStatus(installationId, status, extra)
// The cubit calls InstallationRepository.updateStatus() which maps each
// InstallationStatus enum value to the correct PUT endpoint and body:
//
//   installationStarted   → PUT /installation/my-leads/:id/start
//                           body: { startDate }
//                           files: beforePhotos[] (multipart)
//
//   installationCompleted → PUT /installation/my-leads/:id/installation
//                           body: { systemTested, customerSigned, installationDate, notes }
//                           files: afterPhotos[] (multipart)
//                           Backend now marks projectCompleted = true
//
// NO "status" string is ever sent in the body. The backend derives status
// from which endpoint was called, preventing the 500 validation error.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:solar_project/Helper/picked_photo.dart';
import 'package:solar_project/Cubits/Installation/installation_cubit.dart';
import 'package:solar_project/Cubits/Installation/installation_state.dart';
import 'package:solar_project/Cubits/SolarLeads/solar_leads_cubit.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart';
import 'package:solar_project/core/network/dio_client.dart';
import 'package:solar_project/data/Models/installation_model.dart';
import 'package:solar_project/data/Models/solar_leads_model.dart';
import 'package:solar_project/data/Models/sprinkler_lead_model.dart';
import 'package:solar_project/data/Repository/solar_leads_repository.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/Helper/app_colors.dart';
import 'package:solar_project/screens/Dashboards/Leads/Solar/Steps/installation_completed_screen.dart';
import 'package:solar_project/screens/Dashboards/Leads/Solar/Steps/installation_started_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Palette
// ─────────────────────────────────────────────────────────────────────────────
const _kPurple = AppColors.lightPurple;
const _kBlue = AppColors.lightPurple;
const _kGreen = AppColors.lightPurple;
const _kAmber = AppColors.lightPurple;
const _kRed = AppColors.lightPurple;
const _kBg = AppColors.bgSecondary);
const _kText = AppColors.textPrimary);
const _kTextSec = AppColors.textSecondary);
const _kTextMut = AppColors.textTertiary);
const _kBorder = AppColors.borderLight);

// ─────────────────────────────────────────────────────────────────────────────
// Pipeline
// ─────────────────────────────────────────────────────────────────────────────
const _kAllSteps = [
  InstallationStatus.installationAssigned,
  InstallationStatus.installationStarted,
  InstallationStatus.installationCompleted,
  InstallationStatus.meterApplied,
  InstallationStatus.meterInspection,
  InstallationStatus.meterInstalled,
];

const _kVisibleSteps = [
  InstallationStatus.installationAssigned,
  InstallationStatus.installationStarted,
];

int _visibleStepIndex(InstallationStatus status) {
  switch (status) {
    case InstallationStatus.installationAssigned:
      return 0;
    case InstallationStatus.installationStarted:
      return 1;
    case InstallationStatus.installationCompleted:
    case InstallationStatus.meterApplied:
    case InstallationStatus.meterInspection:
    case InstallationStatus.meterInstalled:
    case InstallationStatus.projectCompleted:
      return 2;
  }
}

String _statusLabel(InstallationStatus s) {
  switch (s) {
    case InstallationStatus.installationAssigned:
      return 'Assigned';
    case InstallationStatus.installationStarted:
      return 'Started';
    case InstallationStatus.installationCompleted:
      return 'Installation Completed';
    case InstallationStatus.meterApplied:
      return 'Meter Applied';
    case InstallationStatus.meterInspection:
      return 'Inspecting';
    case InstallationStatus.meterInstalled:
      return 'Meter Installed ✓';
    case InstallationStatus.projectCompleted:
      return 'Project Complete 🏆';
  }
}

InstallationStatus _nextStep(InstallationStatus s) {
  final i = _kAllSteps.indexOf(s);
  return i < _kAllSteps.length - 1 ? _kAllSteps[i + 1] : s;
}

// ─────────────────────────────────────────────────────────────────────────────
// Per-step UI metadata
// ─────────────────────────────────────────────────────────────────────────────
class _SM {
  final String emoji, title, hint;
  final Color color;
  final int n;
  const _SM(this.emoji, this.title, this.hint, this.color, this.n);
}

const _kMeta = <InstallationStatus, _SM>{
  InstallationStatus.installationAssigned: _SM(
    '🏗️',
    'Installation Started',
    'Confirm arrival — capture site photos before starting',
    _kPurple,
    1,
  ),
  InstallationStatus.installationStarted: _SM(
    '⚡',
    'Installation Completed',
    'Panel/wiring/inverter photos + sign-off',
    _kAmber,
    2,
  ),
  InstallationStatus.installationCompleted: _SM(
    '✅',
    'Installation Completed',
    'Final installation details are complete',
    _kGreen,
    3,
  ),
  InstallationStatus.meterApplied: _SM(
    '🔍',
    'Meter Inspection',
    'Inspection date + inspector details',
    _kBlue,
    4,
  ),
  InstallationStatus.meterInspection: _SM(
    '⚙️',
    'Meter Installed',
    'Meter number + installation photos',
    _kGreen,
    5,
  ),
  InstallationStatus.meterInstalled: _SM(
    '🏆',
    'Project Completed',
    'Set automatically when meter is installed',
    _kGreen,
    6,
  ),
  InstallationStatus.projectCompleted: _SM(
    '🏆',
    'Project Completed',
    'All steps complete',
    _kGreen,
    6,
  ),
};

// ─────────────────────────────────────────────────────────────────────────────
// Public screen
// ─────────────────────────────────────────────────────────────────────────────
class InstallationDetailScreen extends StatefulWidget {
  final String leadId;
  final String customerName;
  final String phone;
  final String address;
  final String village;
  final bool isSolar;
  final double? systemKw;
  final String? electricityConnection;
  final double? farmSize;
  final String? waterSource;
  final String? cropType;
  final String? assignedByName;
  final String? assignmentNotes;
  final InstallationStatus initialStatus;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final bool initialProjectCompleted;

  const InstallationDetailScreen._({
    required this.leadId,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.village,
    required this.isSolar,
    this.systemKw,
    this.electricityConnection,
    this.farmSize,
    this.waterSource,
    this.cropType,
    this.assignedByName,
    this.assignmentNotes,
    required this.initialStatus,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    this.initialProjectCompleted = false,
  });

  factory InstallationDetailScreen.fromSolar(SolarLeadsModel l) =>
      InstallationDetailScreen._(
        leadId: l.id,
        customerName: l.customerName,
        phone: l.mobile,
        address: l.address,
        village: l.village,
        isSolar: true,
        systemKw: l.requiredKW,
        electricityConnection: l.electricityConnection,
        assignedByName: l.createdBy,
        assignmentNotes: l.installationAssignData.notes,
        initialStatus: InstallationStatus.installationAssigned,
        totalAmount: l.finalAmount?.toDouble() ?? 0,
        paidAmount: l.advancePayment?.toDouble() ?? 0,
        remainingAmount: ((l.finalAmount ?? 0) - (l.advancePayment ?? 0))
            .clamp(0, double.infinity)
            .toDouble(),
      );

  factory InstallationDetailScreen.fromSprinkler(SprinklerLeadModel l) =>
      InstallationDetailScreen._(
        leadId: l.id,
        customerName: l.customerName,
        phone: l.phone,
        address: l.address,
        village: l.village,
        isSolar: false,
        farmSize: l.farmSize,
        waterSource: l.waterSource,
        cropType: l.cropType,
        assignedByName: l.createdByName,
        assignmentNotes: l.installationAssignData.notes,
        initialStatus: InstallationStatus.installationAssigned,
        totalAmount: 0,
        paidAmount: 0,
        remainingAmount: 0,
      );

  factory InstallationDetailScreen.fromModel(InstallationModel m) =>
      InstallationDetailScreen._(
        leadId: m.id,
        customerName: m.customerName,
        phone: m.phone,
        address: m.address,
        village: '',
        isSolar: m.projectType == 'solar',
        systemKw: m.systemSize > 0 ? m.systemSize : null,
        assignedByName: m.assignedByName,
        assignmentNotes: m.notes,
        initialStatus: m.status,
        totalAmount: m.totalAmount,
        paidAmount: m.paidAmount,
        remainingAmount: m.remainingAmount,
        initialProjectCompleted: m.projectCompleted,
      );

  // ── Compute expanded height based on content ──────────────────────────────
  double get _heroExpandedHeight {
    double h = 210.0;
    // Each badge row adds ~28px (Wrap with runSpacing)
    final badgeCount = [
      systemKw != null,
      electricityConnection != null,
      farmSize != null,
      waterSource != null,
      assignedByName != null,
    ].where((b) => b).length;
    if (badgeCount > 3) h += 28.0; // second badge row

    // Assignment note block
    final note = assignmentNotes?.trim() ?? '';
    if (note.isNotEmpty) {
      // Base note container height ~56px + ~16px per extra line (approx 40 chars/line)
      final lines = (note.length / 40).ceil().clamp(1, 6);
      h += 56.0 + (lines - 1) * 16.0;
    }
    return h;
  }

  @override
  State<InstallationDetailScreen> createState() =>
      _InstallationDetailScreenState();
}

class _InstallationDetailScreenState extends State<InstallationDetailScreen> {
  late InstallationStatus _currentStatus;
  late bool _projectCompleted;

  Color get _accent => widget.isSolar ? _kPurple : _kBlue;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.initialStatus;
    _projectCompleted = widget.initialProjectCompleted ||
        widget.initialStatus == InstallationStatus.installationCompleted ||
        widget.initialStatus == InstallationStatus.projectCompleted;
  }

  Future<void> _openForm(InstallationStatus step) async {
    if (_projectCompleted || step == InstallationStatus.meterInstalled) return;

    final stepIdx = _kVisibleSteps.indexOf(step);
    final currentIdx = _visibleStepIndex(
      _projectCompleted ? InstallationStatus.projectCompleted : _currentStatus,
    );
    if (currentIdx >= _kVisibleSteps.length || stepIdx < 0 || stepIdx > currentIdx) return;

    if (step == InstallationStatus.installationAssigned ||
        step == InstallationStatus.installationStarted) {
      SolarLeadsModel lead;
      try {
        lead = await SolarLeadRepository(DioClient()).getSingleLead(widget.leadId);
      } catch (e) {
        if (!mounted) return;
        AppFeedback.showError(context, 'Could not load lead: $e');
        return;
      }

      final updatedLead = await Navigator.push<SolarLeadsModel>(
        context,
        MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: context.read<InstallationCubit>()),
              BlocProvider.value(value: context.read<SolarLeadCubit>()),
              BlocProvider.value(value: context.read<SprinklerLeadCubit>()),
            ],
            child: step == InstallationStatus.installationAssigned
                ? SolarInstallationStartedScreen(lead: lead)
                : SolarInstallationScreen(lead: lead),
          ),
        ),
      );

      if (updatedLead != null && mounted) {
        final wasProjectCompleted = _projectCompleted;
        final hasCompleted = updatedLead.installationData.completedDate != null;
        final hasStarted = updatedLead.installationData.startDate != null;
        final updatedStatus = hasCompleted
            ? InstallationStatus.installationCompleted
            : hasStarted
            ? InstallationStatus.installationStarted
            : InstallationStatus.installationAssigned;

        setState(() {
          _currentStatus = updatedStatus;
          _projectCompleted =
              updatedLead.isCompleted ||
              updatedStatus == InstallationStatus.installationCompleted;
        });

        AppFeedback.showSuccess(context, 'Status updated successfully!');
        if (!mounted) return;
        context.read<InstallationCubit>().fetchInstallations();
        context.read<SolarLeadCubit>().fetchAllLeads();
        context.read<SprinklerLeadCubit>().fetchAllLeads();

        if (!wasProjectCompleted && _projectCompleted) {
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) _showCompletionDialog();
          });
        }
      }
      return;
    }

    final updated = await Navigator.push<InstallationStatus>(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<InstallationCubit>()),
            BlocProvider.value(value: context.read<SolarLeadCubit>()),
            BlocProvider.value(value: context.read<SprinklerLeadCubit>()),
          ],
          child: _StepFormScreen(
            leadId: widget.leadId,
            step: step,
            customerName: widget.customerName,
          ),
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() => _currentStatus = updated);
      AppFeedback.showSuccess(context, 'Status updated successfully!');
      if (!mounted) return;
      context.read<SolarLeadCubit>().fetchAllLeads();
      context.read<SprinklerLeadCubit>().fetchAllLeads(status: 'dealDone');
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            const Text(
              'Project Completed!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              "${widget.customerName}'s installation is fully complete.\nAdmin has been notified.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: _kTextSec,
                height: 1.5,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'Done  →',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: _kGreen,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: BlocListener<InstallationCubit, InstallationState>(
        listener: (ctx, state) {
          if (!ctx.mounted) return;

          if (state is InstallationError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: _kRed,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
          if (state is InstallationActionSuccess) {
            final match = state.updated;
            if (match != null && match.id == widget.leadId && mounted) {
              final wasProjectCompleted = _projectCompleted;
              setState(() {
                _currentStatus = match.status;
                _projectCompleted = match.projectCompleted ||
                    match.status == InstallationStatus.installationCompleted ||
                    match.status == InstallationStatus.projectCompleted;
              });
              if (!wasProjectCompleted && _projectCompleted) {
                Future.delayed(const Duration(milliseconds: 400), () {
                  if (mounted) _showCompletionDialog();
                });
              }
            }
            if (ctx.mounted) ctx.read<SolarLeadCubit>().fetchAllLeads();
          }
        },
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: widget._heroExpandedHeight, // ← dynamic
                  backgroundColor: _accent,
                  leading: IconButton(
                    icon: const AppSvgIcon(
                      AppSvgAssets.chevronLeft,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: _hero(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _heading('Installation Pipeline'),
                        const SizedBox(height: 10),
                        _pipelineCard(),
                        if (_projectCompleted) ...[
                          const SizedBox(height: 16),
                          _completionBanner(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (!_projectCompleted)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _UpdateStatusBar(
                  currentStatus: _currentStatus,
                  accent: _accent,
                  onTap: () => _openForm(_currentStatus),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _completionBanner() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.lightPurple, AppColors.lightPurple],
      ),
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: _kGreen.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: const Row(
      children: [
        Text('🏆', style: TextStyle(fontSize: 28)),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Project Completed!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'All steps done. Completed projects are locked for editing.',
                style: TextStyle(color: Colors.white70, fontSize: 11.5),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _hero() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [_accent, _accent.withOpacity(0.78)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Stack(
      children: [
        Positioned(
          top: -30,
          right: -30,
               child: Container(
             width: 140,
             height: 140,
             decoration: BoxDecoration(
               shape: BoxShape.circle,
               color: Colors.white.withOpacity(0.07),
             ),
           ),
        ),
        // ── KEY FIX: wrap in LayoutBuilder so content never overflows ──
        Positioned.fill(
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _heroBadge(
                    widget.isSolar
                        ? '☀️  KaaryaBook Solar'
                        : '💧  KaaryaBook Sprinkler',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.customerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const AppSvgIcon(
                        AppSvgAssets.phone,
                        size: 13,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.phone,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const AppSvgIcon(
                        AppSvgAssets.mapPin,
                        size: 13,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.village.isNotEmpty
                              ? '${widget.address}, ${widget.village}'
                              : widget.address,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (widget.systemKw != null)
                        _heroBadge(
                          '⚡ ${widget.systemKw!.toStringAsFixed(widget.systemKw! % 1 == 0 ? 0 : 1)} kW',
                        ),
                      if (widget.electricityConnection != null)
                        _heroBadge('🔌 ${widget.electricityConnection}'),
                      if (widget.farmSize != null)
                        _heroBadge(
                          '🌾 ${widget.farmSize!.toStringAsFixed(0)} acres',
                        ),
                      if (widget.waterSource != null)
                        _heroBadge('💧 ${widget.waterSource}'),
                      if (widget.assignedByName != null)
                        _heroBadge('👤 ${widget.assignedByName}'),
                    ],
                  ),
                  if (widget.assignmentNotes?.trim().isNotEmpty ?? false) ...[
                    const SizedBox(height: 10),
                    _heroNote(widget.assignmentNotes!.trim()),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      '${_kMeta[_currentStatus]!.emoji}  ${_statusLabel(_currentStatus)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _heroBadge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _heroNote(String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📝', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Assignment Note',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _heading(String text) => Row(
    children: [
      Container(
        width: 3,
        height: 16,
        decoration: BoxDecoration(
          color: _accent,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: _kText,
        ),
      ),
    ],
  );

  Widget _pipelineCard() {
    final currentIdx = _visibleStepIndex(
      _projectCompleted ? InstallationStatus.projectCompleted : _currentStatus,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: _kVisibleSteps.asMap().entries.map((e) {
          final stepIdx = e.key;
          final step = e.value;
          final isDone = stepIdx < currentIdx;
          final isActive = stepIdx == currentIdx;
          final isPending = stepIdx > currentIdx;

          return _PipelineRow(
            step: step,
            isDone: isDone,
            isActive: isActive,
            isPending: isPending,
            isLast: stepIdx == _kAllSteps.length - 1,
            isAutoStep: step == InstallationStatus.meterInstalled,
            onTap:
                (_projectCompleted ||
                    isPending ||
                    step == InstallationStatus.meterInstalled)
                ? null
                : () => _openForm(step),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pipeline row
// ─────────────────────────────────────────────────────────────────────────────
class _PipelineRow extends StatelessWidget {
  final InstallationStatus step;
  final bool isDone, isActive, isPending, isLast, isAutoStep;
  final VoidCallback? onTap;

  const _PipelineRow({
    required this.step,
    required this.isDone,
    required this.isActive,
    required this.isPending,
    required this.isLast,
    required this.isAutoStep,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final m = _kMeta[step]!;
    final dotColor = isDone
        ? _kGreen
        : isActive
        ? m.color
        : _kBorder;
    final lineColor = isDone ? AppColors.primaryLightest) : _kBorder;
    final stepNum = _kAllSteps.indexOf(step) + 1;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 38,
            child: Column(
              children: [
                const SizedBox(height: 2),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isActive)
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: m.color.withValues(alpha: 0.25),
                            width: 2,
                          ),
                        ),
                      ),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                        boxShadow: !isPending
                            ? [
                                BoxShadow(
                                  color: dotColor.withValues(alpha: 0.45),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isDone
                            ? const AppSvgIcon(
                                AppSvgAssets.check,
                                color: Colors.white,
                                size: 14,
                              )
                            : isActive
                            ? Text(
                                m.emoji,
                                style: const TextStyle(fontSize: 13),
                              )
                            : Text(
                                '$stepNum',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _kTextMut,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 44,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      color: lineColor,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: GestureDetector(
                onTap: onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.primaryLightest).withValues(alpha: 0.55)
                        : isActive
                        ? m.color.withValues(alpha: 0.05)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isActive
                        ? Border.all(
                            color: m.color.withValues(alpha: 0.3),
                            width: 1.5,
                          )
                        : isDone
                        ? Border.all(color: _kGreen.withValues(alpha: 0.2))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    m.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isActive
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isDone
                                          ? AppColors.primary)
                                          : isActive
                                          ? m.color
                                          : _kTextMut,
                                    ),
                                  ),
                                ),
                                if (isDone)
                                  _badge('Done', _kGreen)
                                else if (isActive && isAutoStep)
                                  _badge('Auto ✓', _kGreen)
                                else if (isActive)
                                  _badge('Active ›', m.color)
                                else if (isPending && isAutoStep)
                                  _badge('Auto', _kTextMut),
                              ],
                            ),
                            if (!isPending) ...[
                              const SizedBox(height: 3),
                              Text(
                                isDone ? 'Completed ✓' : m.hint,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDone
                                      ? _kGreen.withValues(alpha: 0.8)
                                      : _kTextSec,
                                ),
                              ),
                            ] else if (isAutoStep) ...[
                              const SizedBox(height: 3),
                              const Text(
                                'Set automatically when meter is installed',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _kTextMut,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!isPending && !isAutoStep) ...[
                        const SizedBox(width: 8),
                        AppSvgIcon(
                          isActive
                              ? AppSvgAssets.chevronRight
                              : AppSvgAssets.pencil,
                          size: 13,
                          color: isActive ? m.color : _kTextMut,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Step form screen
// ─────────────────────────────────────────────────────────────────────────────
class _StepFormScreen extends StatefulWidget {
  final String leadId;
  final InstallationStatus step;
  final String customerName;

  const _StepFormScreen({
    required this.leadId,
    required this.step,
    required this.customerName,
  });

  @override
  State<_StepFormScreen> createState() => _StepFormScreenState();
}

class _StepFormScreenState extends State<_StepFormScreen> {
  final Map<String, TextEditingController> _ctrls = {};
  final Map<String, DateTime> _dates = {};
  final Map<String, String> _errors = {};

  final List<PickedPhoto> _sitePhotos = [];
  final List<PickedPhoto> _afterPhotos = [];

  final Map<String, bool?> _yesno = {};

  final _picker = ImagePicker();
  bool _uploadingPhotos = false;

  TextEditingController _c(String k) => _ctrls.putIfAbsent(k, () {
    final controller = TextEditingController();
    controller.addListener(() {
      if (!mounted || !_errors.containsKey(k)) return;
      setState(() => _errors.remove(k));
    });
    return controller;
  });
  DateTime? _d(String k) => _dates[k];
  String? _err(String k) => _errors[k];
  void _sd(String k, DateTime v) => setState(() {
    _dates[k] = v;
    _errors.remove(k);
  });

  @override
  void dispose() {
    for (final c in _ctrls.values) c.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos(
    List<PickedPhoto> target, {
    int max = 5,
    String? errorKey,
  }) async {
    if (target.length >= max) {
      if (mounted)
        AppFeedback.showError(context, 'Maximum $max photos allowed');
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add Photo',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _kText,
              ),
            ),
            const SizedBox(height: 8),
            if (!kIsWeb)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const AppSvgIcon(
                    AppSvgAssets.camera,
                    color: _kPurple,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Take Photo',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Use camera',
                  style: TextStyle(fontSize: 11),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _capturePhoto(
                    target,
                    ImageSource.camera,
                    max: max,
                    errorKey: errorKey,
                  );
                },
              ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const AppSvgIcon(
                  AppSvgAssets.images,
                  color: _kBlue,
                  size: 20,
                ),
              ),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Pick existing photo',
                style: TextStyle(fontSize: 11),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await _capturePhoto(
                  target,
                  ImageSource.gallery,
                  max: max,
                  errorKey: errorKey,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _capturePhoto(
    List<PickedPhoto> target,
    ImageSource source, {
    int max = 5,
    String? errorKey,
  }) async {
    try {
      final XFile? img = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (img != null && mounted) {
        final bytes = await img.readAsBytes();
        setState(() {
          target.add(PickedPhoto(bytes: bytes, filename: img.name));
          if (errorKey != null) _errors.remove(errorKey);
        });
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, 'Failed to pick photo: $e');
    }
  }

  void _removePhoto(List<PickedPhoto> target, int index) {
    setState(() => target.removeAt(index));
  }

  void _submit() {
    if (!mounted) return;

    final errors = <String, String>{};
    final extra = <String, dynamic>{};

    switch (widget.step) {
      case InstallationStatus.installationAssigned:
        final startDate = _dates['start_date'];
        if (startDate == null) {
          errors['start_date'] = 'Start Date is required';
        }
        if (errors.isEmpty) {
          extra['startDate'] = startDate!.toIso8601String();
          if (_sitePhotos.isNotEmpty) {
            extra['beforePhotos'] = _sitePhotos;
          }
          if (_c('team_name').text.isNotEmpty) {
            extra['teamName'] = _c('team_name').text.trim();
          }
          if (_c('notes').text.isNotEmpty) {
            extra['notes'] = _c('notes').text.trim();
          }
        }
        break;

      case InstallationStatus.installationStarted:
        final completionDate = _dates['completion_date'];
        final testing = _yesno['testing'];
        final customerSigned = _yesno['customer_signed'];
        if (completionDate == null) {
          errors['completion_date'] = 'Completion Date is required';
        }
        if (testing == null) {
          errors['testing'] = 'Please select if testing was done';
        }
        if (customerSigned == null) {
          errors['customer_signed'] = 'Please select if customer signature was received';
        }
        if (errors.isEmpty) {
          extra['installationDate'] = completionDate!.toIso8601String();
          extra['systemTested'] = testing == true;
          extra['customerSigned'] = customerSigned == true;
          if (_afterPhotos.isNotEmpty) {
            extra['afterPhotos'] = _afterPhotos;
          }
          if (_c('notes').text.isNotEmpty) {
            extra['notes'] = _c('notes').text.trim();
          }
          if (_yesno['structure_done'] != null) {
            extra['structureDone'] = _yesno['structure_done'] == true;
          }
          if (_yesno['wiring_done'] != null) {
            extra['wiringDone'] = _yesno['wiring_done'] == true;
          }
          if (_yesno['plume_done'] != null) {
            extra['plumeDone'] = _yesno['plume_done'] == true;
          }
          if (_yesno['inverter_done'] != null) {
            extra['inverterAcDone'] = _yesno['inverter_done'] == true;
          }
          if (_yesno['fully_complete'] != null) {
            extra['fullyComplete'] = _yesno['fully_complete'] == true;
          }
          if (_c('structure_vendor_name').text.isNotEmpty) {
            extra['structureVendorName'] = _c('structure_vendor_name').text.trim();
          }
          if (_dates['structure_completed_date'] != null) {
            extra['structureCompletedDate'] = _dates['structure_completed_date']!.toIso8601String();
          }
          if (_c('wiring_vendor_name').text.isNotEmpty) {
            extra['wiringVendorName'] = _c('wiring_vendor_name').text.trim();
          }
          if (_dates['wiring_completed_date'] != null) {
            extra['wiringCompletedDate'] = _dates['wiring_completed_date']!.toIso8601String();
          }
        }
        break;

      case InstallationStatus.installationCompleted:
        if (_c('application_number').text.isEmpty) {
          errors['application_number'] = 'Application Number is required';
        }
        final appDate = _dates['application_date'];
        if (appDate == null) {
          errors['application_date'] = 'Application Date is required';
        }
        if (errors.isEmpty) {
          extra['applicationNumber'] = _c('application_number').text.trim();
          extra['applicationDate'] = appDate!.toIso8601String();
        }
        break;

      case InstallationStatus.meterApplied:
        final inspDate = _dates['inspection_date'];
        if (inspDate == null) {
          errors['inspection_date'] = 'Inspection Date is required';
        }
        if (errors.isEmpty) {
          extra['inspectionDate'] = inspDate!.toIso8601String();
          if (_c('inspector_name').text.isNotEmpty) {
            extra['inspectorName'] = _c('inspector_name').text.trim();
          }
          if (_c('inspector_notes').text.isNotEmpty) {
            extra['inspectorNotes'] = _c('inspector_notes').text.trim();
          }
        }
        break;

      case InstallationStatus.meterInspection:
        if (_c('meter_number').text.isEmpty) {
          errors['meter_number'] = 'Meter Number is required';
        }
        final meterDate = _dates['meter_install_date'];
        if (meterDate == null) {
          errors['meter_install_date'] = 'Meter Installation Date is required';
        }
        if (errors.isEmpty) {
          extra['meterNumber'] = _c('meter_number').text.trim();
          extra['installedDate'] = meterDate!.toIso8601String();
        }
        break;

      default:
        break;
    }

    if (errors.isNotEmpty) {
      setState(() {
        _errors
          ..clear()
          ..addAll(errors);
      });
      return;
    }

    context.read<InstallationCubit>().updateStatus(
      installationId: widget.leadId,
      status: _nextStep(widget.step),
      extra: extra,
    );
  }

  Future<void> _pickDate(
    String key, {
    DateTime? first,
    DateTime? last,
    DateTime? initial,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? _d(key) ?? DateTime.now(),
      firstDate: first ?? DateTime(2020),
      lastDate: last ?? DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _kPurple)),
        child: child!,
      ),
    );
    if (picked != null && mounted) _sd(key, picked);
  }

  @override
  Widget build(BuildContext context) {
    final m = _kMeta[widget.step]!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const AppSvgIcon(
            AppSvgAssets.chevronLeft,
            size: 18,
            color: _kText,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              m.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _kText,
              ),
            ),
            Text(
              'Step ${m.n} of 2  •  ${widget.customerName}',
              style: const TextStyle(fontSize: 10.5, color: _kTextMut),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: m.n / 2,
            backgroundColor: _kBorder,
            valueColor: AlwaysStoppedAnimation(m.color),
            minHeight: 3,
          ),
        ),
      ),
      body: BlocConsumer<InstallationCubit, InstallationState>(
        listener: (ctx, state) {
          if (!ctx.mounted) return;

          if (state is InstallationActionSuccess) {
            final updatedStep = _nextStep(widget.step);
            Navigator.pop(ctx, updatedStep);
          }

          if (state is InstallationError) {
            AppFeedback.showError(ctx, 'Failed: ${state.message}');
          }
        },
        builder: (ctx, state) {
          final loading = state is InstallationLoading || _uploadingPhotos;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._fields(m.color),
                const SizedBox(height: 24),
                _SubmitBtn(
                  label: _submitLabel(),
                  color: m.color,
                  loading: loading,
                  success: false,
                  onPressed: _submit,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _submitLabel() {
    switch (widget.step) {
      case InstallationStatus.installationAssigned:
        return 'Mark Installation Started';
      case InstallationStatus.installationStarted:
        return 'Mark Installation Completed';
      case InstallationStatus.installationCompleted:
        return 'Submit Meter Application';
      case InstallationStatus.meterApplied:
        return 'Confirm Inspection Done';
      case InstallationStatus.meterInspection:
        return 'Confirm Meter Installed ✓';
      case InstallationStatus.meterInstalled:
        return 'Project Completed 🏆';
      case InstallationStatus.projectCompleted:
        return 'Project Completed';
    }
  }

  List<Widget> _fields(Color color) {
    switch (widget.step) {
      case InstallationStatus.installationAssigned:
        return [
          _note(
            'Confirm arrival on site and capture before photos before starting installation.',
            color,
          ),
          _sec('Installation Started'),
          _txt(
            'team_name',
            'Technician / Team Name',
            hint: 'Name of the installation team or engineer',
          ),
          _datePicker(
            'start_date',
            'Installation Started On',
            color,
            required: true,
            last: DateTime.now().add(const Duration(days: 1)),
          ),
          _photoPickerSection(
            label: 'Before Installation Photos',
            hint: 'Capture site condition before installation begins',
            photos: _sitePhotos,
            color: color,
            icon: AppSvgAssets.camera,
            onAdd: () => _pickPhotos(_sitePhotos, max: 5),
            onRemove: (i) => _removePhoto(_sitePhotos, i),
            maxCount: 5,
          ),
          _txt(
            'notes',
            'Notes about installation start...',
            hint: 'Enter arrival or site notes',
            area: true,
          ),
        ];

      case InstallationStatus.installationStarted:
        return [
          _note(
            'Complete the final installation checklist, capture after photos, and confirm system testing.',
            color,
          ),
          _sec('Completion Checklist'),
          _yesNoSelector(
            key: 'structure_done',
            label: 'Structure Done',
            color: color,
          ),
          const SizedBox(height: 8),
          _yesNoSelector(
            key: 'wiring_done',
            label: 'Wiring Done',
            color: color,
          ),
          const SizedBox(height: 8),
          _yesNoSelector(
            key: 'plume_done',
            label: 'Plume Done',
            color: color,
          ),
          const SizedBox(height: 8),
          _yesNoSelector(
            key: 'inverter_done',
            label: 'Inverter / AC / DC Done',
            color: color,
          ),
          const SizedBox(height: 8),
          _yesNoSelector(
            key: 'fully_complete',
            label: 'Fully Project Complete',
            color: color,
          ),
          const SizedBox(height: 10),
          _sec('System Verification'),
          _yesNoSelector(
            key: 'testing',
            label: 'System Tested & Working',
            color: color,
            required: true,
          ),
          const SizedBox(height: 8),
          _yesNoSelector(
            key: 'customer_signed',
            label: 'Customer Signature Received',
            color: color,
            required: true,
          ),
          const SizedBox(height: 12),
          _sec('Vendor Details'),
          _txt(
            'structure_vendor_name',
            'Structure Vendor Name',
            hint: 'Optional vendor/company name',
          ),
          const SizedBox(height: 8),
          _datePicker(
            'structure_completed_date',
            'Structure Completed Date',
            color,
          ),
          const SizedBox(height: 10),
          _txt(
            'wiring_vendor_name',
            'Wiring Vendor Name',
            hint: 'Optional wiring vendor name',
          ),
          const SizedBox(height: 8),
          _datePicker(
            'wiring_completed_date',
            'Wiring Completed Date',
            color,
          ),
          const SizedBox(height: 10),
          _photoPickerSection(
            label: 'After Installation Photos',
            hint: 'Capture panels, wiring, inverter and final installed system',
            photos: _afterPhotos,
            color: color,
            icon: AppSvgAssets.camera,
            onAdd: () =>
                _pickPhotos(_afterPhotos, max: 8, errorKey: 'after_photos'),
            onRemove: (i) => _removePhoto(_afterPhotos, i),
            maxCount: 8,
          ),
          _sec('Completion Date'),
          _datePicker(
            'completion_date',
            'Installation Completed On',
            color,
            required: true,
          ),
          _txt(
            'notes',
            'Notes about installation completion...',
            hint: 'Enter final remarks or handover notes',
            area: true,
          ),
        ];

      case InstallationStatus.installationCompleted:
        return [
          _sec('Application Details'),
          _txt(
            'application_number',
            'Application Number',
            hint: 'e.g. DGVCL-2024-001',
            req: true,
          ),
          _datePicker(
            'application_date',
            'Application Date',
            color,
            required: true,
          ),
        ];

      case InstallationStatus.meterApplied:
        return [
          _sec('Inspection Details'),
          _datePicker(
            'inspection_date',
            'Inspection Date',
            color,
            required: true,
          ),
          _txt(
            'inspector_name',
            'Inspector Name',
            hint: 'From electricity dept',
          ),
          _txt(
            'inspector_notes',
            "Inspector's Notes",
            hint: 'Observations…',
            area: true,
          ),
        ];

      case InstallationStatus.meterInspection:
        return [
          _note(
            '🎉 Final step! Meter installed = project auto-completed.',
            color,
          ),
          _sec('Meter Details'),
          _txt(
            'meter_number',
            'Meter Number',
            hint: 'e.g. MET-2024-456',
            req: true,
          ),
          _datePicker(
            'meter_install_date',
            'Meter Installation Date',
            color,
            required: true,
          ),
        ];

      case InstallationStatus.meterInstalled:
      case InstallationStatus.projectCompleted:
        return [
          _note('Project has been marked complete automatically.', color),
        ];
    }
  }

  Widget _photoPickerSection({
    required String label,
    required String hint,
    required List<PickedPhoto> photos,
    required Color color,
    required String icon,
    required VoidCallback onAdd,
    required void Function(int) onRemove,
    required int maxCount,
    bool required = false,
    String? errorKey,
  }) {
    final errorText = errorKey == null ? null : _err(errorKey);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: label.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _kTextMut,
                          letterSpacing: 0.8,
                        ),
                        children: [
                          if (required)
                            const TextSpan(
                              text: ' *',
                              style: TextStyle(
                                color: _kRed,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hint,
                      style: const TextStyle(fontSize: 11, color: _kTextSec),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${photos.length}/$maxCount',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (photos.isNotEmpty) ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: photos.length,
              itemBuilder: (ctx, i) =>
                  _photoTile(photos[i], () => onRemove(i), color),
            ),
            const SizedBox(height: 8),
          ],
          if (photos.length < maxCount)
            GestureDetector(
              onTap: onAdd,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: photos.isEmpty ? 100 : 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: errorText != null
                        ? _kRed
                        : color.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: AppSvgIcon(icon, color: color, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Photo',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                        if (photos.isEmpty)
                          Text(
                            'Camera or gallery  •  Max $maxCount photos',
                            style: const TextStyle(
                              fontSize: 10,
                              color: _kTextMut,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _kGreen.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kGreen.withValues(alpha: 0.2)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppSvgIcon(
                    AppSvgAssets.circleCheckBig,
                    color: _kGreen,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Maximum photos added',
                    style: TextStyle(
                      fontSize: 12,
                      color: _kGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          if (errorText != null) _fieldError(errorText),
        ],
      ),
    );
  }

  Widget _fieldError(String text) => Padding(
    padding: const EdgeInsets.only(top: 6, left: 2),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        color: _kRed,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _photoTile(PickedPhoto photo, VoidCallback onRemove, Color color) =>
      Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              Uint8List.fromList(photo.bytes),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  shape: BoxShape.circle,
                ),
                child: const AppSvgIcon(
                  AppSvgAssets.x,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const AppSvgIcon(
                AppSvgAssets.camera,
                color: Colors.white,
                size: 10,
              ),
            ),
          ),
        ],
      );

  Widget _sec(String text) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 10),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: _kTextMut,
        letterSpacing: 1,
      ),
    ),
  );

  Widget _note(String text, Color color) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.06),
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(10),
        bottomRight: Radius.circular(10),
      ),
      border: Border(left: BorderSide(color: color, width: 3)),
    ),
    child: Row(
      children: [
        const Text('💡 ', style: TextStyle(fontSize: 13)),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11.5, color: _kTextSec),
          ),
        ),
      ],
    ),
  );

  Widget _datePicker(
    String key,
    String label,
    Color color, {
    bool required = false,
    DateTime? first,
    DateTime? last,
  }) {
    final picked = _d(key);
    final errorText = _err(key);
    final display = picked == null
        ? 'Tap to select date'
        : '${picked.day.toString().padLeft(2, '0')} / '
              '${picked.month.toString().padLeft(2, '0')} / '
              '${picked.year}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: RichText(
              text: TextSpan(
                text: label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: _kTextMut,
                  letterSpacing: 0.8,
                ),
                children: [
                  if (required)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: _kRed,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _pickDate(key, first: first, last: last),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: picked != null
                    ? color.withValues(alpha: 0.05)
                    : const Color(0xFFFAFCFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: errorText != null
                      ? _kRed
                      : picked != null
                      ? color
                      : _kBorder,
                  width: picked != null ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: (picked != null ? color : _kTextMut).withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: AppSvgIcon(
                      AppSvgAssets.calendarDays,
                      size: 16,
                      color: picked != null ? color : _kTextMut,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      display,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: picked != null
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: picked != null ? color : _kTextMut,
                      ),
                    ),
                  ),
                  if (picked != null)
                    GestureDetector(
                      onTap: () => setState(() => _dates.remove(key)),
                      child: const AppSvgIcon(
                        AppSvgAssets.x,
                        size: 16,
                        color: _kTextMut,
                      ),
                    )
                  else
                    const AppSvgIcon(
                      AppSvgAssets.chevronRight,
                      size: 18,
                      color: _kTextMut,
                    ),
                ],
              ),
            ),
          ),
          if (errorText != null) _fieldError(errorText),
        ],
      ),
    );
  }


  Widget _txt(
    String key,
    String label, {
    String? hint,
    bool req = false,
    bool area = false,
    TextInputType kb = TextInputType.text,
  }) {
    final errorText = _err(key);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: _kTextMut,
                letterSpacing: 0.8,
              ),
              children: [
                if (req)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: _kRed, fontWeight: FontWeight.w900),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _c(key),
            maxLines: area ? 3 : 1,
            keyboardType: kb,
            style: const TextStyle(fontSize: 13.5, color: _kText),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: _kTextMut, fontSize: 13),
              errorText: errorText,
              errorStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: const Color(0xFFFAFCFF),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: errorText != null ? _kRed : _kBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: errorText != null ? _kRed : _kPurple,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kRed),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kRed, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _yesNoSelector({
    required String key,
    required String label,
    Color color = _kPurple,
    bool required = false,
  }) {
    final value = _yesno[key];
    final errorText = _err(key);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RichText(
              text: TextSpan(
                text: label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: _kTextMut,
                  letterSpacing: 0.8,
                ),
                children: [
                  if (required)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: _kRed,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _yesno[key] = true;
                    _errors.remove(key);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: value == true
                          ? _kGreen.withValues(alpha: 0.1)
                          : AppColors.bgSecondary),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: value == true
                            ? _kGreen
                            : errorText != null
                            ? _kRed
                            : _kBorder,
                        width: value == true ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (value == true) ...[
                          const AppSvgIcon(
                            AppSvgAssets.check,
                            color: _kGreen,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          'Yes',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: value == true ? _kGreen : _kTextSec,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _yesno[key] = false;
                    _errors.remove(key);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: value == false
                          ? _kRed.withValues(alpha: 0.08)
                          : AppColors.bgSecondary),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: value == false
                            ? _kRed
                            : errorText != null
                            ? _kRed
                            : _kBorder,
                        width: value == false ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (value == false) ...[
                          const AppSvgIcon(
                            AppSvgAssets.x,
                            color: _kRed,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          'No',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: value == false ? _kRed : _kTextSec,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (errorText != null) _fieldError(errorText),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Submit button
// ─────────────────────────────────────────────────────────────────────────────
class _SubmitBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool loading, success;
  final VoidCallback onPressed;

  const _SubmitBtn({
    required this.label,
    required this.color,
    required this.loading,
    required this.success,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bg = success
        ? _kGreen
        : loading
        ? color.withValues(alpha: 0.55)
        : color;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bg, bg.withValues(alpha: 0.82)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.38),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: (loading || success) ? null : onPressed,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                else if (success)
                  const AppSvgIcon(
                    AppSvgAssets.check,
                    color: Colors.white,
                    size: 20,
                  )
                else
                  const AppSvgIcon(
                    AppSvgAssets.chevronRight,
                    color: Colors.white,
                    size: 18,
                  ),
                const SizedBox(width: 8),
                Text(
                  success ? 'Updated!' : label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
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

// ─────────────────────────────────────────────────────────────────────────────
// Floating Update Status bar
// ─────────────────────────────────────────────────────────────────────────────
class _UpdateStatusBar extends StatelessWidget {
  final InstallationStatus currentStatus;
  final Color accent;
  final VoidCallback onTap;

  const _UpdateStatusBar({
    required this.currentStatus,
    required this.accent,
    required this.onTap,
  });

  String get _nextLabel {
    switch (currentStatus) {
      case InstallationStatus.installationAssigned:
        return 'Mark Installation Started';
      case InstallationStatus.installationStarted:
        return 'Mark Installation Completed';
      case InstallationStatus.installationCompleted:
        return 'Submit Meter Application';
      case InstallationStatus.meterApplied:
        return 'Confirm Inspection Done';
      case InstallationStatus.meterInspection:
        return 'Confirm Meter Installed ✓';
      case InstallationStatus.meterInstalled:
        return 'Project Completed 🏆';
      case InstallationStatus.projectCompleted:
        return 'Project Completed 🏆';
    }
  }

  String get _currentLabel {
    switch (currentStatus) {
      case InstallationStatus.installationAssigned:
        return 'Installation Assigned';
      case InstallationStatus.installationStarted:
        return 'Installation Started';
      case InstallationStatus.installationCompleted:
        return 'Installation Done';
      case InstallationStatus.meterApplied:
        return 'Meter Applied';
      case InstallationStatus.meterInspection:
        return 'Meter Inspection';
      case InstallationStatus.meterInstalled:
        return 'Meter Installed';
      case InstallationStatus.projectCompleted:
        return 'Project Completed';
    }
  }

  String get _icon {
    switch (currentStatus) {
      case InstallationStatus.installationAssigned:
        return AppSvgAssets.cog;
      case InstallationStatus.installationStarted:
        return AppSvgAssets.zap;
      case InstallationStatus.installationCompleted:
        return AppSvgAssets.clipboardList;
      case InstallationStatus.meterApplied:
        return AppSvgAssets.search;
      case InstallationStatus.meterInspection:
        return AppSvgAssets.gauge;
      case InstallationStatus.meterInstalled:
        return AppSvgAssets.trophy;
      case InstallationStatus.projectCompleted:
        return AppSvgAssets.pencil;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppSvgIcon(AppSvgAssets.circle, size: 7, color: accent),
                    const SizedBox(width: 5),
                    Text(
                      'Current: $_currentLabel',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Text(
                'Tap to update →',
                style: TextStyle(
                  fontSize: 10,
                  color: _kTextMut,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent, accent.withValues(alpha: 0.82)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppSvgIcon(_icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    _nextLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const AppSvgIcon(
                    AppSvgAssets.chevronRight,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}




