import 'package:birthday/core/constants/app_constants.dart';
import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String formatBirthday(DateTime birthday) {
    if (birthday.year == AppConstants.unknownYear) {
      return DateFormat("d 'de' MMMM", 'pt_BR').format(birthday);
    }
    return DateFormat("d 'de' MMMM 'de' yyyy", 'pt_BR').format(birthday);
  }

  static String formatBirthdayShort(DateTime birthday) {
    return DateFormat("d 'de' MMM", 'pt_BR').format(birthday);
  }

  static String formatMonthDay(DateTime date) {
    return DateFormat("d 'de' MMM", 'pt_BR').format(date);
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatDateForDb(DateTime date) {
    return date.toIso8601String();
  }

  static DateTime parseDateFromDb(String iso) {
    return DateTime.parse(iso);
  }
}
