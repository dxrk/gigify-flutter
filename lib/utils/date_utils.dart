import 'package:intl/intl.dart';

class DateUtils {
  static String formatDate(DateTime date, String format) {
    final DateFormat formatter = DateFormat(format);
    return formatter.format(date);
  }

  static String formatReadable(DateTime date) {
    return DateFormat('EEEE, MMMM d, y').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('E, MMM d, y • h:mm a').format(date);
  }

  static String getRelativeTimeDescription(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final nextWeek = today.add(const Duration(days: 7));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == tomorrow) {
      return 'Tomorrow';
    } else if (dateOnly.isAfter(tomorrow) && dateOnly.isBefore(nextWeek)) {
      final weekday = DateFormat('EEEE').format(date);
      return 'This $weekday';
    } else if (dateOnly.difference(today).inDays < 14) {
      final days = dateOnly.difference(today).inDays;
      return 'In $days days';
    } else if (dateOnly.difference(today).inDays < 30) {
      final weekday = DateFormat('EEEE').format(date);
      return 'In a few weeks, on $weekday';
    } else if (dateOnly.month == today.month && dateOnly.year == today.year) {
      return 'Later this month';
    } else if ((dateOnly.month == today.month + 1 &&
            dateOnly.year == today.year) ||
        (today.month == 12 &&
            dateOnly.month == 1 &&
            dateOnly.year == today.year + 1)) {
      return 'Next month';
    } else {
      return 'In ${DateFormat('MMMM').format(date)}';
    }
  }

  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  static bool isEvening(DateTime date) {
    return date.hour >= 18;
  }

  static int daysBetween(DateTime from, DateTime to) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);
    return toDate.difference(fromDate).inDays;
  }

  static List<DateTime> getDatesBetween(DateTime startDate, DateTime endDate) {
    final days = endDate.difference(startDate).inDays;
    return List.generate(
        days + 1, (index) => startDate.add(Duration(days: index)));
  }

  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime getEndOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  static bool datesOverlap(
      DateTime start1, DateTime end1, DateTime start2, DateTime end2) {
    return start1.isBefore(end2) && end1.isAfter(start2);
  }

  static String formatForApi(DateTime date) {
    return date.toUtc().toIso8601String();
  }
}
