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

  /// Formats remaining duration into concise format: "7d 19h left", "02h 14m left", or "45m 12s left"
  static String formatRemaining(Duration remaining) {
    if (remaining.isNegative || remaining.inSeconds <= 0) {
      return 'Editing closed';
    }

    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    if (days > 0) {
      if (hours > 0) {
        return '${days}d ${hours}h left';
      }
      return '${days}d left';
    } else if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m left';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds.toString().padLeft(2, '0')}s left';
    } else {
      return '${seconds}s left';
    }
  }

  /// Formats cutoff deadline relative to delivery or today: e.g. "today, 8:30 PM", "tomorrow, 8:30 PM", or "24 Sep, 8:30 PM"
  static String formatCutoffDeadline(DateTime cutoffDate) {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final targetDay = DateTime(cutoffDate.year, cutoffDate.month, cutoffDate.day);
      final differenceInDays = targetDay.difference(today).inDays;

      final timeStr = DateFormat('h:mm a').format(cutoffDate);

      if (differenceInDays == 0) {
        return 'today, $timeStr';
      } else if (differenceInDays == 1) {
        return 'tomorrow, $timeStr';
      } else {
        final dateStr = DateFormat('d MMM').format(cutoffDate);
        return '$dateStr, $timeStr';
      }
    } catch (_) {
      return '8:30 PM';
    }
  }
}
