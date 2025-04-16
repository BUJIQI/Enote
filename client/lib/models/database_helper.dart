import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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

  Future<Database> _initDb() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "score_app.db");

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onOpen: (db) async {
        print("📂 数据库已打开: \$path");
        final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
        print("📋 当前所有表: \$tables");
      },
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE Score (
      Scoreid TEXT PRIMARY KEY,
      Userid TEXT NOT NULL,
      Title TEXT NOT NULL,
      Create_time TEXT NOT NULL,
      Access_time TEXT NOT NULL,
      MxlPath TEXT,         -- ✅ 改为保存本地 MXL 路径
      Image TEXT
    )
  ''');

    // ✅ 新增谱集信息表
    await db.execute('''
    CREATE TABLE CollectionInfo (
      Collectionid TEXT PRIMARY KEY,
      Userid TEXT NOT NULL,
      Title TEXT NOT NULL,
      Create_time TEXT NOT NULL
    )
  ''');

    // ✅ 新增谱集曲谱关联表
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
