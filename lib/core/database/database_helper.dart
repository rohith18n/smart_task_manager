import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tasksTableName} (
        id INTEGER PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        priority TEXT NOT NULL,
        category TEXT NOT NULL,
        due_date TEXT,
        is_completed INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 1,
        sync_action TEXT NOT NULL DEFAULT 'NONE'
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_tasks_user_id ON ${AppConstants.tasksTableName} (user_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_tasks_is_synced ON ${AppConstants.tasksTableName} (is_synced)
    ''');
    await db.execute('''
      CREATE INDEX idx_tasks_due_date ON ${AppConstants.tasksTableName} (due_date)
    ''');
    await db.execute('''
      CREATE INDEX idx_tasks_created_at ON ${AppConstants.tasksTableName} (created_at)
    ''');
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.execute('DROP TABLE IF EXISTS ${AppConstants.tasksTableName}');
    await _onCreate(db, newVersion);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
