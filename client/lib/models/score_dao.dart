// ✅ 修改文件：score_dao.dart
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'package:uuid/uuid.dart';

final uuid = Uuid();

class ScoreDao {
  // 插入一条 Score
  static Future<String> insertScore({
    required int? localid,
    required String title,
    String? mxlPath,
    String? image,
  }) async {
    final db = await DatabaseHelper().db;
    final scoreId = Uuid().v4();
    final now = DateTime.now().toIso8601String();

    await db.insert('Score', {
      'Scoreid': scoreId,
      'localid': localid,
      'Title': title,
      'Create_time': now,
      'Access_time': now,
      'MxlPath': mxlPath,  // ✅ 更新字段
      'Image': image,
    });
    print('✅ 曲谱插入 Score 表：\$scoreId');
    return scoreId;
  }

  // 查询所有曲谱
  static Future<List<Map<String, dynamic>>> fetchAllScores({
    required int? localid,
  }) async {
    final dbClient = await DatabaseHelper().db;
    return await dbClient.query(
      'Score',
      where: 'localid = ?',
      whereArgs: [localid],
      orderBy: 'Access_time DESC',
    );
  }

  // 修改标题
  static Future<void> updateScoreTitle(String scoreid, String newTitle) async {
    final dbClient = await DatabaseHelper().db;
    await dbClient.update(
      'Score',
      {'Title': newTitle},
      where: 'Scoreid = ?',
      whereArgs: [scoreid],
    );
  }

  // 删除曲谱
  static Future<void> deleteScore(String scoreid) async {
    final dbClient = await DatabaseHelper().db;
    await dbClient.delete(
      'Score',
      where: 'Scoreid = ?',
      whereArgs: [scoreid],
    );
  }

  // 更新访问时间
  static Future<void> updateAccessTime(String scoreid) async {
    final dbClient = await DatabaseHelper().db;
    await dbClient.update(
      'Score',
      {'Access_time': DateTime.now().toIso8601String()},
      where: 'Scoreid = ?',
      whereArgs: [scoreid],
    );
  }

  static Future<void> debugPrintAllScores() async {
    final db = await DatabaseHelper().db;
    final result = await db.query('Score');
    print('🧾 当前 Score 表数据：\$result');
  }
}

