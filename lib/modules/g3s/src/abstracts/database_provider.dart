import 'package:sqflite/sqflite.dart';

/// Abstract class definition for [DatabaseProvider].
///
/// Use [DatabaseProvider] abstract class to define inherited class for a sqflite
/// database provider.
abstract class DatabaseProvider {
  static Database _database;
  /// Returns a [Future] of [Database] from the inherited class of [DatabaseProvider]
  Future<Database> get database async {
    if (_database == null) _database = await initDB();
    return _database;
  }

  /// Returns a [Future] of [Database] from the inherited class of [DatabaseProvider] when it is initialized.
  ///
  /// implement [initDB] method as async method to initilize the database like this:
  /// ```dart
  /// Directory directory = await getApplicationDocumentsDirectory();
  /// final path = join(directory.path, 'store.db');
  /// return await openDatabase(path);
  /// ```
  Future<Database> initDB() {
    throw "initDB method is not implemented";
  }
}
