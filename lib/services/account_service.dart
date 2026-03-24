import 'package:birthday/data/models/account_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountService {
  static const _key = 'account_profile';

  Future<AccountProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return const AccountProfile();
    return AccountProfile.fromJson(json);
  }

  Future<void> save(AccountProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, profile.toJson());
  }
}
