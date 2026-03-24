import 'package:birthday/data/database/dao/person_dao.dart';
import 'package:birthday/data/database/database_helper.dart';
import 'package:birthday/data/models/person.dart';

class PersonRepository {
  PersonRepository(this._helper);

  final DatabaseHelper _helper;

  Future<PersonDao> get _dao async {
    final db = await _helper.database;
    return PersonDao(db);
  }

  Future<List<Person>> getAll() async => (await _dao).getAll();

  Future<List<Person>> getByGroup(String groupId) async =>
      (await _dao).getByGroup(groupId);

  Future<Person?> getById(String id) async => (await _dao).getById(id);

  Future<List<Person>> getAllSortedByNextBirthday() async =>
      (await _dao).getAllSortedByNextBirthday();

  Future<void> insert(Person person) async => (await _dao).insert(person);

  Future<void> update(Person person) async => (await _dao).update(person);

  Future<void> delete(String id) async => (await _dao).delete(id);
}

