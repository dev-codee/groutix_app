import 'package:intl/intl.dart';

class DateFormatter {
  static String formatAppt(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '—';
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('EEE, d MMM yyyy • h:mm a').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  static String formatApptDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('EEE, d MMM').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  static String formatApptTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  static String formatRelative(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '—';
    try {
      final dt = DateTime.parse(isoString);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('d MMM yyyy').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  static String formatCurrency(num? amount) {
    if (amount == null) return '\$0.00';
    final formatter = NumberFormat.currency(locale: 'en_AU', symbol: '\$');
    return formatter.format(amount);
  }

  static bool isSameDay(String? isoString, DateTime target) {
    if (isoString == null || isoString.isEmpty) return false;
    try {
      final dt = DateTime.parse(isoString);
      return dt.year == target.year && dt.month == target.month && dt.day == target.day;
    } catch (_) {
      return false;
    }
  }

  static String formatTodayHeader() {
    return DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());
  }
}

