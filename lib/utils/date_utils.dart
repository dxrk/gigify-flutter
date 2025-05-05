import 'package:intl/intl.dart';

class ConcertDateUtils {
  static String formatDate(DateTime date, String pattern) {
    final localDate = date.toLocal();
    return DateFormat(pattern, 'en_US').format(localDate);
  }

  static String formatTime(DateTime date) {
    final localDate = date.toLocal();
    return DateFormat('h:mm a', 'en_US').format(localDate);
  }

  static String getFormattedStartTimeTruncated(DateTime date) {
    return formatDate(date, 'M/d/y');
  }

  static String getFormattedStartTime(DateTime date) {
    final formattedTime = formatTime(date);
    return formattedTime == '12:00 AM'
        ? formatDate(date, 'M/d/y')
        : '${formatDate(date, 'M/d/y')} at $formattedTime';
  }
}
