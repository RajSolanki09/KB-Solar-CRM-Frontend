// lib/Cubits/ServiceLeads/service_leads_state.dart

import 'package:solar_project/data/Models/service_request_model.dart';

abstract class ServiceLeadState {}

class ServiceLeadInitial extends ServiceLeadState {}
class ServiceLeadLoading extends ServiceLeadState {}

class ServiceLeadsLoaded extends ServiceLeadState {
  final List<ServiceRequestModel> services;
  ServiceLeadsLoaded(this.services);
}

class ServiceLeadSaved extends ServiceLeadState {
  final ServiceRequestModel service;
  ServiceLeadSaved(this.service);
}

class ServiceLeadError extends ServiceLeadState {
  final String message;
  ServiceLeadError(this.message);
}