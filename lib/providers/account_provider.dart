import 'package:birthday/data/models/account_profile.dart';
import 'package:birthday/services/account_service.dart';
import 'package:birthday/services/revenue_cat_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final accountServiceProvider = Provider<AccountService>((ref) => AccountService());

class AccountNotifier extends AsyncNotifier<AccountProfile> {
  @override
  Future<AccountProfile> build() async {
    final profile = await ref.read(accountServiceProvider).load();
    // Always derive plan from RevenueCat entitlement (source of truth)
    final isPro = await RevenueCatService.instance.isPro();
    return profile.copyWith(plan: isPro ? AccountPlan.pro : AccountPlan.free);
  }

  Future<void> save(AccountProfile profile) async {
    await ref.read(accountServiceProvider).save(profile);
    state = AsyncData(profile);
  }

  /// Re-checks RevenueCat entitlement and updates the plan in state.
  Future<void> refreshPlan() async {
    final current = state.valueOrNull ?? const AccountProfile();
    final isPro = await RevenueCatService.instance.isPro();
    final updated = current.copyWith(
      plan: isPro ? AccountPlan.pro : AccountPlan.free,
    );
    await ref.read(accountServiceProvider).save(updated);
    state = AsyncData(updated);
  }
}

final accountProvider =
    AsyncNotifierProvider<AccountNotifier, AccountProfile>(AccountNotifier.new);
