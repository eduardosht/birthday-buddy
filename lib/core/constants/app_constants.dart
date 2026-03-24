import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  // ── Supabase ─────────────────────────────────────────────────────────────
  static String get supabaseUrl => dotenv.env['SUPABASE_URL']!;
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY']!;

  // ── RevenueCat ───────────────────────────────────────────────────────────
  static String get revenueCatApiKey => dotenv.env['REVENUE_CAT_API_KEY']!;
  static const String rcEntitlementId = 'Birthday Buddy Pro';
  static const String rcMonthlyProductId = 'monthly';
  static const String rcYearlyProductId = 'yearly';

  static const int alertThresholdDays = 2;
  static const String notificationChannelId = 'birthday_channel';
  static const String notificationChannelName = 'Birthday Reminders';
  static const String hourlyChannelId = 'birthday_today_channel';
  static const String hourlyChannelName = 'Aniversários de Hoje';
  static const int birthdayNotifBaseId = 1000;
  static const int reminderNotifBaseId = 2000;
  // Hourly IDs: 3000 + (personHash % 900) * 100 + hourOffset (0–14)
  static const int hourlyNotifBaseId = 3000;
  static const int birthdayNotifHour = 8;
  static const int reminderNotifHour = 9;
  // Hourly alerts fire from 8am to 10pm (15 slots)
  static const int hourlyStartHour = 8;
  static const int hourlyEndHour = 22;
  static const String avatarsDirectory = 'avatars';
  static const int unknownYear = 1900;
}
