// lib/Cubits/SprinklerLeads/sprinkler_leads_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/core/network/dio_client.dart';
import 'package:solar_project/data/Models/sprinkler_lead_model.dart';
import 'package:solar_project/data/Repository/sprinkler_leads_repository.dart';
import 'package:solar_project/Helper/picked_photo.dart';
import 'sprinkler_leads_state.dart';

class SprinklerLeadCubit extends Cubit<SprinklerLeadState> {
  final SprinklerLeadRepository _repo;

  SprinklerLeadCubit()
    : _repo = SprinklerLeadRepository(DioClient()),
      super(SprinklerLeadInitial());

  // ── Pagination tracking per tab ───────────────────────────────────────────
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

  // ── FETCH ALL LEADS ───────────────────────────────────────────────────────
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
                l.currentStep.index >=
                    SprinklerStep.installationAssigned.index &&
                l.currentStep.index < SprinklerStep.installationCompleted.index,
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

  // Internal fetch method for a specific tab
  Future<void> _doFetchTab({required int tabIndex}) async {
    emit(SprinklerLeadLoading());
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
        SprinklerLeadsLoaded(
          result.leads,
          total: result.total,
          page: result.page,
          pages: result.pages,
          tabIndex: tabIndex,
        ),
      );
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── REFRESH SINGLE LEAD ───────────────────────────────────────────────────
  Future<void> refreshLead(String leadId) async {
    try {
      final updated = await _repo.getSingleLead(leadId);
      emit(SprinklerLeadSaved(updated));
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── FETCH FOR INSTALLATION PENDING (NO DATE FILTERING) ──────────────────
  Future<void> fetchInstallationPending({String? status}) async {
    emit(SprinklerLeadLoading());
    try {
      final result = await _repo.getAllLeads(
        status: status ?? 'all',
        search: null,
        page: 1,
        limit: 9999,
        fromDate: null,
        toDate: null,
      );
      emit(
        SprinklerLeadsLoaded(
          result.leads,
          total: result.total,
          page: result.page,
          pages: result.pages,
          tabIndex: 0,
        ),
      );
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── FETCH INSTALLATION PENDING PAGE (SERVER-SIDE PAGINATION) ─────────────
  Future<Map<String, dynamic>> fetchInstallationPendingPage({
    required int page,
    required int limit,
    String? search,
  }) async {
    emit(SprinklerLeadLoading());
    try {
      final result = await _repo.getAllLeads(
        status: 'all',
        search: search,
        page: 1,
        limit: 9999,
        fromDate: null,
        toDate: null,
      );

      final filtered = result.leads.where((l) {
        return l.currentStep.index >=
                SprinklerStep.installationAssigned.index &&
            l.currentStep.index < SprinklerStep.installationCompleted.index;
      }).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final searched = (search == null || search.trim().isEmpty)
          ? filtered
          : filtered.where((l) {
              final q = search.toLowerCase();
              return l.customerName.toLowerCase().contains(q) ||
                  l.phone.contains(search) ||
                  l.address.toLowerCase().contains(q);
            }).toList();

      final total = searched.length;
      final totalPages = total == 0 ? 1 : (total / limit).ceil();
      final startIndex = (page - 1) * limit;
      final endIndex = (startIndex + limit).clamp(0, total);
      final paginatedLeads = startIndex >= total
          ? <SprinklerLeadModel>[]
          : searched.sublist(startIndex, endIndex);

      emit(
        SprinklerLeadsLoaded(
          paginatedLeads,
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
      emit(SprinklerLeadError(e.toString()));
      rethrow;
    }
  }

  // ── CREATE LEAD ───────────────────────────────────────────────────────────
  Future<void> createLead(SprinklerLeadModel lead) async {
    emit(SprinklerLeadLoading());
    try {
      final created = await _repo.createLead(lead);
      emit(SprinklerLeadSaved(created));
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── DELETE LEAD (admin only) ──────────────────────────────────────────────
  Future<void> deleteLead(String leadId) async {
    emit(SprinklerLeadLoading());
    try {
      await _repo.deleteLead(leadId);
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── STEP 1: UPDATE BASIC INFO ─────────────────────────────────────────────
  Future<void> updateBasicInfo(
    String leadId, {
    String? customerName,
    String? phone,
    String? address,
    String? village,
    double? farmSize,
    String? waterSource,
    String? cropType,
    String? source,
    String? referenceName,
    String? note,
  }) async {
    emit(SprinklerLeadLoading());
    try {
      final updated = await _repo.updateBasicInfo(
        leadId,
        customerName: customerName,
        phone: phone,
        address: address,
        village: village,
        farmSize: farmSize,
        waterSource: waterSource,
        cropType: cropType,
        source: source,
        referenceName: referenceName,
        note: note,
      );
      emit(SprinklerLeadSaved(updated));
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── STEP 2: SITE VISIT ────────────────────────────────────────────────────
  Future<void> saveSiteVisit(
    String leadId, {
    DateTime? visitDate,
    String? visitTime,
    String? salesPerson,
    String? fieldConditionNotes,
    String? waterAvailabilityNotes,
    String? notes,
    List<PickedPhoto> photos = const [],
  }) async {
    emit(SprinklerLeadLoading());
    try {
      final updated = await _repo.updateSiteVisit(
        leadId,
        visitDate: visitDate,
        visitTime: visitTime,
        salesPerson: salesPerson,
        fieldConditionNotes: fieldConditionNotes,
        waterAvailabilityNotes: waterAvailabilityNotes,
        notes: notes,
        photos: photos,
      );
      emit(SprinklerLeadSaved(updated));
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── STEP 3: VISIT DATA ────────────────────────────────────────────────────
  Future<void> saveVisitData(
    String leadId, {
    int? noOfPanels,
    String? pumpCapacity,
    String? typeOfPump,
    double? deliveryPipeLength,
    int? noOfSprinklers,
    double? cableLength,
    String? typeOfSite,
    String? notes,
    List<PickedPhoto> photos = const [],
  }) async {
    emit(SprinklerLeadLoading());
    try {
      final updated = await _repo.updateVisitData(
        leadId,
        noOfPanels: noOfPanels,
        pumpCapacity: pumpCapacity,
        typeOfPump: typeOfPump,
        deliveryPipeLength: deliveryPipeLength,
        noOfSprinklers: noOfSprinklers,
        cableLength: cableLength,
        typeOfSite: typeOfSite,
        notes: notes,
        photos: photos,
      );

      emit(SprinklerLeadSaved(updated));
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── STEP 4: QUOTATION ─────────────────────────────────────────────────────
  Future<void> saveQuotation(
    String leadId, {
    List<Map<String, dynamic>>? lineItems,
    int? noOfPanels,
    double? noOfKW,
    int? noOfSprinklerSet,
    String? typeOfSprinkler,
    String? pumpDetails,
    String? sprinkleType,
    String? upvcPipeSizes,
    String? cableDetails,
    String? upvcFittings,
    String? controlPanel,
    double? pipeLength,
    int? sprinklerQty,
    String? fittings,
    double? labourCost,
    double? transportCost,
    double? totalAmount,
    double? discount,
    double? advancePercent,
    double? balancePercent,
    String? warrantyNote,
    String? notes,
  }) async {
    emit(SprinklerLeadLoading());
    try {
      final updated = await _repo.updateQuotation(
        leadId,
        lineItems: lineItems,
        noOfPanels: noOfPanels,
        noOfKW: noOfKW,
        noOfSprinklerSet: noOfSprinklerSet,
        typeOfSprinkler: typeOfSprinkler,
        pumpDetails: pumpDetails,
        sprinkleType: sprinkleType,
        upvcPipeSizes: upvcPipeSizes,
        cableDetails: cableDetails,
        upvcFittings: upvcFittings,
        controlPanel: controlPanel,
        pipeLength: pipeLength,
        sprinklerQty: sprinklerQty,
        fittings: fittings,
        labourCost: labourCost,
        transportCost: transportCost,
        totalAmount: totalAmount,
        discount: discount,
        advancePercent: advancePercent,
        balancePercent: balancePercent,
        warrantyNote: warrantyNote,
        notes: notes,
      );
      emit(SprinklerLeadSaved(updated));
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── STEP 5: FOLLOWUP (step screen) ───────────────────────────────────────
  Future<void> saveFollowup(
    String leadId, {
    DateTime? followupDate,
    String? response,
    String? customerType,
    String? remarks,
    String? notes,
    String? interestLevel,
    String? followupType,
  }) async {
    emit(SprinklerLeadLoading());
    try {
      final updated = await _repo.updateFollowup(
        leadId,
        followupDate: followupDate,
        response: response,
        customerType: customerType,
        remarks: remarks,
        notes: notes,
        interestLevel: interestLevel,
        followupType: followupType,
      );
      emit(SprinklerLeadSaved(updated));
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── EDIT FOLLOWUP (PATCH — no step advance) ──────────────────────────────
  Future<void> editFollowup(
    String leadId, {
    DateTime? followupDate,
    String? response,
    String? customerType,
    String? remarks,
    String? notes,
  }) async {
    emit(SprinklerLeadLoading());
    try {
      final updated = await _repo.editFollowup(
        leadId,
        followupDate: followupDate,
        response: response,
        customerType: customerType,
        remarks: remarks,
        notes: notes,
      );
      emit(SprinklerLeadSaved(updated));
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── ADD FOLLOWUP ENTRY (history) ─────────────────────────────────────────
  Future<void> addFollowupEntry(
    String leadId, {
    required String remark,
    required String followupType,
    required DateTime nextFollowupDate,
    int? callDuration,
    String? attachment,
  }) async {
    emit(SprinklerLeadLoading());
    try {
      final updated = await _repo.addFollowupEntry(
        leadId,
        remark: remark,
        followupType: followupType,
        nextFollowupDate: nextFollowupDate,
        callDuration: callDuration,
        attachment: attachment,
      );
      emit(SprinklerLeadSaved(updated));
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── GET FOLLOWUP HISTORY ──────────────────────────────────────────────────
  Future<List<FollowupHistoryEntry>> getFollowupHistory(String leadId) async {
    try {
      return await _repo.getFollowupHistory(leadId);
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
      return [];
    }
  }

  // ── MARK FOLLOWUP DONE ────────────────────────────────────────────────────
  Future<void> markFollowupDone(String leadId) async {
    emit(SprinklerLeadLoading());
    try {
      emit(SprinklerLeadSaved(await _repo.markFollowupDone(leadId)));
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── STEP 6: DEAL ─────────────────────────────────────────────────────────
  Future<void> saveDeal(
    String leadId, {
    double? finalDealAmount,
    double? discountGiven,
    double? advancePayment,
    String? paymentMode,
    String? notes,
  }) async {
    emit(SprinklerLeadLoading());
    try {
      final updated = await _repo.updateDeal(
        leadId,
        finalDealAmount: finalDealAmount,
        discountGiven: discountGiven,
        advancePayment: advancePayment,
        paymentMode: paymentMode,
        notes: notes,
      );
      emit(SprinklerLeadSaved(updated));
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── STEP 7 (ADMIN): ASSIGN INSTALLATION TEAM ─────────────────────────────
  Future<void> assignInstaller(
    String leadId, {
    required List<String> installerIds,
    DateTime? scheduledDate,
    String? notes,
  }) async {
    emit(SprinklerLeadLoading());
    try {
      final updated = await _repo.assignInstaller(
        leadId,
        installerIds: installerIds,
        scheduledDate: scheduledDate,
        notes: notes,
      );
      emit(SprinklerLeadSaved(updated));
      fetchAllLeads();
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── STEP 8: INSTALLATION STARTED ───────────────────────────────────────
  Future<void> saveInstallationStarted(
    String leadId, {
    DateTime? startedAt,
    String? notes,
    List<PickedPhoto> beforePhotos = const [],
  }) async {
    emit(SprinklerLeadLoading());
    try {
      final updated = await _repo.startInstallation(
        leadId,
        startedAt: startedAt,
        notes: notes,
        beforePhotos: beforePhotos,
      );
      emit(SprinklerLeadSaved(updated));
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── STEP 9 (INSTALLATION TEAM): COMPLETE INSTALLATION ────────────────────
  Future<void> completeInstallation(
    String leadId, {
    String? technicianName,
    DateTime? installationDate,
    String? materialUsed,
    String? extraMaterial,
    String? workNotes,
    String? notes,
    bool? pendingWork,
    String? pendingWorkNote,
    bool? systemTested,
    bool? paymentReceived,
    DateTime? followUpDate,
    String? completedBy,
    String? customerReview,
    List<PickedPhoto> photos = const [],
  }) async {
    emit(SprinklerLeadLoading());
    try {
      final updated = await _repo.completeInstallation(
        leadId,
        technicianName: technicianName,
        installationDate: installationDate,
        materialUsed: materialUsed,
        extraMaterial: extraMaterial,
        workNotes: workNotes,
        notes: notes,
        pendingWork: pendingWork,
        pendingWorkNote: pendingWorkNote,
        systemTested: systemTested,
        paymentReceived: paymentReceived,
        followUpDate: followUpDate,
        completedBy: completedBy,
        customerReview: customerReview,
        photos: photos,
      );
      emit(SprinklerLeadSaved(updated));
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── LEGACY: saveInstallation (kept for backward compat) ──────────────────
  Future<void> saveInstallation(
    String leadId, {
    String? technicianName,
    DateTime? installationDate,
    String? materialUsed,
    String? extraMaterial,
    String? workNotes,
    String? notes,
    List<PickedPhoto> photos = const [],
  }) async {
    emit(SprinklerLeadLoading());
    try {
      final updated = await _repo.completeInstallation(
        leadId,
        technicianName: technicianName,
        installationDate: installationDate,
        materialUsed: materialUsed,
        extraMaterial: extraMaterial,
        workNotes: workNotes,
        notes: notes,
        photos: photos,
      );
      emit(SprinklerLeadSaved(updated));
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── STEP 10 (ADMIN): PAYMENT ──────────────────────────────────────────────
  Future<void> addPayment(
    String leadId, {
    required double amount,
    required String mode,
    String type = 'partial',
    String? transactionId,
    String? notes,
  }) async {
    emit(SprinklerLeadLoading());
    try {
      final updated = await _repo.addPayment(
        leadId,
        amount: amount,
        mode: mode,
        type: type,
        transactionId: transactionId,
        notes: notes,
      );
      emit(SprinklerLeadSaved(updated));
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // Pending Payment

  Future<void> fetchAllLeadsForPendingPayment() async {
    emit(SprinklerLeadLoading());
    try {
      final result = await _repo.getAllLeads(
        status: 'all', // ← 'Active' ki jagah 'all'
        page: 1,
        limit: 9999,
        // ← date filtering hatao
      );

      // Client side filter
      final filtered = result.leads.where((l) {
        if (l.currentStep.index < SprinklerStep.dealDone.index) return false;
        if (l.currentStep == SprinklerStep.projectCompleted) return false;
        if (l.isCompleted) return false;

        final remaining = l.paymentSummary.remainingBalance > 0
            ? l.paymentSummary.remainingBalance
            : (l.totalAmount - (l.advancePayment ?? 0))
                  .clamp(0, double.infinity)
                  .toDouble();
        return remaining > 0;
      }).toList();

      emit(
        SprinklerLeadsLoaded(
          filtered,
          total: filtered.length,
          page: 1,
          pages: 1,
          tabIndex: 0,
        ),
      );
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
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
      if (l.currentStep == SprinklerStep.projectCompleted) return false;
      if (l.currentStep.index < SprinklerStep.dealDone.index) return false;
      final remaining = l.paymentSummary.remainingBalance > 0
          ? l.paymentSummary.remainingBalance
          : (l.totalAmount - (l.advancePayment ?? 0))
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
      return l.currentStep.index >= SprinklerStep.installationAssigned.index &&
          l.currentStep.index <= SprinklerStep.installationStarted.index;
    }).length;
  } catch (_) {
    return 0;
  }
}

  // ── STEP 11 (ADMIN): REVIEW ───────────────────────────────────────────────
  Future<void> saveReview(
    String leadId, {
    required int rating,
    String? feedback,
    String? notes,
  }) async {
    emit(SprinklerLeadLoading());
    try {
      final updated = await _repo.updateReview(
        leadId,
        rating: rating,
        feedback: feedback,
        notes: notes,
      );
      emit(SprinklerLeadSaved(updated));
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
    }
  }

  // ── INSTALLATION TEAM: GET MY ASSIGNED LEADS ─────────────────────────────
  Future<List<SprinklerLeadModel>> fetchMyInstallationLeads({
    String? status,
    String? search,
  }) async {
    try {
      return await _repo.getMyInstallationLeads(status: status, search: search);
    } catch (e) {
      emit(SprinklerLeadError(_message(e)));
      return [];
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────
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
