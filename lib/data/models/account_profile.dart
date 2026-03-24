import 'dart:convert';

enum AccountPlan { free, pro }

class AccountProfile {
  final String? name;
  final DateTime? birthday;
  final String? photoPath;
  final AccountPlan plan;
  final DateTime? planExpiresAt;

  const AccountProfile({
    this.name,
    this.birthday,
    this.photoPath,
    this.plan = AccountPlan.free,
    this.planExpiresAt,
  });

  bool get isPro => plan == AccountPlan.pro;
  bool get isFree => plan == AccountPlan.free;

  // Free plan limits
  static const int freeMaxGroups = 1;
  static const int freeMaxPeople = 10;

  AccountProfile copyWith({
    String? name,
    DateTime? birthday,
    String? photoPath,
    AccountPlan? plan,
    DateTime? planExpiresAt,
    bool clearPhoto = false,
    bool clearBirthday = false,
    bool clearPlanExpiry = false,
  }) {
    return AccountProfile(
      name: name ?? this.name,
      birthday: clearBirthday ? null : (birthday ?? this.birthday),
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      plan: plan ?? this.plan,
      planExpiresAt: clearPlanExpiry ? null : (planExpiresAt ?? this.planExpiresAt),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'birthday': birthday?.toIso8601String(),
    'photoPath': photoPath,
    'plan': plan.name,
    'planExpiresAt': planExpiresAt?.toIso8601String(),
  };

  factory AccountProfile.fromMap(Map<String, dynamic> map) => AccountProfile(
    name: map['name'] as String?,
    birthday: map['birthday'] != null ? DateTime.parse(map['birthday'] as String) : null,
    photoPath: map['photoPath'] as String?,
    plan: AccountPlan.values.firstWhere(
      (e) => e.name == map['plan'],
      orElse: () => AccountPlan.free,
    ),
    planExpiresAt: map['planExpiresAt'] != null
        ? DateTime.parse(map['planExpiresAt'] as String)
        : null,
  );

  String toJson() => jsonEncode(toMap());
  factory AccountProfile.fromJson(String source) =>
      AccountProfile.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
