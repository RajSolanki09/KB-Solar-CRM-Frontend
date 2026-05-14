// lib/Cubits/SolarLeads/solar_leads_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Helper/picked_photo.dart';
import 'package:solar_project/data/Models/solar_leads_model.dart';
import 'package:solar_project/data/Repository/solar_leads_repository.dart';
import 'solar_leads_state.dart';

class SolarLeadCubit extends Cubit<SolarLeadState> {
  final SolarLeadRepository _repo;
  SolarLeadCubit(this._repo) : super(SolarLeadInitial());

  String _msg(Object e) => e.toString().replaceAll("Exception: ", "");

  // ── CREATE ────────────────────────────────────────────────────────────────
  // referenceName is embedded in the lead model and sent via toCreateJson()
  Future<void> createLead(SolarLeadsModel lead) async {
    emit(SolarLeadLoading());
    try {
      emit(SolarLeadSaved(await _repo.createLead(lead)));
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── GET ALL ───────────────────────────────────────────────────────────────
  // Per-tab pagination tracking
  // Tab indices: 0 = Recent, 1 = Older, 2 = Completed
  final Map<int, int> _tabCurrentPage = {0: 1, 1: 1, 2: 1};
  final Map<int, int> _tabTotalPages = {0: 1, 1: 1, 2: 1};
  final Map<int, int> _tabTotalLeads = {0: 0, 1: 0, 2: 0};

  // Installation pending count tracking
  int _installationPendingCount = 0;

  String? _lastStatus;
  String? _lastSearch;
  DateTime? _lastSelectedDate;
  int _currentTab = 0; // 0=Recent, 1=Older, 2=Completed

  // Getters for current tab pagination
  int get currentPage => _tabCurrentPage[_currentTab] ?? 1;
  int get totalPages => _tabTotalPages[_currentTab] ?? 1;
  int get totalLeads => _tabTotalLeads[_currentTab] ?? 0;

  // Getters for specific tab pagination
  int getTabPage(int tabIndex) => _tabCurrentPage[tabIndex] ?? 1;
  int getTabTotalPages(int tabIndex) => _tabTotalPages[tabIndex] ?? 1;
  int getTabTotalLeads(int tabIndex) => _tabTotalLeads[tabIndex] ?? 0;

  // Getter for installation pending count
  int getInstallationPendingCount() => _installationPendingCount;

  // Main fetch for all tabs - pre-loads counts for all 3 tabs
  Future<void> fetchAllLeads({
    String? status,
    String? search,
    DateTime? selectedDate,
  }) async {
    _lastStatus = status;
    _lastSearch = search;
    _lastSelectedDate = selectedDate;
    // Reset pagination for all tabs
    _tabCurrentPage.clear();
    _tabTotalPages.clear();
    _tabTotalLeads.clear();
    _tabCurrentPage.addAll({0: 1, 1: 1, 2: 1});
    _tabTotalPages.addAll({0: 1, 1: 1, 2: 1});
    _tabTotalLeads.addAll({0: 0, 1: 0, 2: 0});
    _currentTab = 0;

    // Pre-load all tabs to populate their counts before user clicks
    // Start with tab 0 and display it, then load tabs 1 and 2 in background
    await _doFetchTab(tabIndex: 0);

    // Load other tabs silently to populate counts
    try {
      await _doFetchTab(tabIndex: 1);
      await _doFetchTab(tabIndex: 2);
      // After loading all tabs, emit tab 0 again to display it in UI
      await _doFetchTab(tabIndex: 0);
    } catch (e) {
      // If any tab fails, just continue - tab 0 is still valid
      print('Error pre-loading tab counts: $e');
    }

    // Fetch installation pending count separately (without date filtering)
    await _fetchAndUpdateInstallationPendingCount();
  }

  // Fetch all leads to count installation pending (no date filtering)
  Future<void> _fetchAndUpdateInstallationPendingCount() async {
    try {
      final result = await _repo.getAllLeads(
        status: 'all',
        search: null,
        page: 1,
        limit: 9999, // Get all leads
        fromDate: null, // NO date filtering
        toDate: null,
      );

      // Filter for installation pending leads
      _installationPendingCount = result.leads
          .where(
            (l) =>
                l.currentStep.index >= SolarStep.dealDone.index &&
                l.currentStep.index <= SolarStep.installationStarted.index,
          )
          .length;
    } catch (e) {
      print('Error fetching installation pending count: $e');
      _installationPendingCount = 0;
    }
  }

  // Fetch specific page of current tab
  Future<void> fetchPage(int page, {int tabIndex = -1}) async {
    final tab = tabIndex >= 0 ? tabIndex : _currentTab;
    if (page < 1 || page > (_tabTotalPages[tab] ?? 1)) return;
    _tabCurrentPage[tab] = page;
    _currentTab = tab;
    await _doFetchTab(tabIndex: tab);
  }

  // Set current tab and fetch first page
  Future<void> setTabAndFetch(int tabIndex, {bool forceRefresh = false}) async {
    _currentTab = tabIndex;
    final isFirstLoad = (_tabTotalLeads[tabIndex] ?? 0) == 0;

    if (forceRefresh || isFirstLoad) {
      // First time loading this tab or force refresh
      _tabCurrentPage[tabIndex] = 1;
      await _doFetchTab(tabIndex: tabIndex);
    } else {
      // Tab was already loaded, fetch current page
      await _doFetchTab(tabIndex: tabIndex);
    }
  }

  Future<void> _doFetchTab({required int tabIndex}) async {
    emit(SolarLeadLoading());
    try {
      String? status = _lastStatus;
      String? search = _lastSearch;

      // Calculate date ranges based on tabIndex OR use selected date if provided
      DateTime? fromDate;
      DateTime? toDate;

      if (_lastSelectedDate != null) {
        // User picked a specific date - filter to only that date
        final selectedDay = DateTime(
          _lastSelectedDate!.year,
          _lastSelectedDate!.month,
          _lastSelectedDate!.day,
        );
        fromDate = selectedDay;
        toDate = selectedDay.add(const Duration(days: 1));
      } else {
        // No specific date picked - use automatic tab date ranges
        if (tabIndex == 0) {
          // Recent: last 7 days
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          fromDate = today.subtract(
            Duration(days: 6),
          ); // 7 days including today
          toDate = today.add(Duration(days: 1)); // End of today
        } else if (tabIndex == 1) {
          // Older: before 7 days
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          toDate = today.subtract(Duration(days: 7)); // Start of 7 days ago
          // fromDate is null to get all older leads
        }
      }

      // Apply tab-specific status filters
      if (tabIndex == 0 || tabIndex == 1) {
        // Recent (0) and Older (1): both fetch only ACTIVE leads from API
        // Only override if current filter is 'Completed' or specific status
        if (_lastStatus == 'all' ||
            _lastStatus == 'All' ||
            _lastStatus == 'Pending Payment') {
          // If 'all' or 'Pending Payment' status requested, keep it to fetch all leads regardless of completion
          status = _lastStatus;
        } else if (_lastStatus == 'Completed' ||
            (_lastStatus != 'All' &&
                _lastStatus != 'Active' &&
                _lastStatus != null)) {
          // If we're in a specific status filter, keep it for both tabs
          status = _lastStatus;
        } else {
          // Otherwise, fetch only active leads for pagination to work correctly
          status = 'Active';
        }
      } else if (tabIndex == 2) {
        // Completed leads - always fetch completed regardless of filter
        status = 'Completed'; // Use capitalized 'Completed' to match API
      }

      final result = await _repo.getAllLeads(
        status: status,
        search: search,
        page: _tabCurrentPage[tabIndex] ?? 1,
        limit: 10,
        fromDate: fromDate,
        toDate: toDate,
      );

      _tabTotalPages[tabIndex] = result.pages;
      _tabTotalLeads[tabIndex] = result.total;

      emit(
        SolarLeadsLoaded(
          leads: result.leads,
          total: result.total,
          page: result.page,
          pages: result.pages,
          tabIndex: tabIndex,
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── REFRESH SINGLE ────────────────────────────────────────────────────────
  Future<void> refreshLead(String id) async {
    try {
      emit(SolarLeadDetailLoaded(await _repo.getSingleLead(id)));
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── FETCH FOR INSTALLATION PENDING (NO DATE FILTERING) ──────────────────
  Future<void> fetchInstallationPending({String? status}) async {
    emit(SolarLeadLoading());
    try {
      final result = await _repo.getAllLeads(
        status: status ?? 'all',
        search: null,
        page: 1,
        limit: 1000, // High limit to get all leads
        fromDate: null, // NO date filtering
        toDate: null,
      );
      emit(
        SolarLeadsLoaded(
          leads: result.leads,
          total: result.total,
          page: result.page,
          pages: result.pages,
          tabIndex: 0,
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── FETCH INSTALLATION PENDING PAGE (SERVER-SIDE PAGINATION) ─────────────
  Future<Map<String, dynamic>> fetchInstallationPendingPage({
    required int page,
    required int limit,
    String? search,
  }) async {
    emit(SolarLeadLoading());
    try {
      // Saari leads fetch karo
      final result = await _repo.getAllLeads(
        status: 'all',
        search: search,
        page: 1, // ← page 1 fix
        limit: 9999, // ← sab fetch karo
        fromDate: null,
        toDate: null,
      );

      // Sirf dealDone (5) se installationStarted (7) tak
      final filtered = result.leads.where((l) {
        return l.currentStep.index >= SolarStep.dealDone.index &&
            l.currentStep.index <= SolarStep.installationStarted.index;
      }).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // Search apply karo
      final searched = (search == null || search.trim().isEmpty)
          ? filtered
          : filtered.where((l) {
              final q = search.toLowerCase();
              return l.customerName.toLowerCase().contains(q) ||
                  l.mobile.contains(search) ||
                  l.address.toLowerCase().contains(q);
            }).toList();

      // Paginate
      final total = searched.length;
      final totalPages = total == 0 ? 1 : (total / limit).ceil();
      final startIndex = (page - 1) * limit;
      final endIndex = (startIndex + limit).clamp(0, total);
      final paginatedLeads = startIndex >= total
          ? <SolarLeadsModel>[]
          : searched.sublist(startIndex, endIndex);

      emit(
        SolarLeadsLoaded(
          leads: paginatedLeads,
          total: total,
          page: page,
          pages: totalPages,
          tabIndex: 0,
        ),
      );

      return {
        'page': page,
        'pages': totalPages,
        'total': total,
        'leads': paginatedLeads,
      };
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PUT — first-time submit (advances stage)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> scheduleVisit(
    String id, {
    DateTime? visitDate,
    String? salesAssignedId,
    String? notes,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.updateVisitSchedule(
            id,
            visitDate: visitDate,
            salesAssignedId: salesAssignedId,
            notes: notes,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── STEP 4: QUOTATION ─────────────────────────────────────────────────────
  Future<void> saveQuotation(
    String id, {
    String? systemSize,
    String? panelType,
    String? inverterType,
    String? structureType,
    String? wiringDetails,
    double? rooftopSystemCost,
    double? elevatedStructureCost,
    double? netMeterCost,
    double? premiumOtherCost,
    double? totalAmount,
    double? subsidyAmount,
    double? advancePercent,
    double? balancePercent,
    String? warrantyNote,
    String? notes,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.updateQuotation(
            id,
            systemSize: systemSize,
            panelType: panelType,
            inverterType: inverterType,
            structureType: structureType,
            wiringDetails: wiringDetails,
            rooftopSystemCost: rooftopSystemCost,
            elevatedStructureCost: elevatedStructureCost,
            netMeterCost: netMeterCost,
            premiumOtherCost: premiumOtherCost,
            totalAmount: totalAmount,
            subsidyAmount: subsidyAmount,
            advancePercent: advancePercent,
            balancePercent: balancePercent,
            warrantyNote: warrantyNote,
            notes: notes,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── STEP 5: FOLLOWUP ─────────────────────────────────────────────────────
  Future<void> saveFollowup(
    String id, {
    DateTime? followupDate,
    String? notes,
    String? outcome,
    String? customerType,
    String? interestLevel,
    String? followupType,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.updateFollowup(
            id,
            followupDate: followupDate,
            notes: notes,
            outcome: outcome,
            customerType: customerType,
            interestLevel: interestLevel,
            followupType: followupType,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── ADD FOLLOWUP ENTRY ────────────────────────────────────────────────────
  Future<void> addFollowupEntry(
    String id, {
    required String remark,
    required String followupType,
    required DateTime nextFollowupDate,
    int? callDuration,
    String? attachment,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.addFollowupEntry(
            id,
            remark: remark,
            followupType: followupType,
            nextFollowupDate: nextFollowupDate,
            callDuration: callDuration,
            attachment: attachment,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── GET FOLLOWUP HISTORY ──────────────────────────────────────────────────
  Future<void> loadFollowupHistory(String id) async {
    emit(SolarLeadLoading());
    try {
      final history = await _repo.getFollowupHistory(id);
      emit(SolarFollowupHistoryLoaded(history));
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── MARK FOLLOWUP DONE ──────────────────────────────────────────────────
  Future<void> markFollowupDone(String id) async {
    emit(SolarLeadLoading());
    try {
      emit(SolarLeadSaved(await _repo.markFollowupDone(id)));
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── STEP 6: DEAL ──────────────────────────────────────────────────────────
  Future<void> saveDeal(
    String id, {
    double? finalAmount,
    double? advancePayment,
    String? paymentMode,
    DateTime? expectedInstallDate,
    String? notes,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.updateDeal(
            id,
            finalAmount: finalAmount,
            advancePayment: advancePayment,
            paymentMode: paymentMode,
            expectedInstallDate: expectedInstallDate,
            notes: notes,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── STEP 7: INSTALLATION ASSIGNED ─────────────────────────────────────────
  Future<void> saveInstallationAssign(
    String id, {
    List<String>? installationTeamMemberIds,
    List<String>? installationTeamNames,
    DateTime? scheduledDate,
    String? notes,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.updateInstallationAssign(
            id,
            installationTeamMemberIds: installationTeamMemberIds,
            installationTeamNames: installationTeamNames,
            scheduledDate: scheduledDate,
            notes: notes,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── STEP 8: INSTALLATION STARTED ──────────────────────────────────────────
  Future<void> saveInstallationStarted(
    String id, {
    String? teamAssigned,
    DateTime? startDate,
    String? notes,
    List<PickedPhoto> beforePhotos = const [],
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.updateInstallationStarted(
            id,
            teamAssigned: teamAssigned,
            startDate: startDate,
            notes: notes,
            beforePhotos: beforePhotos,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── STEP 9: INSTALLATION COMPLETED ────────────────────────────────────────
  Future<void> saveInstallation(
    String id, {
    bool systemTested = false,
    bool customerSigned = false,
    bool structureDone = false,
    bool wiringDone = false,
    bool plumeDone = false,
    bool inverterAcDone = false,
    bool fullyComplete = false,
    DateTime? completedDate,
    String? structureVendorName,
    String? structureVendorCo,
    String? wiringVendorName,
    String? wiringVendorCo,
    String? notes,
    List<PickedPhoto> afterPhotos = const [],
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.updateInstallation(
            id,
            systemTested: systemTested,
            customerSigned: customerSigned,
            structureDone: structureDone,
            wiringDone: wiringDone,
            plumeDone: plumeDone,
            inverterAcDone: inverterAcDone,
            fullyComplete: fullyComplete,
            completedDate: completedDate,
            structureVendorName: structureVendorName,
            structureVendorCo: structureVendorCo,
            wiringVendorName: wiringVendorName,
            wiringVendorCo: wiringVendorCo,
            notes: notes,
            afterPhotos: afterPhotos,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── STEP 10: AGREEMENT UPLOAD ───────────────────────────────────────────
  Future<void> saveAgreementUpload(
    String id, {
    bool agreementUploaded = false,
    bool installationDetailsProvided = false,
    String? status,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.updateAgreementUpload(
            id,
            agreementUploaded: agreementUploaded,
            installationDetailsProvided: installationDetailsProvided,
            status: status,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── STEP 10: METER ────────────────────────────────────────────────────────
  Future<void> saveMeter(
    String id, {
    DateTime? applicationDate,
    DateTime? inspectionDate,
    DateTime? installedDate,
    bool? gebFileHandover,
    String? meterInstallationStatus,
    String? systemRunStatus,
    String? notes,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.updateMeter(
            id,
            applicationDate: applicationDate,
            inspectionDate: inspectionDate,
            installedDate: installedDate,
            gebFileHandover: gebFileHandover,
            meterInstallationStatus: meterInstallationStatus,
            systemRunStatus: systemRunStatus,
            notes: notes,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── STEP 11: PORTAL ───────────────────────────────────────────────────────
  Future<void> savePortal(
    String id, {
    String? applicationId,
    String? status,
    String? notes,
    Map<String, PickedPhoto> documents = const {},
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.updatePortal(
            id,
            applicationId: applicationId,
            status: status,
            notes: notes,
            documents: documents,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── STEP 12: SUBSIDY ──────────────────────────────────────────────────────
  Future<void> saveSubsidy(
    String id, {
    bool? subsidyClaim,
    bool? receivedAmount,
    String? notes,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.updateSubsidy(
            id,
            subsidyClaim: subsidyClaim,
            receivedAmount: receivedAmount,
            notes: notes,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── STEP 13: PAYMENT ──────────────────────────────────────────────────────
  Future<void> addPayment(
    String id, {
    required double amount,
    required String mode,
    String type = 'partial',
    String? notes,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.addPayment(
            id,
            amount: amount,
            mode: mode,
            type: type,
            notes: notes,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // Pending payment

  Future<void> fetchAllLeadsForPendingPayment() async {
    emit(SolarLeadLoading());
    try {
      final result = await _repo.getAllLeads(
        status: 'all',
        page: 1,
        limit: 9999,
      );

      final filtered = result.leads.where((l) {
        if (l.currentStep.index < SolarStep.dealDone.index) return false;
        if (l.currentStep == SolarStep.projectCompleted) return false;
        if (l.isCompleted) return false;

        final remaining = l.paymentSummary.remainingBalance > 0
            ? l.paymentSummary.remainingBalance
            : ((l.finalAmount ?? l.totalAmount) - (l.advancePayment ?? 0))
                  .clamp(0, double.infinity)
                  .toDouble();
        return remaining > 0;
      }).toList();

      emit(
        SolarLeadsLoaded(
          leads: filtered,
          total: filtered.length,
          page: 1,
          pages: 1,
          tabIndex: 0,
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // Pending Payment Count

  Future<int> getPendingPaymentCount() async {
  try {
    final result = await _repo.getAllLeads(
      status: 'all',
      page: 1,
      limit: 9999,
    );
    return result.leads.where((l) {
      if (l.isCompleted) return false;
      if (l.currentStep == SolarStep.projectCompleted) return false;
      if (l.currentStep.index < SolarStep.dealDone.index) return false;
      final remaining = l.paymentSummary.remainingBalance > 0
          ? l.paymentSummary.remainingBalance
          : ((l.finalAmount ?? l.totalAmount) - (l.advancePayment ?? 0))
                .clamp(0, double.infinity);
      return remaining > 0;
    }).length;
  } catch (_) {
    return 0;
  }
}

// Installation Pending Count 

Future<int> getInstallationPendingCountAsync() async {
  try {
    final result = await _repo.getAllLeads(
      status: 'all',
      page: 1,
      limit: 9999,
    );
    return result.leads.where((l) {
      return l.currentStep.index >= SolarStep.dealDone.index &&
          l.currentStep.index <= SolarStep.installationStarted.index;
    }).length;
  } catch (_) {
    return 0;
  }
}
  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<void> deleteLead(String id) async {
    emit(SolarLeadLoading());
    try {
      await _repo.deleteLead(id);
      emit(SolarLeadSuccess());
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── UPDATE BASIC INFO ─────────────────────────────────────────────────────
  // Edits core customer fields (name, phone, address, source, etc.)
  // without advancing the pipeline step.
  Future<void> updateBasicInfo(
    String id, {
    String? customerName,
    String? mobile,
    String? address,
    String? village,
    double? landSize,
    double? requiredKW,
    String? electricityConnection,
    String? source,
    String? referenceName,
    String? note,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.updateBasicInfo(
            id,
            customerName: customerName,
            mobile: mobile,
            address: address,
            village: village,
            landSize: landSize,
            requiredKW: requiredKW,
            electricityConnection: electricityConnection,
            source: source,
            referenceName: referenceName,
            note: note,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PATCH — edit existing data (NO stage advance)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> editVisitSchedule(
    String id, {
    DateTime? visitDate,
    String? salesAssignedId,
    String? notes,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.editVisitSchedule(
            id,
            visitDate: visitDate,
            salesAssignedId: salesAssignedId,
            notes: notes,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  // ── STEP 2b: TECHNICAL VISIT ──────────────────────────────────────────────
  Future<void> markTechnicalVisit(
    String id, {
    String? systemKW,
    String? meterPhase,
    String? inverterBoardType,
    String? panelBoardType,
    String? panelCapacity,
    String? cableType,
    String? acDBType,
    String? structureHeight,
    String? beamLineDetails,
    String? totalArray,
    String? scaffoldingDetails,
    String? panelLayout,
    String? lugType,
    String? dbConfigSingle,
    String? dbConfigThree,
    String? estimatedCost,
    String? additionalNotes,
    List<PickedPhoto> photos = const [],
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.updateTechnicalVisit(
            id,
            systemKW: systemKW,
            meterPhase: meterPhase,
            inverterBoardType: inverterBoardType,
            panelBoardType: panelBoardType,
            panelCapacity: panelCapacity,
            cableType: cableType,
            acDBType: acDBType,
            structureHeight: structureHeight,
            beamLineDetails: beamLineDetails,
            totalArray: totalArray,
            scaffoldingDetails: scaffoldingDetails,
            panelLayout: panelLayout,
            lugType: lugType,
            dbConfigSingle: dbConfigSingle,
            dbConfigThree: dbConfigThree,
            estimatedCost: estimatedCost,
            additionalNotes: additionalNotes,
            photos: photos,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  Future<void> editTechnicalVisit(
    String id, {
    String? systemKW,
    String? meterPhase,
    String? inverterBoardType,
    String? panelBoardType,
    String? panelCapacity,
    String? cableType,
    String? acDBType,
    String? structureHeight,
    String? beamLineDetails,
    String? totalArray,
    String? scaffoldingDetails,
    String? panelLayout,
    String? lugType,
    String? dbConfigSingle,
    String? dbConfigThree,
    String? estimatedCost,
    String? additionalNotes,
    List<PickedPhoto> photos = const [],
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.editTechnicalVisit(
            id,
            systemKW: systemKW,
            meterPhase: meterPhase,
            inverterBoardType: inverterBoardType,
            panelBoardType: panelBoardType,
            panelCapacity: panelCapacity,
            cableType: cableType,
            acDBType: acDBType,
            structureHeight: structureHeight,
            beamLineDetails: beamLineDetails,
            totalArray: totalArray,
            scaffoldingDetails: scaffoldingDetails,
            panelLayout: panelLayout,
            lugType: lugType,
            dbConfigSingle: dbConfigSingle,
            dbConfigThree: dbConfigThree,
            estimatedCost: estimatedCost,
            additionalNotes: additionalNotes,
            photos: photos,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  Future<void> editQuotation(
    String id, {
    String? systemSize,
    String? panelType,
    String? inverterType,
    String? structureType,
    String? wiringDetails,
    double? rooftopSystemCost,
    double? elevatedStructureCost,
    double? netMeterCost,
    double? premiumOtherCost,
    double? totalAmount,
    double? subsidyAmount,
    double? advancePercent,
    double? balancePercent,
    String? warrantyNote,
    String? notes,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.editQuotation(
            id,
            systemSize: systemSize,
            panelType: panelType,
            inverterType: inverterType,
            structureType: structureType,
            wiringDetails: wiringDetails,
            rooftopSystemCost: rooftopSystemCost,
            elevatedStructureCost: elevatedStructureCost,
            netMeterCost: netMeterCost,
            premiumOtherCost: premiumOtherCost,
            totalAmount: totalAmount,
            subsidyAmount: subsidyAmount,
            advancePercent: advancePercent,
            balancePercent: balancePercent,
            warrantyNote: warrantyNote,
            notes: notes,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  Future<void> editFollowup(
    String id, {
    DateTime? followupDate,
    String? notes,
    String? outcome,
    String? customerType,
    String? interestLevel,
    String? followupType,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.editFollowup(
            id,
            followupDate: followupDate,
            notes: notes,
            outcome: outcome,
            customerType: customerType,
            interestLevel: interestLevel,
            followupType: followupType,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  Future<void> editDeal(
    String id, {
    double? finalAmount,
    double? advancePayment,
    String? paymentMode,
    DateTime? expectedInstallDate,
    String? installationTeamMemberId,
    String? installationTeamName,
    String? notes,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.editDeal(
            id,
            finalAmount: finalAmount,
            advancePayment: advancePayment,
            paymentMode: paymentMode,
            expectedInstallDate: expectedInstallDate,
            installationTeamMemberId: installationTeamMemberId,
            installationTeamName: installationTeamName,
            notes: notes,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  Future<void> editInstallationAssign(
    String id, {
    List<String>? installationTeamMemberIds,
    List<String>? installationTeamNames,
    DateTime? scheduledDate,
    String? notes,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.editInstallationAssign(
            id,
            installationTeamMemberIds: installationTeamMemberIds,
            installationTeamNames: installationTeamNames,
            scheduledDate: scheduledDate,
            notes: notes,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  Future<void> editInstallation(
    String id, {
    String? teamAssigned,
    bool? systemTested,
    bool? customerSigned,
    bool? structureDone,
    bool? wiringDone,
    bool? plumeDone,
    bool? inverterAcDone,
    bool? fullyComplete,
    DateTime? completedDate,
    String? structureVendorName,
    String? structureVendorCo,
    String? wiringVendorName,
    String? wiringVendorCo,
    String? notes,
    List<PickedPhoto> beforePhotos = const [],
    List<PickedPhoto> afterPhotos = const [],
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.editInstallation(
            id,
            teamAssigned: teamAssigned,
            systemTested: systemTested,
            customerSigned: customerSigned,
            structureDone: structureDone,
            wiringDone: wiringDone,
            plumeDone: plumeDone,
            inverterAcDone: inverterAcDone,
            fullyComplete: fullyComplete,
            completedDate: completedDate,
            structureVendorName: structureVendorName,
            structureVendorCo: structureVendorCo,
            wiringVendorName: wiringVendorName,
            wiringVendorCo: wiringVendorCo,
            notes: notes,
            beforePhotos: beforePhotos,
            afterPhotos: afterPhotos,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  Future<void> editAgreementUpload(
    String id, {
    bool? agreementUploaded,
    bool? installationDetailsProvided,
    String? status,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.editAgreementUpload(
            id,
            agreementUploaded: agreementUploaded,
            installationDetailsProvided: installationDetailsProvided,
            status: status,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  Future<void> editMeter(
    String id, {
    DateTime? applicationDate,
    DateTime? inspectionDate,
    DateTime? installedDate,
    bool? gebFileHandover,
    String? meterInstallationStatus,
    String? systemRunStatus,
    String? notes,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.editMeter(
            id,
            applicationDate: applicationDate,
            inspectionDate: inspectionDate,
            installedDate: installedDate,
            gebFileHandover: gebFileHandover,
            meterInstallationStatus: meterInstallationStatus,
            systemRunStatus: systemRunStatus,
            notes: notes,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  Future<void> editPortal(
    String id, {
    String? applicationId,
    String? status,
    String? notes,
    Map<String, PickedPhoto> documents = const {},
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.editPortal(
            id,
            applicationId: applicationId,
            status: status,
            notes: notes,
            documents: documents,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  Future<void> editSubsidy(
    String id, {
    bool? subsidyClaim,
    bool? receivedAmount,
    String? notes,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.editSubsidy(
            id,
            subsidyClaim: subsidyClaim,
            receivedAmount: receivedAmount,
            notes: notes,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }

  Future<void> editPayment(
    String id, {
    required double amount,
    required String mode,
    String type = 'partial',
    String? notes,
  }) async {
    emit(SolarLeadLoading());
    try {
      emit(
        SolarLeadSaved(
          await _repo.editPayment(
            id,
            amount: amount,
            mode: mode,
            type: type,
            notes: notes,
          ),
        ),
      );
    } catch (e) {
      emit(SolarLeadError(_msg(e)));
    }
  }
}
