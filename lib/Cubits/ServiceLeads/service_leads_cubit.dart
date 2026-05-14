// lib/Cubits/ServiceLeads/service_leads_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_state.dart';
import 'package:solar_project/Helper/picked_photo.dart';
import 'package:solar_project/data/Repository/service_repository.dart';

class ServiceLeadCubit extends Cubit<ServiceLeadState> {
  final ServiceRepository _repo;

  // Tab-wise total counts (for tab badge numbers)
  final Map<int, int> _tabTotals = {0: 0, 1: 0, 2: 0};

  ServiceLeadCubit({ServiceRepository? repo})
    : _repo = repo ?? ServiceRepository(),
      super(ServiceLeadInitial());

  int getTabTotal(int tabIndex) => _tabTotals[tabIndex] ?? 0;

  // ── Fetch all services ─────────────────────────────────────────────────────
  Future<void> fetchAllServices({
    int page = 1,
    String? search,
    String? status,
    int tabIndex = 0,
  }) async {
    emit(ServiceLeadLoading());
    try {
      final result = await _repo.getAllServices(
        page: page,
        search: search,
        status: status,
        tabIndex: tabIndex,
      );

      final services = result['services'] as List<dynamic>;
      final total = result['total'] as int;
      final pages = result['pages'] as int;

      // ✅ Store all 3 tab counts at once from backend response
      final tabCounts = result['tabCounts'] as Map<String, dynamic>?;
      if (tabCounts != null) {
        _tabTotals[0] =
            (tabCounts['recent'] as num?)?.toInt() ?? _tabTotals[0] ?? 0;
        _tabTotals[1] =
            (tabCounts['older'] as num?)?.toInt() ?? _tabTotals[1] ?? 0;
        _tabTotals[2] =
            (tabCounts['completed'] as num?)?.toInt() ?? _tabTotals[2] ?? 0;
      } else {
        _tabTotals[tabIndex] = total;
      }

      emit(
        ServiceLeadsLoaded(
          services: services.cast(),
          total: total,
          page: page,
          pages: pages,
          tabIndex: tabIndex,
        ),
      );
    } catch (e) {
      emit(ServiceLeadError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  // ── Tab switch ─────────────────────────────────────────────────────────────
  Future<void> setTabAndFetch(int tabIndex) async {
    await fetchAllServices(page: 1, tabIndex: tabIndex);
  }

  // ── Page change ────────────────────────────────────────────────────────────
  Future<void> fetchPage(int page, {required int tabIndex}) async {
    await fetchAllServices(page: page, tabIndex: tabIndex);
  }

  // ── Create ─────────────────────────────────────────────────────────────────
  Future<void> createService(Map<String, dynamic> data) async {
    try {
      final service = await _repo.createService(data);
      emit(ServiceLeadSaved(service));
      await fetchAllServices();
    } catch (e) {
      emit(ServiceLeadError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  // ── Update ─────────────────────────────────────────────────────────────────
  Future<void> updateService(String id, Map<String, dynamic> data) async {
    try {
      final service = await _repo.updateService(id, data);
      emit(ServiceLeadSaved(service));
      await fetchAllServices();
    } catch (e) {
      emit(ServiceLeadError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  // ── Add payment ────────────────────────────────────────────────────────────
  Future<void> addPayment(String id, double amount, String mode) async {
    try {
      final service = await _repo.addPayment(id, amount, mode);
      emit(ServiceLeadSaved(service));
      await fetchAllServices();
    } catch (e) {
      emit(ServiceLeadError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  // ── Upload photos ──────────────────────────────────────────────────────────
  Future<void> uploadPhotos(
    String id, {
    List<PickedPhoto> beforePhotos = const [],
    List<PickedPhoto> afterPhotos = const [],
  }) async {
    try {
      final service = await _repo.uploadPhotos(
        id,
        beforePhotos: beforePhotos,
        afterPhotos: afterPhotos,
      );
      emit(ServiceLeadSaved(service));
      await fetchAllServices();
    } catch (e) {
      emit(ServiceLeadError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────
  Future<void> deleteService(String id) async {
    try {
      await _repo.deleteService(id);
      await fetchAllServices();
    } catch (e) {
      emit(ServiceLeadError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
