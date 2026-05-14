import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimeHelper {
  static Future<DateTime?> pickPastDate(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: firstDate ?? DateTime(2023),
      lastDate: lastDate ?? now,
    );
  }

  /// Date picker with custom accent color (used in service/admin screens).
  static Future<DateTime?> pickDateThemed(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    required Color accentColor,
  }) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: firstDate ?? DateTime(2023),
      lastDate: lastDate ?? DateTime(2027),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: accentColor,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
  }

  /// Returns the cutoff DateTime below which items are considered "older"
  /// (defaults to 7 days ago, i.e. last 6 full days + today).
  static DateTime recentCutoff({int days = 6}) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days));
  }

  /// Whether [date] falls within the "recent" window.
  static bool isRecent(DateTime date, {int days = 6}) =>
      !date.isBefore(recentCutoff(days: days));

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String leadDateFilterLabel(DateTime? selectedDate) {
    if (selectedDate == null) return 'All Dates';

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final selectedOnly = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    if (isSameDay(selectedOnly, todayOnly)) return 'Today';
    if (selectedOnly.difference(todayOnly).inDays == -1) return 'Yesterday';

    return formatDate(selectedDate);
  }

  static String formatDate(DateTime date, {String pattern = 'dd MMM yyyy'}) {
    return DateFormat(pattern).format(date.toLocal());
  }

  static String formatTime(DateTime date, {String pattern = 'hh:mm a'}) {
    return DateFormat(pattern).format(date.toLocal());
  }

  static String formatDateTime(
    DateTime date, {
    String datePattern = 'dd MMM yyyy',
    String timePattern = 'hh:mm a',
    String separator = ', ',
  }) {
    final dateText = formatDate(date, pattern: datePattern);
    final timeText = formatTime(date, pattern: timePattern);
    return '$dateText$separator$timeText';
  }
}
