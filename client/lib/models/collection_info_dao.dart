import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'package:uuid/uuid.dart';

final uuid = Uuid();

class CollectionInfoDao {
  static Future<void> createCollection(String userid, String title) async {
    final db = await DatabaseHelper().db;
    await db.insert('CollectionInfo', {
      'Collectionid': uuid.v4(),
      'Userid': userid,
      'Title': title,
      'Create_time': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> fetchCollections(String userid) async {
    final db = await DatabaseHelper().db;
    return await db.query(
      'CollectionInfo',
      where: 'Userid = ?',
      whereArgs: [userid],
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
