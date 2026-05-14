import 'package:flutter/material.dart';

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
      return Colors.blue;
    case "Visit":
      return Colors.orange;
    case "Quotation Sent":
      return Colors.purple;
    case "Followup":
      return Colors.amber;
    case "Deal Done":
      return Colors.green;
    case "Portal Update":
      return Colors.cyan;
    case "Installation":
      return Colors.teal;
    case "Meter Process":
      return Colors.indigo;
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

