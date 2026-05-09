import 'package:flutter/material.dart';
import 'package:solar_project/core/app_colors.dart';

class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= 600 && w < 1024;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;
}

//--------------------  Status Color Helper ---------------------------

Color getStatusColor(String status) {
  switch (status) {
    case "New":
      return AppColors.primary;
    case "Visit":
      return AppColors.solar;
    case "Quotation Sent":
      return AppColors.primary;
    case "Followup":
      return Colors.amber;
    case "Deal Done":
      return AppColors.success;
    case "Portal Update":
      return Colors.cyan;
    case "Installation":
      return Colors.teal;
    case "Meter Process":
      return AppColors.primary;
    case "Subsidy Form":
      return Colors.deepOrange;
    case "Payment":
      return Colors.lightGreen;
    case "Completed":
      return Colors.grey;
    default:
      return Colors.black;
  }
}
