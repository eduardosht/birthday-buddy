import 'package:birthday/core/constants/app_constants.dart';

class BirthdayUtils {
  BirthdayUtils._();

  static bool isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  static DateTime safeDate(int year, int month, int day) {
    if (month == 2 && day == 29 && !isLeapYear(year)) {
      return DateTime(year, 2, 28);
    }
    return DateTime(year, month, day);
  }

  static DateTime nextBirthdayDate(DateTime birthday) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var next = safeDate(now.year, birthday.month, birthday.day);
    if (next.isBefore(today)) {
      next = safeDate(now.year + 1, birthday.month, birthday.day);
    }
    return next;
  }

  static int daysUntilBirthday(DateTime birthday) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final next = nextBirthdayDate(birthday);
    return next.difference(today).inDays;
  }

  static bool isBirthdayToday(DateTime birthday) {
    return daysUntilBirthday(birthday) == 0;
  }

  static bool isAlertThreshold(DateTime birthday) {
    final days = daysUntilBirthday(birthday);
    return days > 0 && days <= AppConstants.alertThresholdDays;
  }

  static int? calculateAge(DateTime birthday) {
    if (birthday.year == AppConstants.unknownYear) return null;
    final now = DateTime.now();
    int age = now.year - birthday.year;
    if (now.month < birthday.month ||
        (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return age;
  }

  static int? calculateTurningAge(DateTime birthday) {
    if (birthday.year == AppConstants.unknownYear) return null;
    return DateTime.now().year - birthday.year;
  }

  static String countdownText(int days) {
    if (days == 0) return 'Hoje!';
    if (days == 1) return 'Amanhã!';
    return 'Em $days dias';
  }
}

