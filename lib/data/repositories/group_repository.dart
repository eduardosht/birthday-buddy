import 'package:birthday/data/database/dao/group_dao.dart';
import 'package:birthday/data/database/database_helper.dart';
import 'package:birthday/data/models/group.dart';

class GroupRepository {
  GroupRepository(this._helper);

  final DatabaseHelper _helper;

  Future<GroupDao> get _dao async {
    final db = await _helper.database;
    return GroupDao(db);
  }

  Future<List<Group>> getAll() async => (await _dao).getAll();

  Future<Group?> getById(String id) async => (await _dao).getById(id);

  Future<void> insert(Group group) async => (await _dao).insert(group);

  Future<void> update(Group group) async => (await _dao).update(group);

  Future<void> delete(String id) async => (await _dao).delete(id);
}

