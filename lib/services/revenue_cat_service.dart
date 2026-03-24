import 'package:birthday/core/constants/app_constants.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  RevenueCatService._();
  static final RevenueCatService instance = RevenueCatService._();

  /// Returns true if the user has an active "Birthday Buddy Pro" entitlement.
  Future<bool> isPro() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.all[AppConstants.rcEntitlementId]?.isActive ==
          true;
    } catch (_) {
      return false;
    }
  }

  /// Fetches full CustomerInfo (for UI display).
  Future<CustomerInfo?> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (_) {
      return null;
    }
  }

  /// Log the Supabase user into RevenueCat so purchases are tied to the account.
  Future<void> logIn(String userId) async {
    try {
      await Purchases.logIn(userId);
    } catch (_) {}
  }

  /// Log out of RevenueCat (on Supabase sign-out).
  Future<void> logOut() async {
    try {
      await Purchases.logOut();
    } catch (_) {}
  }
}
