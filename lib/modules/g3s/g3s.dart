import 'package:sqflite/sqflite.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:band_names/modules/g3s/src/abstracts/model.dart';
import 'package:band_names/modules/g3s/src/collection.dart';
import 'package:band_names/modules/g3s/src/abstracts/database_provider.dart';
export 'src/abstracts/database_provider.dart';
export 'src/mixins/collection_mixin.dart';
export 'src/collection.dart';
export 'src/mixins/document_mixin.dart';
export 'src/document.dart';
export 'src/abstracts/model.dart';
export 'src/object_id.dart';

/// The entry point for accessing to [G3S].
///
/// You can get an instance by calling `G3S.instance`.
class G3S {
  static G3S _g3s;
  G3S._();

  /// Returns an instance of [G3S].
  static G3S get instance {
    if (G3S._g3s == null) G3S._g3s = G3S._();
    return G3S._g3s;
  }

  factory G3S() {
    return G3S.instance;
  }

  static final _regExp = RegExp(r"^[a-z_]+$");
  static final _collections = Map<String, Collection>();
  static final _schemas = Map<String, Map<String, String>>();

  /// Gets a [Collection] for the specified collection name.
  Collection collection(String name) {
    assert(_collections.containsKey(name), "Collection does not exist for name $name");
    _collections[name].where({});
    return _collections[name];
  }

  /// Sets the model, schema and fromMap function for a new [Collection] with
  /// specified collection name.
  void setSchema<T extends Model>(
    String name,
    Map<String, String> schema,
    T Function(Map<String, dynamic>) fromMap,
  ) {
    assert(schema != null, "Collection schema cannot be null");
    assert(schema.isNotEmpty, "Collection schema must be a non-empty map");
    assert(name != null, "Collection name cannot be null");
    assert(name.isNotEmpty, "Collection name must be a non-empty string");
    assert(_regExp.hasMatch(name), "Collection name must contain only lower case letter and underscores");
    if (_collections.containsKey(name)) return;
    if (_schemas.containsKey(name)) return;
    _collections.putIfAbsent(name, () => Collection<T>(name, fromMap));
    _schemas.putIfAbsent(name, () => schema);
  }

  Database _local;
  DatabaseProvider _databaseProvider;

  /// Gets a [Future] of [Database] from a [DatabaseProvider].
  ///
  /// This getter requires the `G3S.instance.setDatabase` to be called with an
  /// instance of inherited class of [DatabaseProvider] abstract class.
  Future<Database> get local async {
    if (_local == null) {
      _local = await _databaseProvider.database;
      for (final schema in _schemas.entries) {
        final schemaString = schema.value.entries.map((e) => '${e.key} ${e.value}').join(',');
        await _local.execute("CREATE TABLE IF NOT EXISTS \"g3s.${schema.key}\" ($schemaString)");
      }
    }
    return _local;
  }

  /// Sets an instance of inherited class from [DatabaseProvider] abstract class to
  /// make use of `G3S.instance.local`.
  void setDatabaseProvider(DatabaseProvider databaseProvider) {
    assert(databaseProvider != null, "Database provider cannot be null");
    _databaseProvider = databaseProvider;
  }

  IO.Socket _socket;

  /// Gets an [IO.Socket] from a socket connection.
  ///
  /// This getter requires the `G3S.instance.setIOSocket` to be called with an
  /// instance of [IO.Socket] from a socket connection.
  IO.Socket get socket => _socket;

  /// Sets an instance of [IO.Socket] from a socket connection to make use of
  /// `G3S.instance.socket`
  void setIOSocket(IO.Socket socket) {
    assert(socket != null, "Socket cannot be null");
    _socket = socket;
  }
}
