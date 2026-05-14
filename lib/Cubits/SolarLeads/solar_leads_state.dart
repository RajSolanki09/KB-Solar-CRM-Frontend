// lib/Cubits/SolarLeads/solar_leads_state.dart
import 'package:solar_project/data/Models/solar_leads_model.dart';

abstract class SolarLeadState {}

class SolarLeadInitial   extends SolarLeadState {}
class SolarLeadLoading   extends SolarLeadState {}

// Used by step screens — returns updated lead
class SolarLeadSaved extends SolarLeadState {
  final SolarLeadsModel lead;
  SolarLeadSaved(this.lead);
}

// Used by create / delete / generic success
class SolarLeadSuccess extends SolarLeadState {
  final SolarLeadsModel? lead;
  SolarLeadSuccess({this.lead});
}

// List loaded
class SolarLeadsLoaded extends SolarLeadState {
  final List<SolarLeadsModel> leads;
  final int total, page, pages;
  final int tabIndex; // New field for per-tab pagination
  SolarLeadsLoaded({
    required this.leads,
    required this.total,
    required this.page,
    required this.pages,
    this.tabIndex = 0,
  });
}

// Single lead detail loaded (used by detail screen refresh)
class SolarLeadDetailLoaded extends SolarLeadState {
  final SolarLeadsModel lead;
  SolarLeadDetailLoaded(this.lead);
}

// NEW: Followup history loaded
class SolarFollowupHistoryLoaded extends SolarLeadState {
  final List<FollowupHistoryEntry> history;
  SolarFollowupHistoryLoaded(this.history);
}

class SolarLeadError extends SolarLeadState {
  final String message;
  SolarLeadError(this.message);
}