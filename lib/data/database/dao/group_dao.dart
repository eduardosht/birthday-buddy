import 'package:sqflite/sqflite.dart';
import 'package:birthday/data/models/group.dart';

class GroupDao {
  final Database db;

  GroupDao(this.db);

  static const String _table = 'groups';

  Future<void> insert(Group group) async {
    await db.insert(
      _table,
      group.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(Group group) async {
    await db.update(
      _table,
      group.toMap(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  Future<void> delete(String id) async {
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Group>> getAll() async {
    final maps = await db.query(_table, orderBy: 'createdAt ASC');
    return maps.map(Group.fromMap).toList();
  }

  Future<Group?> getById(String id) async {
    final maps = await db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Group.fromMap(maps.first);
  }
}

