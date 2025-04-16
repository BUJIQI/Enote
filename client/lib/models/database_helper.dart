import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'user.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<void> insertUser(User user) async {
    final dbClient = await db;
    await dbClient.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> resetLocalPassword(String username, String newPassword) async {
    final dbClient = await db;

    // 检查用户是否存在
    final result = await dbClient.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (result.isEmpty) {
      return false; // 用户不存在
    }

    // 更新密码
    await dbClient.update(
      'users',
      {'password': newPassword},
      where: 'username = ?',
      whereArgs: [username],
    );

    return true; // 修改成功
  }

  Future<void> updateSyncEnabled(String username, bool enabled) async {
    final dbClient = await db;
    await dbClient.update(
      'users',
      {
        'SyncEnabled': enabled ? 1 : 0,
      },
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  // 修改当前用户的昵称和密码
  Future<void> updateUsernameAndPassword({
    required String currentUsername,
    required String newUsername,
    required String newPassword,
  }) async {
    final dbClient = await db;

    await dbClient.update(
      'users',
      {
        'username': newUsername,
        'password': newPassword,
      },
      where: 'username = ?',
      whereArgs: [currentUsername],
    );
  }


  Future<Database> _initDb() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "score_app.db");
    await deleteDatabase(path);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onOpen: (db) async {
        await db.execute("PRAGMA foreign_keys = ON");
        final result = await db.rawQuery("PRAGMA foreign_keys");
        print("🔍 外键支持状态: ${result.first}"); // 应该输出 {foreign_keys: 1}
        print("📂 数据库已打开: \$path");
        final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
        print("📋 当前所有表: \$tables");
      },
    );
  }

  Future _onCreate(Database db, int version) async {
    // ✅ 启用外键支持
    await db.execute("PRAGMA foreign_keys = ON");

    // ✅ 用户信息表
    await db.execute('''
    CREATE TABLE users (
      localid INTEGER PRIMARY KEY AUTOINCREMENT,
      userId TEXT,
      username TEXT,
      password TEXT,
      SyncEnabled INTEGER
    )
  ''');

    // ✅ 曲谱表，关联用户
    await db.execute('''
    CREATE TABLE Score (
      Scoreid TEXT PRIMARY KEY,
      localid INTEGER NOT NULL,
      Title TEXT NOT NULL,
      Create_time TEXT NOT NULL,
      Access_time TEXT NOT NULL,
      MxlPath TEXT,
      Image TEXT,
      FOREIGN KEY (localid) REFERENCES users(localid) ON DELETE CASCADE
    )
  ''');

    // ✅ 谱集信息表，关联用户
    await db.execute('''
    CREATE TABLE CollectionInfo (
      Collectionid TEXT PRIMARY KEY,
      localid INTEGER NOT NULL,
      Title TEXT NOT NULL,
      Create_time TEXT NOT NULL,
      FOREIGN KEY (localid) REFERENCES users(localid) ON DELETE CASCADE
    )
  ''');

    // ✅ 谱集与曲谱的关联表，关联谱集和曲谱
    await db.execute('''
    CREATE TABLE CollectionItem (
      id TEXT PRIMARY KEY,
      Collectionid TEXT NOT NULL,
      Scoreid TEXT NOT NULL,
      Orderno INTEGER NOT NULL
    )
  ''');
  }
}

