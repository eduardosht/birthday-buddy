import 'package:sqflite/sqflite.dart';

class MigrationV1 {
  static Future<void> run(Database db) async {
    await db.execute('''
      CREATE TABLE groups (
        id         TEXT    PRIMARY KEY,
        name       TEXT    NOT NULL,
        colorValue INTEGER NOT NULL,
        emoji      TEXT    NOT NULL DEFAULT '🎉',
        createdAt  TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE people (
        id          TEXT    PRIMARY KEY,
        groupId     TEXT    NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
        name        TEXT    NOT NULL,
        birthday    TEXT    NOT NULL,
        photoPath   TEXT,
        contactId   TEXT,
        phoneNumber TEXT,
        notes       TEXT,
        createdAt   TEXT    NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_people_groupId ON people(groupId)',
    );

    await db.execute(
      "CREATE INDEX idx_people_birthday ON people(strftime('%m-%d', birthday))",
    );
  }
}

