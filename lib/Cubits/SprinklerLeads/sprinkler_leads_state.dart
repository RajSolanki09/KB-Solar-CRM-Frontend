// lib/Cubits/SprinklerLeads/sprinkler_leads_state.dart

import 'package:solar_project/data/Models/sprinkler_lead_model.dart';

abstract class SprinklerLeadState {}

/// Initial state before any action is taken.
class SprinklerLeadInitial extends SprinklerLeadState {}

/// Emitted while any async operation is in progress.
/// Screens show a loading indicator during this state.
class SprinklerLeadLoading extends SprinklerLeadState {}

/// Emitted by fetchAllLeads() — carries the full list for the list screen.
class SprinklerLeadsLoaded extends SprinklerLeadState {
  final List<SprinklerLeadModel> leads;
  SprinklerLeadsLoaded(this.leads);
}

/// Emitted after any single-lead operation succeeds:
/// create, refresh, any step save, assign installer, payment, review, etc.
/// Detail screens listen for this to pop / update their local lead.
class SprinklerLeadSaved extends SprinklerLeadState {
  final SprinklerLeadModel lead;
  SprinklerLeadSaved(this.lead);
}

/// Emitted when any operation fails.
/// Screens show a SnackBar with [message].
class SprinklerLeadError extends SprinklerLeadState {
  final String message;
  SprinklerLeadError(this.message);
}