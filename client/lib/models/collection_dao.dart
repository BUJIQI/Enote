// ✅ 修改文件：collection_dao.dart
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'score_item.dart';  // 导入 ScoreItem 模型
import 'package:uuid/uuid.dart';

final uuid = Uuid();

class CollectionDao {
  /// 插入一个谱集记录（添加曲谱到某个谱集）
  static Future<void> insertCollection({
    required String localid,
    required String scoreid,
    required int orderno,
  }) async {
    final dbClient = await DatabaseHelper().db;
    await dbClient.insert('Collection', {
      'Collectionid': uuid.v4(),
      'localid': localid,
      'Scoreid': scoreid,
      'Orderno': orderno,
    });
  }

  /// 查询某用户创建的所有谱集（不去重）
  static Future<List<Map<String, dynamic>>> fetchCollectionsByUserId({
    required String localid,
  }) async {
    final dbClient = await DatabaseHelper().db;
    return await dbClient.query(
      'Collection',
      where: 'localid = ?',
      whereArgs: [localid],
      orderBy: 'Orderno ASC',
    );
  }

  /// 查询某个谱集中的所有曲谱（JOIN Score 表）
  static Future<List<ScoreItem>> fetchScoresByCollectionId(String collectionId) async {
    final db = await DatabaseHelper().db;

    final result = await db.rawQuery('''
      SELECT s.Scoreid, s.Title, s.MxlPath, s.Image
      FROM Collection c
      JOIN Score s ON c.Scoreid = s.Scoreid
      WHERE c.Collectionid = ?
      ORDER BY c.Orderno ASC
    ''', [collectionId]);

    return result.map((row) {
      return ScoreItem(
        id: row['Scoreid'] as String,
        name: row['Title'] as String,
        image: row['Image'] as String? ?? 'assets/imgs/score_icon.jpg',
        mxlPath: row['MxlPath'] as String?,
      );
    }).toList();
  }

  /// 删除某个谱集记录（将曲谱从某个谱集中移除）
  static Future<void> deleteCollection(String collectionid) async {
    final dbClient = await DatabaseHelper().db;
    await dbClient.delete(
      'Collection',
      where: 'Collectionid = ?',
      whereArgs: [collectionid],
    );
  }

  /// 更新谱集排序（可选）
  static Future<void> updateCollectionOrder(
      String collectionid, int newOrderno) async {
    final dbClient = await DatabaseHelper().db;
    await dbClient.update(
      'Collection',
      {'Orderno': newOrderno},
      where: 'Collectionid = ?',
      whereArgs: [collectionid],
    );
  }
}
