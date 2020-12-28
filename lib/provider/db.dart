import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:band_names/modules/g3s/src/abstracts/database_provider.dart';

class DBProvider extends DatabaseProvider {
  static final DBProvider _instance = DBProvider._internal();
  factory DBProvider() => _instance;
  DBProvider._internal();

  static Database _database;

  @override
  Future<Database> get database async {
    if (_database == null) _database = await initDB();
    return _database;
  }

  @override
  Future<Database> initDB() async {
    Directory directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'store.db');
    print(path);
    return await openDatabase(path, version: 1, onCreate: (Database db, int version) async {
      for (String createTable in createTables) {
        print(createTable);
        await db.execute(createTable);
      }
    });
  }

  List<String> createTables = [
    "CREATE TABLE syncs ("
        "  id TEXT PRIMARY KEY," // REQUIRED
        "  _id TEXT UNIQUE," // REQUIRED
        "  collection TEXT,"
        "  method TEXT,"
        "  document TEXT,"
        "  datetime INTEGER,"
        "  state INTEGER"
        ")",
    "CREATE TABLE bands ("
        "  id TEXT PRIMARY KEY," // REQUIRED
        "  _id TEXT UNIQUE," // REQUIRED
        "  name TEXT,"
        "  votes INTEGER"
        ")",
  ];
}
