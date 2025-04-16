import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'package:uuid/uuid.dart';

final uuid = Uuid();

class CollectionInfoDao {
  static Future<void> createCollection(int? localid, String title) async {
    final db = await DatabaseHelper().db;
    await db.insert('CollectionInfo', {
      'Collectionid': uuid.v4(),
      'localid': localid,
      'Title': title,
      'Create_time': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> fetchCollections(int? localid) async {
    final db = await DatabaseHelper().db;
    return await db.query(
      'CollectionInfo',
      where: 'localid = ?',
      whereArgs: [localid],
      orderBy: 'Create_time DESC',
    );
  }

  static Future<void> deleteCollection(String collectionId) async {
    final db = await DatabaseHelper().db;
    await db.delete('CollectionInfo', where: 'Collectionid = ?', whereArgs: [collectionId]);
    await db.delete('CollectionItem', where: 'Collectionid = ?', whereArgs: [collectionId]);
  }

  static Future<void> renameCollection(String collectionId, String newTitle) async {
    final db = await DatabaseHelper().db;
    await db.update(
      'CollectionInfo',
      {'Title': newTitle},
      where: 'Collectionid = ?',
      whereArgs: [collectionId],
    );
  }
}

