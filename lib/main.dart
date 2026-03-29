import 'dart:async';
import 'package:birthday/app.dart';
import 'package:birthday/core/constants/app_constants.dart';
import 'package:birthday/data/database/database_helper.dart';
import 'package:birthday/data/repositories/person_repository.dart';
import 'package:birthday/services/checked_today_service.dart';
import 'package:birthday/services/notification_service.dart';
import 'package:birthday/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize Firebase & Crashlytics first so all errors are captured
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      await FirebaseCrashlytics.instance.log('App starting - supabaseUrl empty: ${AppConstants.supabaseUrl.isEmpty}');
      AppConstants.validateEnv();

      // Initialize pt_BR locale for date formatting
      await initializeDateFormatting('pt_BR', null);

      // Initialize Supabase
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        anonKey: AppConstants.supabaseAnonKey,
      );

      // Initialize RevenueCat
      await Purchases.setLogLevel(LogLevel.debug);
      await Purchases.configure(
        PurchasesConfiguration(AppConstants.revenueCatApiKey),
      );

      // If user is already logged in, identify them in RevenueCat
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Purchases.logIn(user.id);
      }

      // Initialize database
      await DatabaseHelper.instance.database;

      // Initialize notifications
      await NotificationService.instance.initialize();

      // Reschedule all notifications on cold start (repairs after device reboot)
      final allPeople = await PersonRepository(
        DatabaseHelper.instance,
      ).getAll();
      await NotificationService.instance.rescheduleAll(allPeople);

      // Schedule hourly today-notifications for people whose birthday is today
      for (final person in allPeople) {
        if (person.isBirthdayToday) {
          final checked = await CheckedTodayService.isChecked(person.id);
          if (!checked) {
            await NotificationService.instance.scheduleHourlyTodayNotifs(
              person,
            );
          }
        }
      }

      runApp(const ProviderScope(child: BirthdayApp()));
    },
    (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}
