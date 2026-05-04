class ApiEndpoints {
  ApiEndpoints._();

  // Base resources
  static const String auth = '/auth';
  static const String admin = '/admin';
  static const String service = '/service';
  static const String material = '/material';
  static const String solarLead = '/solar_lead';
  static const String sprinklerLead = '/sprinkler_lead';
  static const String installationMyLeads = '/installation/my-leads';

  // Dashboard & reports
  static const String dashboardOwner = '/dashboard/owner';
  static const String reportsMonthly = '/reports/monthly';
  static const String reportsPayments = '/reports/payments';

  // Auth
  static const String authLogin = '$auth/login';
  static const String authLogout = '$auth/logout';
  static const String authChangePassword = '$auth/change-password';
  static const String authProfile = '$auth/profile';
  static const String authFcmToken = '$auth/fcm-token';

  // Admin
  static const String adminStaff = '$admin/staff';
  static const String adminUsers = '$admin/users';
  static String adminById(String id) => '$admin/$id';
  static String adminStatus(String id) => '$admin/$id/status';
  static String adminResetPassword(String id) => '$admin/$id/reset-password';

  // Service
  static String serviceById(String id) => '$service/$id';
  static String serviceAssign(String id) => '$service/$id/assign';
  static String servicePayment(String id) => '$service/$id/payment';
  static String servicePhotos(String id) => '$service/$id/photos';

  // Material
  static const String materialSchema = '$material/schema';
  static String materialById(String id) => '$material/$id';

  static const String materialCustomer = '$material/customer';
  static const String materialCustomerSchema = '$materialCustomer/schema';
  static String materialCustomerById(String id) => '$materialCustomer/$id';
  static String materialCustomerPipeline(String id) => '$materialCustomer/$id/pipeline';
  static String materialCustomerFollowupDone(String id) => '$materialCustomer/$id/followup-done';

  static const String materialSalesStaff = '$material/sales-staff';

  // Installation
  static String installationStart(String id) => '$installationMyLeads/$id/start';
  static String installationDone(String id) => '$installationMyLeads/$id/installation';
  static String installationMeter(String id) => '$installationMyLeads/$id/meter';
  static String installationPayment(String id) => '$installationMyLeads/$id/payment';
  static String installationNotes(String id) => '$installationMyLeads/$id/notes';
  static String installationComplete(String id) => '$installationMyLeads/$id/complete';

  // Solar leads
  static String solarById(String id) => '$solarLead/$id';
  static String solarStep(String id, String step) => '$solarLead/$id/$step';
  static String solarQuotationPdf(String id) => '$solarLead/$id/quotation-pdf';

  // Sprinkler leads
  static String sprinklerById(String id) => '$sprinklerLead/$id';
  static String sprinklerStep(String id, String step) => '$sprinklerLead/$id/$step';
  static String sprinklerQuotationPdf(String id) => '$sprinklerLead/$id/quotation-pdf';
}
