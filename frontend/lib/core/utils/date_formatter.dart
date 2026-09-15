import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  /// Formats YYYY-MM-DD into "Wed 16"
  static String formatShortDay(String yyyyMmDd) {
    try {
      final date = DateTime.parse(yyyyMmDd);
      return DateFormat('E d').format(date);
    } catch (_) {
      return yyyyMmDd;
    }
  }

  /// Returns weekday abbreviation: "Wed", "Thu"
  static String formatWeekday(String yyyyMmDd) {
    try {
      final date = DateTime.parse(yyyyMmDd);
      return DateFormat('E').format(date);
    } catch (_) {
      return '';
    }
  }

  /// Returns day number: "16", "17"
  static String formatDayNum(String yyyyMmDd) {
    try {
      final date = DateTime.parse(yyyyMmDd);
      return DateFormat('d').format(date);
    } catch (_) {
      return '';
    }
  }

  /// Formats YYYY-MM-DD into "Wed, Oct 16"
  static String formatFullDate(String yyyyMmDd) {
    try {
      final date = DateTime.parse(yyyyMmDd);
      return DateFormat('EEE, MMM d').format(date);
    } catch (_) {
      return yyyyMmDd;
    }
  }

  /// Formats Month & Year: "Oct 2024"
  static String formatMonthYear(String yyyyMmDd) {
    try {
      final date = DateTime.parse(yyyyMmDd);
      return DateFormat('MMM yyyy').format(date);
    } catch (_) {
      return '';
    }
  }

  /// Formats remaining duration into "02h 14m remaining" or "45m remaining"
  static String formatRemaining(Duration remaining) {
    if (remaining.isNegative || remaining.inSeconds <= 0) {
      return 'Editing closed';
    }

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m remaining';
    } else if (minutes > 0) {
      return '${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s remaining';
    } else {
      return '${seconds}s remaining';
    }
  }
}
