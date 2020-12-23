import 'package:band_names/modules/fire_mongo/fire_mongo.dart';

abstract class Model {
  static final schema = Map<String, String>();
  static final _regExp = RegExp(r"^[a-z]+$");
  static Future<void> builder(String name) async {
    assert(schema != null, "Collection schema cannot be null");
    assert(schema.isNotEmpty, "Collection schema must be a non-empty map");
    assert(name != null, "Collection name cannot be null");
    assert(name.isNotEmpty, "Collection name must be a non-empty string");
    assert(_regExp.hasMatch(name), "Collection name must contain only lower case letter");
    final local = await FireMongo.instance.local;
    final schemaString = schema.entries.map((e) => '${e.key} ${e.value}').join(',');
    local.execute(
      "CREATE TABLE IF NOT EXIST $name ("
      "id TEXT PRIMARY KEY," // REQUIRED
      "_id TEXT UNIQUE," // REQUIRED
      "$schemaString"
      ")",
    );
  }
}
