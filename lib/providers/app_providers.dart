import 'package:birthday/data/database/database_helper.dart';
import 'package:birthday/data/models/group.dart';
import 'package:birthday/data/models/person.dart';
import 'package:birthday/data/repositories/group_repository.dart';
import 'package:birthday/data/repositories/person_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- Database ---

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

// --- Repositories ---

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository(ref.watch(databaseHelperProvider));
});

final personRepositoryProvider = Provider<PersonRepository>((ref) {
  return PersonRepository(ref.watch(databaseHelperProvider));
});

// --- Groups ---

final groupsProvider = FutureProvider<List<Group>>((ref) async {
  final repo = ref.watch(groupRepositoryProvider);
  return repo.getAll();
});

final groupByIdProvider = FutureProvider.family<Group?, String>((ref, id) async {
  final repo = ref.watch(groupRepositoryProvider);
  return repo.getById(id);
});

// --- People ---

final peopleByGroupProvider =
    FutureProvider.family<List<Person>, String>((ref, groupId) async {
  final repo = ref.watch(personRepositoryProvider);
  return repo.getByGroup(groupId);
});

final personByIdProvider =
    FutureProvider.family<Person?, String>((ref, id) async {
  final repo = ref.watch(personRepositoryProvider);
  return repo.getById(id);
});

final allPeopleSortedProvider = FutureProvider<List<Person>>((ref) async {
  final repo = ref.watch(personRepositoryProvider);
  return repo.getAllSortedByNextBirthday();
});

final upcomingBirthdaysProvider = FutureProvider<List<Person>>((ref) async {
  final people = await ref.watch(allPeopleSortedProvider.future);
  return people.where((p) => p.daysUntilNextBirthday <= 30).toList();
});

final todayBirthdaysProvider = FutureProvider<List<Person>>((ref) async {
  final people = await ref.watch(allPeopleSortedProvider.future);
  return people.where((p) => p.isBirthdayToday).toList();
});

final alertBirthdaysProvider = FutureProvider<List<Person>>((ref) async {
  final people = await ref.watch(allPeopleSortedProvider.future);
  return people.where((p) => p.isAlertThreshold).toList();
});

final groupPersonCountProvider =
    FutureProvider.family<int, String>((ref, groupId) async {
  final people = await ref.watch(peopleByGroupProvider(groupId).future);
  return people.length;
});

