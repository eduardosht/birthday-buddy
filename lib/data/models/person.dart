import 'package:uuid/uuid.dart';
import 'package:birthday/core/constants/app_constants.dart';
import 'package:birthday/core/utils/birthday_utils.dart';

class Person {
  final String id;
  final String groupId;
  final String name;
  final DateTime birthday;
  final String? photoPath;
  final String? contactId;
  final String? phoneNumber;
  final String? notes;
  final DateTime createdAt;

  const Person({
    required this.id,
    required this.groupId,
    required this.name,
    required this.birthday,
    this.photoPath,
    this.contactId,
    this.phoneNumber,
    this.notes,
    required this.createdAt,
  });

  // Computed
  int get daysUntilNextBirthday => BirthdayUtils.daysUntilBirthday(birthday);
  bool get isBirthdayToday => BirthdayUtils.isBirthdayToday(birthday);
  bool get isAlertThreshold => BirthdayUtils.isAlertThreshold(birthday);
  bool get hasKnownYear => birthday.year != AppConstants.unknownYear;

  factory Person.create({
    required String groupId,
    required String name,
    required DateTime birthday,
    String? photoPath,
    String? contactId,
    String? phoneNumber,
    String? notes,
  }) {
    return Person(
      id: const Uuid().v4(),
      groupId: groupId,
      name: name,
      birthday: birthday,
      photoPath: photoPath,
      contactId: contactId,
      phoneNumber: phoneNumber,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  Person copyWith({
    String? groupId,
    String? name,
    DateTime? birthday,
    String? photoPath,
    String? contactId,
    String? phoneNumber,
    String? notes,
  }) {
    return Person(
      id: id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      birthday: birthday ?? this.birthday,
      photoPath: photoPath ?? this.photoPath,
      contactId: contactId ?? this.contactId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  Person copyWithoutPhoto() {
    return Person(
      id: id,
      groupId: groupId,
      name: name,
      birthday: birthday,
      photoPath: null,
      contactId: contactId,
      phoneNumber: phoneNumber,
      notes: notes,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'name': name,
      'birthday': birthday.toIso8601String(),
      'photoPath': photoPath,
      'contactId': contactId,
      'phoneNumber': phoneNumber,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Person.fromMap(Map<String, dynamic> map) {
    return Person(
      id: map['id'] as String,
      groupId: map['groupId'] as String,
      name: map['name'] as String,
      birthday: DateTime.parse(map['birthday'] as String),
      photoPath: map['photoPath'] as String?,
      contactId: map['contactId'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Person && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

