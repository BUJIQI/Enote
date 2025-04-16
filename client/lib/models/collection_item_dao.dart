// ✅ 修改文件：collection_item_dao.dart
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'package:uuid/uuid.dart';
import 'score_item.dart';

final uuid = Uuid();

class CollectionItemDao {
  static Future<void> insertScoreToCollection({
    required String collectionId,
    required String scoreId,
    required int orderno,
  }) async {
    final db = await DatabaseHelper().db;
    await db.insert('CollectionItem', {
      'id': uuid.v4(),
      'Collectionid': collectionId,
      'Scoreid': scoreId,
      'Orderno': orderno,
    });
  }

  static Future<void> debugPrintAllCollectionItems() async {
    final db = await DatabaseHelper().db;
    final result = await db.query('CollectionItem');
    print('📦 CollectionItem 表数据：\$result');
  }

  static Future<List<ScoreItem>> fetchScoresInCollection(String collectionId) async {
    final db = await DatabaseHelper().db;
    print("🧪 开始查询 CollectionId: \$collectionId");

    final result = await db.rawQuery('''
      SELECT s.Scoreid, s.Title, s.MxlPath, s.Image
      FROM CollectionItem c
      JOIN Score s ON c.Scoreid = s.Scoreid
      WHERE c.Collectionid = ?
      ORDER BY c.Orderno ASC
    ''', [collectionId]);

    print("📤 查询结果内容: \$result");

    return result.map((row) {
      return ScoreItem(
        id: row['Scoreid'] as String,
        name: row['Title'] as String,
        image: row['Image'] as String? ?? 'assets/imgs/score_icon.jpg',
        mxlPath: row['MxlPath'] as String?,
      );
    }).toList();
  }
}

