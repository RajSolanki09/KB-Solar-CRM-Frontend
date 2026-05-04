// lib/Cubits/ServiceLeads/service_leads_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/ServiceLeads/service_leads_state.dart';
import 'package:solar_project/Helper/picked_photo.dart';
import 'package:solar_project/data/Repository/service_repository.dart';

class ServiceLeadCubit extends Cubit<ServiceLeadState> {
  final ServiceRepository _repo;

  ServiceLeadCubit({ServiceRepository? repo})
      : _repo = repo ?? ServiceRepository(),
        super(ServiceLeadInitial());

  // ── Fetch all services (role-filtered by backend) ──────────────────────────
  Future<void> fetchAllServices() async {
    emit(ServiceLeadLoading());
    try {
      final list = await _repo.getAllServices();
      emit(ServiceLeadsLoaded(list));
    } catch (e) {
      emit(ServiceLeadError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  // ── Create new service request (admin only) ────────────────────────────────
  Future<void> createService(Map<String, dynamic> data) async {
    try {
      final service = await _repo.createService(data);
      emit(ServiceLeadSaved(service));
      await fetchAllServices();
    } catch (e) {
      emit(ServiceLeadError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  // ── Update service (status, notes, etc.) ──────────────────────────────────
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

  // ── Upload service photos ─────────────────────────────────────────────────
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

  // ── Delete service (admin only) ────────────────────────────────────────────
  Future<void> deleteService(String id) async {
    try {
      await _repo.deleteService(id);
      await fetchAllServices();
    } catch (e) {
      emit(ServiceLeadError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}