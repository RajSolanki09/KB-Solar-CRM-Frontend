// lib/screens/Dashboards/Installation_Dashboard/MyInstallations/sprinkler_installation_detail_screen.dart
//
// ── How API calls work ────────────────────────────────────────────────────────
// This screen calls SprinklerLeadCubit methods directly:
//
//   installationStarted   → cubit.startInstallation(leadId, notes, photos)
//                           → PUT /sprinkler_lead/:id/installation-start
//
//   installationCompleted → cubit.completeInstallation(leadId, ...)
//                           → PUT /sprinkler_lead/:id/installation-complete
//
//   systemTested          → cubit.completeInstallation(leadId, systemTested: true, notes)
//                           → PUT /sprinkler_lead/:id/system-tested
//                           Backend auto-sets projectCompleted = true
//
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:solar_project/Cubits/Installation/installation_cubit.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart';
import 'package:solar_project/Cubits/SprinklerLeads/sprinkler_leads_state.dart';
import 'package:solar_project/Helper/picked_photo.dart';
import 'package:solar_project/Helper/common_widgets.dart';
import 'package:solar_project/data/Models/sprinkler_lead_model.dart';
import 'package:solar_project/Helper/app_feedback.dart';
import 'package:solar_project/Helper/app_svg_icon.dart';
import 'package:solar_project/screens/Dashboards/Leads/Sprinkler/Steps/spk_installation_completed_screen.dart';
import 'package:solar_project/screens/Dashboards/Leads/Sprinkler/Steps/spk_installation_started_screen.dart';
import 'package:solar_project/Helper/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Palette
// ─────────────────────────────────────────────────────────────────────────────
const _kBlue = Color(0xFF0EA5E9);
const _kGreen = AppColors.success);
const _kRed = AppColors.error);
const _kBg = AppColors.bgSecondary);
const _kText = AppColors.textPrimary);
const _kTextSec = AppColors.textSecondary);
const _kTextMut = AppColors.textTertiary);
const _kBorder = AppColors.borderLight);

// ─────────────────────────────────────────────────────────────────────────────
// Pipeline — 3 visible steps for installation users.
// ─────────────────────────────────────────────────────────────────────────────
const _kAllSteps = [
  SprinklerStep.installationStarted,
  SprinklerStep.installationCompleted,
  SprinklerStep.projectCompleted,
];

String _stepLabel(SprinklerStep s) {
  switch (s) {
    case SprinklerStep.installationStarted:
      return 'Installation Started';
    case SprinklerStep.installationCompleted:
      return 'Installation Completed';
    case SprinklerStep.projectCompleted:
      return 'Project Complete 🏆';
    default:
      return sprinklerStepToDisplay(s);
  }
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

const _kMeta = <SprinklerStep, _SM>{
  SprinklerStep.installationStarted: _SM(
    '🏗️',
    'Installation Started',
    'Capture arrival details and before-work photos',
    _kBlue,
    1,
  ),
  SprinklerStep.installationCompleted: _SM(
    '🏁',
    'Installation Completed',
    'Submit completion details and final photos',
    _kGreen,
    2,
  ),
  SprinklerStep.projectCompleted: _SM(
    '🏆',
    'Project Completed',
    'Auto-completed after installation completion',
    _kGreen,
    3,
  ),
};

// ─────────────────────────────────────────────────────────────────────────────
// Public screen
// ─────────────────────────────────────────────────────────────────────────────
class SprinklerInstallationDetailScreen extends StatefulWidget {
  final SprinklerLeadModel lead;
  const SprinklerInstallationDetailScreen({super.key, required this.lead});

  @override
  State<SprinklerInstallationDetailScreen> createState() =>
      _SprinklerInstallationDetailScreenState();
}

class _SprinklerInstallationDetailScreenState
    extends State<SprinklerInstallationDetailScreen> {
  late SprinklerStep _currentStep;
  late SprinklerLeadModel _lead;
  late bool _projectCompleted;

  @override
  void initState() {
    super.initState();
    _lead = widget.lead;
    _currentStep = _normalizeStep(_lead.currentStep);
    _projectCompleted =
        _lead.isCompleted ||
        _lead.currentStep == SprinklerStep.projectCompleted ||
        _lead.currentStep.index >= SprinklerStep.installationCompleted.index;
  }

  SprinklerStep _normalizeStep(SprinklerStep step) {
    if (step == SprinklerStep.installationAssigned) {
      return SprinklerStep.installationStarted;
    }
    if (step.index >= SprinklerStep.installationCompleted.index) {
      return SprinklerStep.installationCompleted;
    }
    return step;
  }

  SprinklerStep _nextActionStep() {
    if (_lead.currentStep == SprinklerStep.installationAssigned) {
      return SprinklerStep.installationStarted;
    }
    if (_lead.currentStep == SprinklerStep.installationStarted) {
      return SprinklerStep.installationCompleted;
    }
    return _normalizeStep(_lead.currentStep);
  }

  // ── mirrors solar's _openForm exactly ─────────────────────────────────────
  Future<void> _openForm(SprinklerStep step, {bool allowNextStep = false}) async {
    final installationCubit = context.read<InstallationCubit>();
    final sprinklerCubit = context.read<SprinklerLeadCubit>();
    final targetStep = _normalizeStep(step);

    // 1. Lock if project is already completed
    if (_projectCompleted) return;

    // 2. Only allow tapping current or past steps
    final stepIdx = _kAllSteps.indexOf(targetStep);
    final currentIdx = _kAllSteps.indexOf(
      _projectCompleted
          ? SprinklerStep.projectCompleted
          : _normalizeStep(_currentStep),
    );
    if (stepIdx < 0 || currentIdx < 0) return;
    if (!allowNextStep && stepIdx > currentIdx) return;
    if (allowNextStep && stepIdx > currentIdx + 1) return;

    final updated = await Navigator.push<SprinklerLeadModel>(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [BlocProvider.value(value: sprinklerCubit)],
          child: targetStep == SprinklerStep.installationStarted
              ? SpkInstallationStartedScreen(lead: _lead)
              : targetStep == SprinklerStep.installationCompleted
              ? SpkInstallationCompleteScreen(lead: _lead)
              : _SpkStepFormScreen(lead: _lead, step: targetStep),
        ),
      ),
    );

    // ✅ Child popped with result — show success on THIS scaffold (still alive)
    if (updated != null && mounted) {
      final wasCompleted = _projectCompleted;
      setState(() {
        _lead = updated;
        _currentStep = _normalizeStep(updated.currentStep);
        _projectCompleted =
            updated.isCompleted ||
            updated.currentStep == SprinklerStep.projectCompleted ||
            updated.currentStep.index >=
                SprinklerStep.installationCompleted.index;
      });

      AppFeedback.showSuccess(context, 'Status updated successfully!');

      if (!mounted) return;

      // ✅ Show updated pipeline for 1.2 seconds, then auto-redirect back
      Future.delayed(const Duration(milliseconds: 1200), () async {
            if (mounted) {
            try {
              await Future.wait([
                installationCubit.fetchInstallations(),
                sprinklerCubit.fetchAllLeads(),
              ]);
              if (mounted) safePop(context);
            } catch (_) {}
          }
      });

      // Show completion dialog if project just completed
      if (!wasCompleted && _projectCompleted) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _showCompletionDialog();
        });
      }
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
              "${_lead.customerName}'s sprinkler installation is fully complete.\nAdmin has been notified.",
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
              // Close completion dialog then the detail page safely
              safePop(context);
              safePop(context);
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
      body: BlocListener<SprinklerLeadCubit, SprinklerLeadState>(
        // ✅ Parent only cares about errors — SprinklerLeadSaved is handled
        // exclusively by the child form via Navigator.pop(context, lead).
        listenWhen: (prev, curr) => curr is SprinklerLeadError,
        listener: (ctx, state) {
          if (!mounted) return;
          if (state is SprinklerLeadError) {
            ScaffoldMessenger.of(context).showSnackBar(
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
        },
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 210,
                  backgroundColor: _kBlue,
                  leading: IconButton(
                    icon: const AppSvgIcon(
                      AppSvgAssets.chevronLeft,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  flexibleSpace: FlexibleSpaceBar(background: _hero()),
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
                  currentStep: _currentStep,
                  onTap: () => _openForm(_nextActionStep(), allowNextStep: true),
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
        colors: [AppColors.success), Color(0xFF059669)],
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
                'All installation steps done. Completed projects are locked for editing.',
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
        colors: [_kBlue, _kBlue.withValues(alpha: 0.78)],
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
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _heroBadge('💧  Sprinkler Project'),
                const SizedBox(height: 8),
                Text(
                  _lead.customerName,
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
                      _lead.phone,
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
                        _lead.village.isNotEmpty
                            ? '${_lead.address}, ${_lead.village}'
                            : _lead.address,
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
                    if (_lead.farmSize != null)
                      _heroBadge(
                        '🌾 ${_lead.farmSize!.toStringAsFixed(0)} acres',
                      ),
                    if (_lead.waterSource != null)
                      _heroBadge('💧 ${_lead.waterSource}'),
                    if (_lead.cropType != null)
                      _heroBadge('🌱 ${_lead.cropType}'),
                    if (_lead.effectiveInstallerNamesString != null)
                      _heroBadge('👤 ${_lead.effectiveInstallerNamesString}'),
                  ],
                ),
                if (_lead.installationAssignData.notes?.trim().isNotEmpty ??
                    false) ...[
                  const SizedBox(height: 10),
                  _heroNote(_lead.installationAssignData.notes!.trim()),
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
                    '${_kMeta[_currentStep]?.emoji ?? '💧'}  ${_stepLabel(_currentStep)}',
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
          color: _kBlue,
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

  // ── Pipeline card ──────────────────────────────────────────────────────────
  Widget _pipelineCard() {
    // Treat completion or later backend states as project completed for this dashboard.
    final effectiveStep = _projectCompleted
      ? SprinklerStep.projectCompleted
        : _normalizeStep(_currentStep);
    final currentIdx = _kAllSteps.indexOf(effectiveStep);

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
        children: _kAllSteps.asMap().entries.map((e) {
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
            isAutoStep: step == SprinklerStep.projectCompleted,
            onTap: (_projectCompleted || isPending)
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
  final SprinklerStep step;
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
    final lineColor = isDone ? const Color(0xFFA7F3D0) : _kBorder;
    final stepNum = _kAllSteps.indexOf(step) + 1;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Timeline spine ───────────────────────────────────────────────
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

          // ── Content card ─────────────────────────────────────────────────
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
                        ? AppColors.successLight).withValues(alpha: 0.55)
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
                                          ? const Color(0xFF065F46)
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
                                'Set automatically when system is tested',
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
class _SpkStepFormScreen extends StatefulWidget {
  final SprinklerLeadModel lead;
  final SprinklerStep step;
  const _SpkStepFormScreen({required this.lead, required this.step});

  @override
  State<_SpkStepFormScreen> createState() => _SpkStepFormScreenState();
}

class _SpkStepFormScreenState extends State<_SpkStepFormScreen> {
  final Map<String, TextEditingController> _ctrls = {};
  final Map<String, bool> _flags = {};
  final Map<String, DateTime> _dates = {};
  final Map<String, String> _errors = {};

  // ── Photo storage ──────────────────────────────────────────────────────────
  // Step 1 (installationAssigned): before-work site photos
  final List<PickedPhoto> _beforePhotos = [];

  final _picker = ImagePicker();

  TextEditingController _c(String k) => _ctrls.putIfAbsent(k, () {
    final controller = TextEditingController();
    controller.addListener(() {
      if (!mounted || !_errors.containsKey(k)) return;
      setState(() => _errors.remove(k));
    });
    return controller;
  });

  bool _f(String k) => _flags[k] ?? false;
  DateTime? _d(String k) => _dates[k];
  String? _err(String k) => _errors[k];
  void _sf(String k, bool v) => setState(() {
    _flags[k] = v;
    _errors.remove(k);
  });
  void _sd(String k, DateTime v) => setState(() {
    _dates[k] = v;
    _errors.remove(k);
  });

  @override
  void dispose() {
    for (final c in _ctrls.values) c.dispose();
    super.dispose();
  }

  void _submit() {
    if (!mounted) return;

    final errors = <String, String>{};
    final cubit = context.read<SprinklerLeadCubit>();

    switch (widget.step) {
      case SprinklerStep.installationAssigned:
        if (_d('start_date') == null) {
          errors['start_date'] = 'Start Date is required';
        }
        if (errors.isNotEmpty) {
          setState(() {
            _errors
              ..clear()
              ..addAll(errors);
          });
          return;
        }

        var startedAt = _d('start_date')!;
        final arrivalText = _c('arrival_time').text;
        if (arrivalText.isNotEmpty) {
          final parts = arrivalText.split(':');
          if (parts.length == 2) {
            final hour = int.tryParse(parts[0]) ?? 0;
            final minute = int.tryParse(parts[1]) ?? 0;
            startedAt = DateTime(
              startedAt.year,
              startedAt.month,
              startedAt.day,
              hour,
              minute,
            );
          }
        }

        cubit.saveInstallationStarted(
          widget.lead.id,
          startedAt: startedAt,
          notes: _c('notes').text.isNotEmpty ? _c('notes').text : null,
          beforePhotos: List<PickedPhoto>.from(_beforePhotos),
        );
        break;

      // case SprinklerStep.installationStarted:
      //   if (_d('completion_date') == null) {
      //     errors['completion_date'] = 'Completion Date is required';
      //   }
      //   if (errors.isNotEmpty) {
      //     setState(() {
      //       _errors
      //         ..clear()
      //         ..addAll(errors);
      //     });
      //     return;
      //   }
      //   cubit.completeInstallation(
      //     widget.lead.id,
      //     technicianName: _c('technician_name').text.isNotEmpty
      //         ? _c('technician_name').text
      //         : null,
      //     installationDate: _d('completion_date'),
      //     materialUsed: _c('material_used').text.isNotEmpty
      //         ? _c('material_used').text
      //         : null,
      //     extraMaterial: _c('extra_material').text.isNotEmpty
      //         ? _c('extra_material').text
      //         : null,
      //     workNotes: _c('work_notes').text.isNotEmpty
      //         ? _c('work_notes').text
      //         : null,
      //     notes: _c('notes').text.isNotEmpty ? _c('notes').text : null,
      //     photos: List<PickedPhoto>.from(_afterPhotos),
      //   );
      //   break;

      case SprinklerStep.installationCompleted:
        final allChecksDone =
            _f('pressure_ok') &&
            _f('all_sprinklers_working') &&
            _f('demo_given');
        if (!allChecksDone) {
          errors['system_checks'] =
              'Please complete all required system test checks';
        }
        if (errors.isNotEmpty) {
          setState(() {
            _errors
              ..clear()
              ..addAll(errors);
          });
          return;
        }
        cubit.completeInstallation(
          widget.lead.id,
          systemTested: true,
          notes: _c('notes').text.isNotEmpty ? _c('notes').text : null,
        );
        break;

      default:
        break;
    }
  }

  Future<void> _pickDate(String key, {DateTime? first, DateTime? last}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _d(key) ?? DateTime.now(),
      firstDate: first ?? DateTime(2020),
      lastDate: last ?? DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _kBlue)),
        child: child!,
      ),
    );
    if (picked != null && mounted) _sd(key, picked);
  }

  Future<void> _pickTime(String key) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _kBlue)),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _c(key).text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  // ── Photo picker helpers ──────────────────────────────────────────────────
  Future<void> _pickPhotos(
    List<PickedPhoto> target, {
    int max = 5,
    String? errorKey,
  }) async {
    if (target.length >= max) {
      if (mounted) {
        AppFeedback.showError(context, 'Maximum $max photos allowed');
      }
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
                    color: _kBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const AppSvgIcon(
                    AppSvgAssets.camera,
                    color: _kBlue,
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
              'Step ${m.n} of 3  •  ${widget.lead.customerName}',
              style: const TextStyle(fontSize: 10.5, color: _kTextMut),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: m.n / 3,
            backgroundColor: _kBorder,
            valueColor: AlwaysStoppedAnimation(m.color),
            minHeight: 3,
          ),
        ),
      ),
      body: BlocConsumer<SprinklerLeadCubit, SprinklerLeadState>(
        // ✅ Always re-listen on SprinklerLeadSaved — prevents Equatable
        // deduplication from silently swallowing the state when the same
        // lead object is saved twice in a session.
        listenWhen: (prev, curr) =>
            curr is SprinklerLeadSaved || curr is SprinklerLeadError,
        listener: (ctx, state) {
          // ── Guard: do nothing if widget is no longer in the tree ──────────
          if (!mounted) return;

          if (state is SprinklerLeadSaved) {
            // ✅ Pop using the widget's own `context` (not the BlocConsumer's
            // internal `ctx`) so the Navigator reference is always valid.
            // No snackbar here — the parent _openForm() shows success.
            Navigator.of(context).pop(state.lead);
          }
          if (state is SprinklerLeadError) {
            AppFeedback.showError(context, 'Failed: ${state.message}');
          }
        },
        builder: (ctx, state) {
          final loading = state is SprinklerLeadLoading;
          const success = false;
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
                  success: success,
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
      case SprinklerStep.installationAssigned:
        return 'Mark Installation Started';
      // case SprinklerStep.installationStarted:
      //   return 'Mark Installation Completed';
      case SprinklerStep.installationCompleted:
        return 'Mark System Tested ✓';
      default:
        return 'Submit';
    }
  }

  List<Widget> _fields(Color color) {
    switch (widget.step) {
      case SprinklerStep.installationAssigned:
        return [
          _note('Confirm arrival on site. Capture before-work photos.', color),
          _sec('Arrival Details'),
          _datePicker(
            'start_date',
            'Start Date',
            color,
            required: true,
            last: DateTime.now().add(const Duration(days: 1)),
          ),
          _timePicker('arrival_time', 'Arrival Time', color),
          _txt(
            'notes',
            'Notes',
            hint: 'Any observations before starting...',
            area: true,
          ),
          _photoPickerSection(
            label: 'Before-Work Photos',
            hint: 'Capture site condition before installation begins',
            photos: _beforePhotos,
            color: color,
            icon: AppSvgAssets.camera,
            onAdd: () => _pickPhotos(_beforePhotos, max: 5),
            onRemove: (i) => _removePhoto(_beforePhotos, i),
            maxCount: 5,
          ),
        ];

      // case SprinklerStep.installationStarted:
      //   return [
      //     _note('Complete sprinkler system setup before submitting.', color),
      //     _sec('Completion Details'),
      //     _datePicker(
      //       'completion_date',
      //       'Completion Date',
      //       color,
      //       required: true,
      //       last: DateTime.now().add(const Duration(days: 1)),
      //     ),
      //     _txt('technician_name', 'Technician Name', hint: 'Full name'),
      //     _sec('Materials'),
      //     _txt(
      //       'material_used',
      //       'Material Used',
      //       hint: 'Pipes, sprinklers, fittings...',
      //       area: true,
      //     ),
      //     _txt(
      //       'extra_material',
      //       'Extra Material',
      //       hint: 'Additional items used...',
      //     ),
      //     _sec('Work Notes'),
      //     _txt(
      //       'work_notes',
      //       'Work Notes',
      //       hint: 'Installation details...',
      //       area: true,
      //     ),
      //     _txt('notes', 'Additional Notes', hint: 'Any other observations...'),
      //     _photoPickerSection(
      //       label: 'After-Work Photos',
      //       hint: 'Sprinkler setup, pipe layout, motor/pump photos',
      //       photos: _afterPhotos,
      //       color: color,
      //       icon: AppSvgAssets.camera,
      //       onAdd: () => _pickPhotos(_afterPhotos, max: 5),
      //       onRemove: (i) => _removePhoto(_afterPhotos, i),
      //       maxCount: 5,
      //     ),
      //   ];

      case SprinklerStep.installationCompleted:
        return [
          _note(
            '🎉 Final step! System tested = project auto-completed.',
            color,
          ),
          _sec('System Test'),
          _check('pressure_ok', 'Water Pressure OK ✓', required: true),
          _check(
            'all_sprinklers_working',
            'All Sprinklers Working ✓',
            required: true,
          ),
          _check('demo_given', 'Customer Demo Given ✓', required: true),
          if (_err('system_checks') != null)
            _fieldError(_err('system_checks')!),
          _sec('Notes'),
          _txt(
            'notes',
            'Test Notes',
            hint: 'Water pressure, coverage, customer feedback...',
            area: true,
          ),
        ];

      default:
        return [_note('This step is completed or auto-set.', color)];
    }
  }

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
                    AppSvgIcon(
                      AppSvgAssets.chevronRight,
                      size: 18,
                      color: _kTextMut.withValues(alpha: 0.6),
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

  Widget _timePicker(
    String key,
    String label,
    Color color, {
    bool required = false,
  }) {
    final controller = _c(key);
    final hasTime = controller.text.isNotEmpty;
    final display = hasTime ? controller.text : 'Tap to select time';

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
            onTap: () => _pickTime(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: hasTime
                    ? color.withValues(alpha: 0.05)
                    : const Color(0xFFFAFCFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasTime ? color : _kBorder,
                  width: hasTime ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: (hasTime ? color : _kTextMut).withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: AppSvgIcon(
                      AppSvgAssets.clock,
                      size: 16,
                      color: hasTime ? color : _kTextMut,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      display,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: hasTime ? FontWeight.w600 : FontWeight.w400,
                        color: hasTime ? color : _kTextMut,
                      ),
                    ),
                  ),
                  if (hasTime)
                    GestureDetector(
                      onTap: () => setState(() => controller.clear()),
                      child: const AppSvgIcon(
                        AppSvgAssets.x,
                        size: 16,
                        color: _kTextMut,
                      ),
                    )
                  else
                    AppSvgIcon(
                      AppSvgAssets.chevronRight,
                      size: 18,
                      color: _kTextMut.withValues(alpha: 0.6),
                    ),
                ],
              ),
            ),
          ),
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
                  color: errorText != null ? _kRed : _kBlue,
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

  Widget _check(String key, String label, {bool required = false}) {
    final errorText = _err(key);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _sf(key, !_f(key)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: _f(key)
                  ? AppColors.successLight)
                  : AppColors.bgSecondary),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: errorText != null
                    ? _kRed
                    : _f(key)
                    ? _kGreen
                    : _kBorder,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _f(key) ? _kGreen : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _f(key) ? _kGreen : AppColors.textLight),
                      width: 2,
                    ),
                  ),
                  child: _f(key)
                      ? const AppSvgIcon(
                          AppSvgAssets.check,
                          color: Colors.white,
                          size: 13,
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _f(key) ? const Color(0xFF065F46) : _kTextSec,
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
              ],
            ),
          ),
        ),
        if (errorText != null) _fieldError(errorText),
      ],
    );
  }

  // ── Photo picker section (grid + add button) ────────────────────────────
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
                  _photoGridTile(photos[i], () => onRemove(i), color),
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
                    style: BorderStyle.solid,
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

  Widget _photoGridTile(
    PickedPhoto photo,
    VoidCallback onRemove,
    Color color,
  ) => Stack(
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
  final SprinklerStep currentStep;
  final VoidCallback onTap;

  const _UpdateStatusBar({required this.currentStep, required this.onTap});

  String get _nextLabel {
    switch (currentStep) {
      case SprinklerStep.installationStarted:
        return 'Mark Installation Completed';
      case SprinklerStep.installationCompleted:
        return 'Installation Completed';
      default:
        return 'Update';
    }
  }

  String get _currentLabel {
    switch (currentStep) {
      case SprinklerStep.installationStarted:
        return 'Installation Started';
      case SprinklerStep.installationCompleted:
        return 'Installation Completed';
      default:
        return 'Completed';
    }
  }

  String get _icon {
    switch (currentStep) {
      case SprinklerStep.installationStarted:
        return AppSvgAssets.cog;
      case SprinklerStep.installationCompleted:
        return AppSvgAssets.flaskConical;
      default:
        return AppSvgAssets.trophy;
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
                  color: _kBlue.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kBlue.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppSvgIcon(
                      AppSvgAssets.circle,
                      size: 7,
                      color: _kBlue,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Current: $_currentLabel',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _kBlue,
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
                  colors: [_kBlue, _kBlue.withValues(alpha: 0.82)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _kBlue.withValues(alpha: 0.35),
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
                    ),
                  ),
                  const SizedBox(width: 6),
                  const AppSvgIcon(
                    AppSvgAssets.chevronRight,
                    color: Colors.white70,
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






