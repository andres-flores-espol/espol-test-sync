import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:band_names/modules/fire_mongo/collection.dart';

class FireMongo {
  static FireMongo _fireMongo;
  FireMongo._();

  static FireMongo get instance {
    if (FireMongo._fireMongo == null) FireMongo._fireMongo = FireMongo._();
    return FireMongo._fireMongo;
  }

  factory FireMongo() {
    return FireMongo.instance;
  }

  static final _regExp = RegExp(r"^[a-z_]+$");
  static final _collections = Map<String, Collection>();
  static final _schemas = Map<String, Map<String, String>>();

  Collection collection(String name) {
    assert(_collections.containsKey(name), "Collection does not exist for name $name");
    _collections[name].find();
    return _collections[name];
  }

  void setSchema(String name, Map<String, String> schema) {
    assert(schema != null, "Collection schema cannot be null");
    assert(schema.isNotEmpty, "Collection schema must be a non-empty map");
    assert(name != null, "Collection name cannot be null");
    assert(name.isNotEmpty, "Collection name must be a non-empty string");
    assert(_regExp.hasMatch(name), "Collection name must contain only lower case letter and underscores");
    _collections.putIfAbsent(name, () => Collection(name));
    _schemas.putIfAbsent(name, () => schema);
  }

  Database _local;
  Future<Database> get local async {
    if (_local == null) _local = await _initDB();
    return _local;
  }

  static Future<Database> _initDB() async {
    Directory directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, '_fire_mongo.db');
    return await openDatabase(path, version: 1, onCreate: (db, version) async {
      for (final schema in _schemas.entries) {
        final schemaString = schema.value.entries.map((e) => '${e.key} ${e.value}').join(',');
        await db.execute(
          "CREATE TABLE IF NOT EXIST ${schema.key} ("
          "id TEXT PRIMARY KEY," // REQUIRED
          "_id TEXT UNIQUE," // REQUIRED
          "$schemaString"
          ")",
        );
      }
    });
  }
}
