import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:band_names/modules/g3s/src/abstracts/model.dart';
import 'package:band_names/modules/g3s/src/collection.dart';
import 'package:band_names/modules/g3s/src/abstracts/database_provider.dart';
import 'package:band_names/modules/g3s/src/sync.dart';
export 'src/abstracts/database_provider.dart';
export 'src/mixins/collection_mixin.dart';
export 'src/collection.dart';
export 'src/mixins/document_mixin.dart';
export 'src/document.dart';
export 'src/abstracts/model.dart';
export 'src/object_id.dart';

final encoder = JsonEncoder.withIndent('  ');
void pretty(Object object) {
  print(encoder.convert(object));
}

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

  static final _regExp = RegExp(r"^[a-z_.]+$");
  static final _collections = Map<String, Collection>();
  static final _schemas = Map<String, Map<String, String>>();

  /// Gets a [Collection] for the specified collection name.
  Collection collection(String name) {
    assert(_collections.containsKey(name), "Collection does not exist for name $name");
    return _collections[name].where({});
  }

  /// Sets the model, schema and fromMap function for a new [Collection] with
  /// specified collection name.
  void setSchema<T extends Model>(String name, Map<String, String> schema, Function(Map<String, dynamic>) fromMap) {
    assert(schema != null, "Collection schema cannot be null");
    assert(schema.isNotEmpty, "Collection schema must be a non-empty map");
    assert(name != null, "Collection name cannot be null");
    assert(name.isNotEmpty, "Collection name must be a non-empty string");
    assert(_regExp.hasMatch(name), "Collection name must contain only lower case letter and underscores");
    if (_collections.containsKey(name)) return;
    if (_schemas.containsKey(name)) return;
    _collections.putIfAbsent(name, () => Collection<T>(name, fromMap, true));
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
        final schemaString = schema.value.entries.map((e) => '\"${e.key}\" ${e.value}').join(',');
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
    socket.on('connect', (_) => emit());
  }

  Collection<Sync> _syncCollection;
  Collection<Sync> get syncCollection => _syncCollection;
  bool _emiting = false;

  void initSyncronization() {
    String name = 'sync';
    Map<String, String> schema = Sync.schema;
    Function(Map<String, dynamic>) fromMap = Sync.fromMap;
    if (_collections.containsKey(name))
      throw ("sync collection already exist, please use [initSyncronization] before any [setSchema].");
    if (_schemas.containsKey(name))
      throw ("sync schema already exist, please use [initSyncronization] before any [setSchema].");
    _collections.putIfAbsent(name, () => Collection<Sync>(name, fromMap, false));
    _schemas.putIfAbsent(name, () => schema);
    _syncCollection = _collections[name];
  }

  void emit() {
    socket.open();
    if (socket.connected && !_emiting) {
      _emiting = true;
      if (socket.sendBuffer.length == 0) {
        _emit();
      } else {
        socket.emitBuffered();
      }
    } else if (socket.disconnected) {
      _emiting = false;
    }
  }

  void cancel() {
    _emiting = false;
  }

  void _emit() async {
    if (!_emiting) return;
    var syncList = await syncCollection.where({'method': 'create'}).orderBy({'datetime': 'ASC'}).get(true);
    if (syncList.isEmpty)
      syncList = await syncCollection.where({'method': 'update'}).orderBy({'datetime': 'ASC'}).get(true);
    if (syncList.isEmpty)
      syncList = await syncCollection.where({'method': 'delete'}).orderBy({'datetime': 'ASC'}).get(true);
    if (syncList.isEmpty)
      syncList = await syncCollection.where({'method': 'select'}).orderBy({'datetime': 'ASC'}).get(true);
    if (syncList.isEmpty) {
      _emiting = false;
      return;
    }
    final sync = syncList[0];
    try {
      if (sync.method == 'create') await _syncCreate(sync);
      if (sync.method == 'update') await _syncUpdate(sync);
      if (sync.method == 'delete') await _syncDelete(sync);
      if (sync.method == 'select') await _syncSelect(sync);
    } catch (e) {
      print(e);
      await syncCollection.doc(sync.local).delete();
      _received(sync.local);
      _emit();
    }
  }

  void _received(String localKey) {
    socket.emit('sync.ready', ['ABC123', localKey]);
  }

  Future<void> _syncCreate(Sync sync) async {
    final data = sync.toMap();
    data.remove('remote');
    final doc = json.decode(sync.arg);
    final _cs = sync.collection.split('.');
    _cs.removeLast();
    _cs.asMap().keys.forEach((i) => _cs[i] = i > 0 ? '${_cs[i - 1]}.${_cs[i]}' : _cs[i]);
    final _ss = _schemas[sync.collection]
        .keys
        .where((key) => _schemas[sync.collection][key].contains('REFERENCES'))
        .where((key) => !_cs.contains(key))
        .toList();
    for (var _s in _ss) {
      doc[_s] = (await collection(_s).doc(doc[_s]).get(true)).remote;
    }
    var _d = doc;
    for (var _c in _cs.reversed) {
      _d = (await collection(_c).doc(_d[_c]).get(true)).toMap();
      doc[_c] = _d['remote'];
    }
    socket.emitWithAck(
      '${sync.collection}.create',
      [doc, data, 'ABC123'],
      ack: (Map<String, dynamic> response) async {
        try {
          if (response['hasError'] && !response['hasData']) throw response['error'];
          final remote = Map<String, dynamic>.from(response['data']);
          final syncList = await syncCollection.where({
            'collection': sync.collection,
            'document': sync.document,
            'method': 'delete',
          }).get();
          await Future.wait(syncList.map((sync) => syncCollection.doc(sync.local).update({'document': remote['_id']})));
          await collection(sync.collection).doc(sync.document).update({'remote': remote.remove('_id')}, true);
        } catch (e) {
          print(e);
        } finally {
          await syncCollection.doc(sync.local).delete();
          _received(sync.local);
          _emit();
        }
      },
    );
  }

  Future<void> _syncUpdate(Sync sync) async {
    final data = sync.toMap();
    data.remove('remote');
    final Map<String, dynamic> changes = json.decode(data.remove('arg'));
    final _cs = sync.collection.split('.');
    _cs.removeLast();
    _cs.asMap().keys.forEach((i) => _cs[i] = i > 0 ? '${_cs[i - 1]}.${_cs[i]}' : _cs[i]);
    final doc = (await collection(sync.collection).doc(sync.document).get(true)).toMap();
    doc[sync.collection] = doc['remote'];
    final _ss = _schemas[sync.collection]
        .keys
        .where((key) => _schemas[sync.collection][key].contains('REFERENCES'))
        .where((key) => !_cs.contains(key))
        .toList();
    for (var _s in _ss) {
      changes[_s] = (await collection(_s).doc(doc[_s]).get(true)).remote;
    }
    var _d = doc;
    for (var _c in _cs.reversed) {
      _d = (await collection(_c).doc(_d[_c]).get(true)).toMap();
      doc[_c] = _d['remote'];
    }
    doc.removeWhere((key, value) => ![sync.collection, ..._cs].contains(key));
    socket.emitWithAck(
      '${sync.collection}.update',
      [doc, changes, data, 'ABC123'],
      ack: (Map<String, dynamic> response) async {
        await syncCollection.doc(sync.local).delete();
        _received(sync.local);
        _emit();
      },
    );
  }

  Future<void> _syncDelete(Sync sync) async {
    final data = sync.toMap();
    data.remove('remote');
    final doc = json.decode(data.remove('arg'));
    final filter = {sync.collection: sync.document, ...doc};
    final _cs = sync.collection.split('.');
    _cs.removeLast();
    _cs.asMap().keys.forEach((i) => _cs[i] = i > 0 ? '${_cs[i - 1]}.${_cs[i]}' : _cs[i]);
    var _d = filter;
    for (var _c in _cs.reversed) {
      _d = (await collection(_c).doc(_d[_c]).get(true)).toMap();
      filter[_c] = _d['remote'];
    }
    filter.removeWhere((key, value) => ![sync.collection, ..._cs].contains(key));
    socket.emitWithAck(
      '${sync.collection}.delete',
      [filter, data, 'ABC123'],
      ack: (Map<String, dynamic> response) async {
        await syncCollection.doc(sync.local).delete();
        _received(sync.local);
        _emit();
      },
    );
  }

  MapEntry<String, dynamic> _mapper(int key, Map<String, dynamic> value1) {
    final remote = value1['remote'];
    value1.removeWhere((key, value) => key != 'local' && !(value is List));
    final _value1 = Map<String, dynamic>.from(value1);
    _value1.forEach((key, value2) {
      if (value2 is List) {
        final _value2 = value2.map((e) => Map<String, dynamic>.from(e)).toList();
        value1.remove(key);
        value1.putIfAbsent(key, () => _value2.asMap().map(_mapper));
      }
    });
    return MapEntry(remote, value1);
  }

  Map<String, dynamic> _remoteFill(Map<String, dynamic> doc, Map<String, dynamic> dk) {
    Map<String, dynamic> _doc = Map<String, dynamic>.from(doc);
    _doc.putIfAbsent('remote', () => _doc.remove('_id'));
    if (dk != null && dk[_doc['remote']] != null) {
      _doc.putIfAbsent('local', () => dk[_doc['remote']]['local'] ?? _doc['remote']);
    }
    _doc.forEach((key, value) {
      if (value is List) {
        _doc[key] = value.map((e) => _remoteFill(e, (dk[_doc['remote']] ?? {})[key])).toList();
      }
    });
    return _doc;
  }

  Future<void> _syncSelect(Sync sync) async {
    final data = sync.toMap();
    final currentCollection = collection(sync.collection);
    final filter = json.decode(data.remove('arg'));
    final remote = Map<String, dynamic>.from(filter);
    data.remove('remote');
    if (remote.containsKey('local')) {
      final currentDocument = (await currentCollection.where(filter).get(true))[0];
      remote.update('local', (_) => currentDocument.remote);
      remote.putIfAbsent('_id', () => remote.remove('local'));
    }
    if (remote.containsKey('remote')) {
      remote.putIfAbsent('_id', () => remote.remove('remote'));
    }
    socket.emitWithAck(
      '${sync.collection}.select',
      [remote, data, 'ABC123'],
      ack: (Map<String, dynamic> response) async {
        try {
          if (response['hasError'] && !response['hasData']) throw response['error'];
          final List<dynamic> documentList = response['data'];
          final l = await currentCollection.where(filter).get(true);
          final d = await Future.wait(l.map((e) => currentCollection.doc(e.local).delete(true)));
          // final dk = d.asMap().map((key, value) => MapEntry(value.remote, value.local));
          final dk = d.map((e) => e.toMap()).toList().asMap().map(_mapper);
          await Future.wait(documentList.map((document) async {
            Map<String, dynamic> newDocument = _remoteFill(document, dk);
            final _ss = _schemas[sync.collection]
                .keys
                .where((key) => _schemas[sync.collection][key].contains('REFERENCES'))
                .toList();
            for (var _s in _ss) {
              final refParentList = await collection(_s).where({'remote': newDocument[_s]}).get(true);
              newDocument[_s] = refParentList.length != 0 ? refParentList[0].local : null;
            }
            await currentCollection.add(newDocument, true);
          }));
        } catch (e) {
          print(e);
        } finally {
          currentCollection.loading = false;
          await syncCollection.doc(sync.local).delete();
          _received(sync.local);
          _emit();
        }
      },
    );
  }
}
