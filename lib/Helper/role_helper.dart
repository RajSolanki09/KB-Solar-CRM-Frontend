// lib/Helper/role_helper.dart
// Single source of truth for all role-based permissions

import 'package:solar_project/Cubits/Auth/auth_state.dart';

class RoleHelper {
  // ── Read role from AppState ───────────────────────────────────────────────
  static UserRole roleFrom(AppState state) {
    if (state is Authenticated) return state.role;
    return UserRole.sales; // safest default — least permissions
  }

  // ── Permission checks ─────────────────────────────────────────────────────
  static bool canAddLead(UserRole r)          => r == UserRole.admin || r == UserRole.sales;
  static bool canEditLead(UserRole r)         => r == UserRole.admin || r == UserRole.sales;
  static bool canDeleteLead(UserRole r)       => r == UserRole.admin;
  static bool canDoSiteVisit(UserRole r)      => r == UserRole.admin || r == UserRole.sales;
  static bool canDoQuotation(UserRole r)      => r == UserRole.admin || r == UserRole.sales;
  static bool canDoTechVisit(UserRole r)      => r == UserRole.admin || r == UserRole.sales;
  static bool canDoFollowup(UserRole r)       => r == UserRole.admin || r == UserRole.sales;
  static bool canDoDeal(UserRole r)           => r == UserRole.admin || r == UserRole.sales;
  static bool canDoInstallation(UserRole r)   => r == UserRole.admin;  // Sales ❌
  static bool canAddPayment(UserRole r)       => true;                  // all roles
  static bool canDoReview(UserRole r)         => true;                  // all roles
  static bool canViewReports(UserRole r)      => r == UserRole.admin;
  static bool isViewOnly(UserRole r)          => r == UserRole.service;

  // ── Per-step check (used in detail screen switch) ─────────────────────────
  static bool canDoStep(UserRole r, int stepIndex) {
    // stepIndex matches SprinklerStep / SolarStep index
    // 0=new, 1=siteVisit, 2=quotation, 3=techVisit, 4=followup,
    // 5=dealDone, 6=installation, 7=payment, 8=review
    if (r == UserRole.admin)   return true;
    if (r == UserRole.service) return stepIndex >= 7; // payment + review only
    // sales: all except installation (index 6)
    return stepIndex != 6;
  }
}