// lib/Cubits/Installation/installation_state.dart

import 'package:solar_project/data/Models/installation_model.dart';

abstract class InstallationState {}

/// Initial state before any fetch.
class InstallationInitial extends InstallationState {}

/// Emitted while fetchInstallations() or updateStatus() is in progress.
class InstallationLoading extends InstallationState {}

/// Emitted by fetchInstallations() — carries the merged solar + sprinkler list.
/// All list screens (dashboard, pending, today's jobs, completed, assigned)
/// read from this state.
class InstallationsLoaded extends InstallationState {
  final List<InstallationModel> installations;
  InstallationsLoaded(this.installations);
}

/// Emitted after updateStatus() / collectPayment() / saveNotes() succeeds.
/// The detail screen listens for this to refresh its UI or pop the step sheet.
class InstallationActionSuccess extends InstallationState {
  final InstallationModel?
  updated; // null when no model is returned (e.g. notes)
  final String message;
  InstallationActionSuccess({
    this.updated,
    this.message = 'Updated successfully',
  });
}

/// Emitted on any failure.
class InstallationError extends InstallationState {
  final String message;
  InstallationError(this.message);
}
