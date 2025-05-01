import 'package:intl/intl.dart';

class DateUtils {
  static String formatDate(DateTime date, String pattern) {
    final localDate = date.toLocal();
    return DateFormat(pattern, 'en_US').format(localDate);
  }

  static String formatReadable(DateTime date) {
    final localDate = date.toLocal();
    return DateFormat('EEEE, MMMM d, y', 'en_US').format(localDate);
  }

  static String formatTime(DateTime date) {
    final localDate = date.toLocal();
    return DateFormat('h:mm a', 'en_US').format(localDate);
  }

  static String formatDateTime(DateTime date) {
    final localDate = date.toLocal();
    return DateFormat('E, MMM d, y • h:mm a', 'en_US').format(localDate);
  }

  static String getRelativeTimeDescription(DateTime date) {
    final now = DateTime.now().toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final nextWeek = today.add(const Duration(days: 7));
    final dateOnly =
        DateTime(date.toLocal().year, date.toLocal().month, date.toLocal().day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == tomorrow) {
      return 'Tomorrow';
    } else if (dateOnly.isAfter(tomorrow) && dateOnly.isBefore(nextWeek)) {
      final weekday = DateFormat('EEEE', 'en_US').format(dateOnly);
      return 'This $weekday';
    } else if (dateOnly.difference(today).inDays < 14) {
      final days = dateOnly.difference(today).inDays;
      return 'In $days days';
    } else if (dateOnly.difference(today).inDays < 30) {
      final weekday = DateFormat('EEEE', 'en_US').format(dateOnly);
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
      return 'In ${DateFormat('MMMM', 'en_US').format(dateOnly)}';
    }
  }

  static bool isWeekend(DateTime date) {
    final wd = date.toLocal().weekday;
    return wd == DateTime.saturday || wd == DateTime.sunday;
  }

  static bool isEvening(DateTime date) {
    return date.toLocal().hour >= 18;
  }

  static int daysBetween(DateTime from, DateTime to) {
    final fromDate =
        DateTime(from.toLocal().year, from.toLocal().month, from.toLocal().day);
    final toDate =
        DateTime(to.toLocal().year, to.toLocal().month, to.toLocal().day);
    return toDate.difference(fromDate).inDays;
  }

  static List<DateTime> getDatesBetween(DateTime startDate, DateTime endDate) {
    final start = DateTime(startDate.toLocal().year, startDate.toLocal().month,
        startDate.toLocal().day);
    final end = DateTime(
        endDate.toLocal().year, endDate.toLocal().month, endDate.toLocal().day);
    final days = end.difference(start).inDays;
    return List.generate(days + 1, (i) => start.add(Duration(days: i)));
  }

  static DateTime getStartOfMonth(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, 1);
  }

  static DateTime getEndOfMonth(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month + 1, 0);
  }

  static bool datesOverlap(
      DateTime start1, DateTime end1, DateTime start2, DateTime end2) {
    final a1 = start1.toLocal();
    final b1 = end1.toLocal();
    final a2 = start2.toLocal();
    final b2 = end2.toLocal();
    return a1.isBefore(b2) && b1.isAfter(a2);
  }

  static String formatForApi(DateTime date) {
    return date.toUtc().toIso8601String();
  }
}
