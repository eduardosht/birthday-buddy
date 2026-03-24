import 'package:sqflite/sqflite.dart';
import 'package:birthday/data/models/person.dart';

class PersonDao {
  final Database db;

  PersonDao(this.db);

  static const String _table = 'people';

  Future<void> insert(Person person) async {
    await db.insert(
      _table,
      person.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(Person person) async {
    await db.update(
      _table,
      person.toMap(),
      where: 'id = ?',
      whereArgs: [person.id],
    );
  }

  Future<void> delete(String id) async {
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Person>> getAll() async {
    final maps = await db.query(_table, orderBy: 'name ASC');
    return maps.map(Person.fromMap).toList();
  }

  Future<List<Person>> getByGroup(String groupId) async {
    final maps = await db.query(
      _table,
      where: 'groupId = ?',
      whereArgs: [groupId],
      orderBy: 'name ASC',
    );
    return maps.map(Person.fromMap).toList();
  }

  Future<Person?> getById(String id) async {
    final maps = await db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Person.fromMap(maps.first);
  }

  /// Returns all people sorted by their next birthday (ascending).
  Future<List<Person>> getAllSortedByNextBirthday() async {
    final maps = await db.query(_table);
    final people = maps.map(Person.fromMap).toList();
    people.sort((a, b) =>
        a.daysUntilNextBirthday.compareTo(b.daysUntilNextBirthday));
    return people;
  }
}

