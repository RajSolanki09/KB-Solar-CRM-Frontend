// lib/Cubits/Installation/installation_cubit.dart
//
// Handles the SOLAR installation team workflow AND merges in SPRINKLER leads
// assigned to the current user so both appear in the same installation dashboard.
//
// ── Solar workflow steps (handled via updateStatus) ──────────────────────────
//   installationAssigned → installationStarted → installationCompleted
//   → meterApplied → meterInspection → meterInstalled → projectCompleted
//
// ── Sprinkler workflow steps (handled by SprinklerLeadCubit, not this cubit) ─
//   installationAssigned → installationStarted → installationCompleted
//   → systemTested
//   (payment + review are admin-only, done from the admin panel)
//
// ── Key design decisions ──────────────────────────────────────────────────────
//   1. fetchInstallations() merges solar + sprinkler leads into one list.
//      Sprinkler leads are wrapped as InstallationModel with projectType = "sprinkler".
//   2. updateStatus() only acts on SOLAR leads. Tapping a sprinkler lead from
//      the assigned screen opens SprinklerLeadDetailScreen instead (see
//      assigned_installation_screen.dart).
//   3. Payment for sprinkler leads is admin-only and is NOT handled here.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/Auth/auth_cubit.dart';
import 'package:solar_project/core/network/dio_client.dart';
import 'package:solar_project/data/Models/installation_model.dart';
import 'package:solar_project/data/Models/sprinkler_lead_model.dart';
import 'package:solar_project/data/Repository/installation_repository.dart';
import 'package:solar_project/data/Repository/sprinkler_leads_repository.dart';
import 'installation_state.dart';

class InstallationCubit extends Cubit<InstallationState> {
  final InstallationRepository _repo;
  final AppStateCubit _authCubit;

  // Sprinkler repo is created lazily on first fetch — no dependency injection
  // needed since it only requires DioClient (which uses stored token).
  SprinklerLeadRepository? _spkRepo;
  SprinklerLeadRepository get _sprinklerRepo =>
      _spkRepo ??= SprinklerLeadRepository(DioClient());

  InstallationCubit({
    required InstallationRepository repo,
    required AppStateCubit authCubit,
  }) : _repo = repo,
       _authCubit = authCubit,
       super(InstallationInitial());

  // ─────────────────────────────────────────────────────────────────────────
  // FETCH — merges solar + sprinkler into one list
  // ─────────────────────────────────────────────────────────────────────────

  /// Fetches solar leads assigned to this user AND sprinkler leads assigned
  /// to this user, then emits InstallationsLoaded with the merged list.
  ///
  /// Sprinkler leads are converted to InstallationModel with
  ///   projectType = "sprinkler"
  /// so the existing tab filtering in AssignedInstallationsScreen works
  /// without any UI changes.
  ///
  /// A sprinkler fetch failure is non-fatal — solar leads still appear.
  Future<void> fetchInstallations() async {
    // Keep auth cubit dependency active for DI lifecycle and future role checks.
    final _ = _authCubit.state;
    emit(InstallationLoading());
    try {
      // ── 1. Solar installations ───────────────────────────────────────────
      final solarLeadsRaw = await _repo.fetchMyInstallations();
      final solarLeads = solarLeadsRaw
          .map(_applySolarDashboardAutoCompletion)
          .toList();

      // ── 2. Sprinkler leads assigned to this installation user ────────────
      List<InstallationModel> sprinklerLeads = [];
      try {
        final spkLeads = await _sprinklerRepo.getMyInstallationLeads();
        sprinklerLeads = spkLeads
            .map((s) => _sprinklerToInstallationModel(s))
            .toList();
      } catch (e) {
        // Non-fatal: keep solar leads even if sprinkler fetch fails
        print(
          'InstallationCubit.fetchInstallations: sprinkler fetch error: $e',
        );
      }

      // ── 3. Merge and emit ────────────────────────────────────────────────
      emit(InstallationsLoaded([...solarLeads, ...sprinklerLeads]));
    } catch (e) {
      emit(InstallationError(_message(e)));
    }
  }

  InstallationModel _applySolarDashboardAutoCompletion(InstallationModel m) {
    final isSolar = m.projectType.toLowerCase() == 'solar';
    if (!isSolar) return m;

    final shouldAutoComplete =
        m.status.index >= InstallationStatus.installationCompleted.index;
    if (!shouldAutoComplete) return m;

    return m.copyWith(
      status: InstallationStatus.projectCompleted,
      projectCompleted: true,
      projectCompletedAt:
          m.projectCompletedAt ?? m.completedDate ?? DateTime.now(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SOLAR STEP ACTIONS
  // updateStatus() is the single entry point for all solar status transitions.
  // It maps InstallationStatus enum → correct API endpoint via the repository.
  // ─────────────────────────────────────────────────────────────────────────

  /// Advance a SOLAR installation lead to the next status.
  ///
  /// [extra] carries any additional form data the step screen collects
  /// (e.g. photos, notes, flags) and is forwarded to the repository.
  ///
  /// After success:
  ///   - emits InstallationActionSuccess(updated: model)
  ///   - re-fetches the full list so the dashboard reflects the change
  Future<void> updateStatus({
    required String installationId,
    required InstallationStatus status,
    Map<String, dynamic> extra = const {},
  }) async {
    emit(InstallationLoading());
    try {
      final updated = await _repo.updateStatus(
        installationId: installationId,
        status: status,
        extra: extra,
      );
      emit(
        InstallationActionSuccess(
          updated: updated,
          message: _statusMessage(status),
        ),
      );
      // Refresh list in background so dashboard card shows new status
      Future.microtask(() => fetchInstallations());
    } catch (e) {
      emit(InstallationError(_message(e)));
    }
  }

  // ── Convenience wrappers (kept for any screen that calls them directly) ───

  /// Step 7 (solar): Mark installation started.
  /// Calls PUT /installation/my-leads/:id/start
  Future<void> markInstallationStarted({
    required String installationId,
    String? notes,
  }) async {
    emit(InstallationLoading());
    try {
      final updated = await _repo.markInstallationStarted(
        installationId: installationId,
        notes: notes,
      );
      emit(
        InstallationActionSuccess(
          updated: updated,
          message: 'Installation started',
        ),
      );
      Future.microtask(() => fetchInstallations());
    } catch (e) {
      emit(InstallationError(_message(e)));
    }
  }

  /// Step 8 (solar): Mark installation completed.
  /// Calls PUT /installation/my-leads/:id/installation
  Future<void> markInstalled({
    required String installationId,
    String? notes,
  }) async {
    emit(InstallationLoading());
    try {
      final updated = await _repo.markInstalled(
        installationId: installationId,
        notes: notes,
      );
      emit(
        InstallationActionSuccess(
          updated: updated,
          message: 'Installation completed',
        ),
      );
      Future.microtask(() => fetchInstallations());
    } catch (e) {
      emit(InstallationError(_message(e)));
    }
  }

  /// Steps 9a/9b/9c (solar): Update meter sub-stage.
  /// All three call PUT /installation/my-leads/:id/meter with different date fields.
  Future<void> updateMeter({
    required String installationId,
    required MeterStage stage,
  }) async {
    emit(InstallationLoading());
    try {
      final updated = await _repo.updateMeter(
        installationId: installationId,
        stage: stage,
      );
      emit(
        InstallationActionSuccess(
          updated: updated,
          message: _meterMessage(stage),
        ),
      );
      Future.microtask(() => fetchInstallations());
    } catch (e) {
      emit(InstallationError(_message(e)));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PAYMENT  (Solar leads — admin-only for sprinkler leads)
  // ─────────────────────────────────────────────────────────────────────────

  /// Collect a payment for a SOLAR installation lead.
  /// For sprinkler leads, payment is handled by the admin via SprinklerLeadCubit.
  Future<void> collectPayment({
    required String installationId,
    required double amount,
    required String mode,
    required DateTime date,
  }) async {
    emit(InstallationLoading());
    try {
      await _repo.collectPayment(
        installationId: installationId,
        amount: amount,
        mode: mode,
        date: date,
      );
      emit(InstallationActionSuccess(message: 'Payment recorded'));
      Future.microtask(() => fetchInstallations());
    } catch (e) {
      emit(InstallationError(_message(e)));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PHOTOS
  // ─────────────────────────────────────────────────────────────────────────

  /// Upload photos for a solar installation lead.
  /// [category] maps to the multipart field name (e.g. "beforePhotos", "afterPhotos").
  Future<void> uploadPhotos({
    required String installationId,
    required List<String> photoPaths,
    required String category,
  }) async {
    emit(InstallationLoading());
    try {
      await _repo.uploadPhotos(
        installationId: installationId,
        photoPaths: photoPaths,
        category: category,
      );
      emit(InstallationActionSuccess(message: 'Photos uploaded'));
      Future.microtask(() => fetchInstallations());
    } catch (e) {
      emit(InstallationError(_message(e)));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTES
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> saveNotes({
    required String installationId,
    required String notes,
  }) async {
    emit(InstallationLoading());
    try {
      await _repo.saveNotes(installationId: installationId, notes: notes);
      emit(InstallationActionSuccess(message: 'Notes saved'));
    } catch (e) {
      emit(InstallationError(_message(e)));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PROJECT COMPLETE
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> completeProject({required String installationId}) async {
    emit(InstallationLoading());
    try {
      await _repo.completeProject(installationId: installationId);
      emit(InstallationActionSuccess(message: 'Project completed 🎉'));
      Future.microtask(() => fetchInstallations());
    } catch (e) {
      emit(InstallationError(_message(e)));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SPRINKLER → INSTALLATION MODEL CONVERSION
  // ─────────────────────────────────────────────────────────────────────────

  /// Wraps a SprinklerLeadModel as an InstallationModel so it renders
  /// correctly in the existing installation dashboard list widgets.
  ///
  /// Key field: projectType = "sprinkler"
  /// This is what AssignedInstallationsScreen uses to:
  ///   (a) put the lead in the Sprinkler tab
  ///   (b) route to SprinklerLeadDetailScreen on tap instead of
  ///       InstallationDetailScreen
  InstallationModel _sprinklerToInstallationModel(SprinklerLeadModel s) {
    final dashboardAutoCompleted =
        s.currentStep.index >= SprinklerStep.installationCompleted.index;
    final resolvedScheduledDate =
      s.installationAssignData.scheduledDate ?? s.dealData.expectedInstallDate;

    // Map SprinklerStep → human-readable status string expected by
    // InstallationModel._parseStatus()
    final String statusStr;
    if (dashboardAutoCompleted) {
      statusStr = 'Project Completed';
    } else {
      switch (s.currentStep) {
        case SprinklerStep.installationAssigned:
          statusStr = 'Installation Assigned';
          break;
        case SprinklerStep.installationStarted:
          statusStr = 'Installation Started';
          break;
        default:
          statusStr = s.status;
      }
    }

    final autoCompletedAt =
        s.installationData.completedAt ??
        s.installationData.installationDate ??
        s.updatedAt;

    return InstallationModel.fromJson({
      '_id': s.id,
      'customerName': s.customerName,
      'phone': s.phone,
      'address': s.address,
      'notes': s.installationAssignData.notes,
      'status': statusStr,
      'projectType': 'sprinkler', // ← tab filter key
      'projectCompleted': dashboardAutoCompleted || s.isCompleted,
      'projectCompletedAt': autoCompletedAt.toIso8601String(),
      'createdAt': s.createdAt.toIso8601String(),
      'updatedAt': s.updatedAt.toIso8601String(),
      // Payment info (read-only; payment is admin-only for sprinkler)
      'payment': {
        'totalAmount': s.paymentSummary.totalAmount,
        'amountReceived': s.paymentSummary.amountReceived,
        'remainingBalance': s.paymentSummary.remainingBalance,
      },
      // Deal info
      if (s.dealData.finalDealAmount != null)
        'deal': {
          'finalDealAmount': s.dealData.finalDealAmount,
          'advancePayment': s.dealData.advancePayment,
          'closedAt': s.dealData.closedAt?.toIso8601String(),
        },
      // Installation assign sub-doc
      'installationAssign': {
        'installationTeamMemberIds': s.effectiveInstallerIds,
        'installationTeamNames': s.effectiveInstallerNames,
        'installationTeamMemberId': s.effectiveInstallerId,
        'installationTeamName': s.effectiveInstallerName,
        'notes': s.installationAssignData.notes,
        'assignedAt': s.installationAssignData.assignedAt?.toIso8601String(),
        if (resolvedScheduledDate != null)
          'scheduledDate': resolvedScheduledDate.toIso8601String(),
      },
      // Installation work dates
      if (s.installationData.startedAt != null)
        'startDate': s.installationData.startedAt!.toIso8601String(),
      if (s.installationData.installationDate != null)
        'installationDate': s.installationData.installationDate!
            .toIso8601String(),
      if (resolvedScheduledDate != null)
        'scheduledDate': resolvedScheduledDate.toIso8601String(),
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  String _statusMessage(InstallationStatus s) {
    switch (s) {
      case InstallationStatus.installationStarted:
        return 'Installation started';
      case InstallationStatus.installationCompleted:
        return 'Installation completed';
      case InstallationStatus.meterApplied:
        return 'Meter application submitted';
      case InstallationStatus.meterInspection:
        return 'Meter inspection done';
      case InstallationStatus.meterInstalled:
        return 'Meter installed';
      case InstallationStatus.projectCompleted:
        return 'Project completed 🎉';
      default:
        return 'Status updated';
    }
  }

  String _meterMessage(MeterStage stage) {
    switch (stage) {
      case MeterStage.applied:
        return 'Meter application submitted';
      case MeterStage.inspection:
        return 'Meter inspection done';
      case MeterStage.installed:
        return 'Meter installed — project complete!';
    }
  }

  String _message(Object e) {
    final s = e.toString();
    if (s.contains('message:')) {
      final start = s.indexOf('message:') + 8;
      final end = s.contains('\n') ? s.indexOf('\n', start) : s.length;
      return s.substring(start, end).trim();
    }
    return s;
  }
}
