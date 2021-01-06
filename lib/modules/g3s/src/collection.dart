import 'dart:async';
import '../g3s.dart';

/// A [Collection] object can be used for adding [Document]s, getting [Document]s,
/// and querying for [Document]s.
class Collection<T extends Model> with CollectionMixin {
  String _name;
  Function(Map<String, dynamic>) _fromMap;
  Map<String, dynamic> _filter = {};
  Map<String, dynamic> _currentFilter = {};
  bool _loading = false;
  final _docs = Map<String, Document<T>>();

  /// The [name] of the [Collection]
  String get name => _name;

  /// String helper for foreign key refernce.
  String get reference => 'REFERENCES "g3s.$name"(local)';

  /// Method from an inherited [Model] class to get an inherited [Model] object from
  /// a [Map] object.
  Future<T> fromMap(Map<String, dynamic> map) async {
    if (_fromMap is Future<T> Function(Map<String, dynamic>)) {
      return await _fromMap(map);
    } else if (_fromMap is T Function(Map<String, dynamic>)) {
      return _fromMap(map);
    } else {
      return null;
    }
  }

  /// The filter of this [Collection].
  Map<String, dynamic> get filter => _filter;

  /// The current filter of this [Collection].
  Map<String, dynamic> get currentFilter => _currentFilter;

  /// Sets the [name] of the [Collection] and the [fromMap] method of the Model.
  Collection(String name, Function(Map<String, dynamic>) fromMap) {
    this._name = name;
    this._fromMap = fromMap;
  }

  /// Makes a [filter] query into [local] database in a table specified by his [name].
  Future<List<Map<String, dynamic>>> _findLocal() async {
    final local = await G3S.instance.local;
    final where = _filter.keys.map((key) => '$key=?').join(' AND ');
    final whereArgs = _filter.values.map((value) => value).toList();
    final documentList = await local.query(
      '\"g3s.$name\"',
      where: where.isNotEmpty ? where : 'TRUE',
      whereArgs: whereArgs,
    );
    return documentList.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Updates the [Stream] of current [Collection] with a specified [documentList].
  void _updateStream(List<Map<String, dynamic>> documentList) {
    final collection = this.collection;
    collection.clear();
    documentList.forEach((document) {
      collection.putIfAbsent(document['local'], () => document);
    });
    change(collection);
  }

  void _updateDocs(List<Map<String, dynamic>> documentList) {
    documentList.forEach((value) {
      if (_docs.containsKey(value['local'])) return;
      final newDocument = Document<T>(this, value);
      _docs.putIfAbsent(value['local'], () => newDocument);
    });
  }

  _findRemote(bool forceLocal) async {
    if (forceLocal || G3S.instance.socket.disconnected) {
      _loading = false;
    } else {
      // {
      //   'collection': name,
      //   'method': 'find',
      //   'document': json.encode(filter),
      //   'datetime': DateTime.now().millisecondsSinceEpoch,
      //   'state': 0,
      // };
      // onAck: _loafing = false
      await Future.delayed(Duration(seconds: 3));
      _loading = false;
    }
  }

  StreamTransformer<Map<String, Map<String, dynamic>>, List<T>> get _streamModel {
    return StreamTransformer<Map<String, Map<String, dynamic>>, List<T>>.fromHandlers(
      handleData: (data, sink) async {
        sink.add(await Future.wait(data.values.map((e) => fromMap(e))));
      },
    );
  }

  /// Notifies of query results at this [Collection].
  Stream<List<T>> snapshots() {
    _currentFilter = _filter;
    _findLocal().then((documentList) {
      _updateStream(documentList);
      _updateDocs(documentList);
      _findRemote(false);
    });
    return stream.transform<List<T>>(_streamModel);
  }

  Future<void> _waitForIt() async {
    await Future.doWhile(() async {
      await Future.delayed(Duration(milliseconds: 33));
      return _loading;
    });
  }

  /// Fetch the documents for this [Collection].
  Future<List<T>> get([bool forceLocal = false]) async {
    _loading = true;
    final documentList = await _findLocal();
    _updateDocs(documentList);
    _findRemote(forceLocal);
    await _waitForIt();
    return await Future.wait(documentList.map((e) => fromMap(e)));
  }

  /// Returns a [Document] with the provided id.
  Document<T> doc(String localKey) {
    assert(localKey != null, "Document local key cannot be null");
    assert(_docs.containsKey(localKey), "Document does not exist for local key $localKey");
    return _docs[localKey];
  }

  Future<Map<String, dynamic>> _prepareData(Map<String, dynamic> data) async {
    assert(data != null);
    return (await fromMap(data)).toMap();
  }

  void _addDocument(Map<String, dynamic> data) {
    assert(!_docs.containsKey(data['local']), "Document already exist for key ${data['local']}");
    final newDocument = Document<T>(this, data);
    _docs.putIfAbsent(data['local'], () => newDocument);
  }

  /// Adds a document [data] to the [Stream] of current [Collection] if matches with
  /// the specified [filter].
  void _addStream(Map<String, dynamic> data) {
    final collection = this.collection;
    for (final entry in currentFilter.entries) {
      final key = entry.key;
      final value = entry.value;
      if (data.containsKey(key)) {
        if (data[key] != value) return;
      }
    }
    collection.putIfAbsent(data['local'], () => data);
    change(collection);
  }

  /// Creates new documents for nested datas
  Future<Map<String, dynamic>> _addNesteds(Map<String, dynamic> data) async {
    final entries = data.entries.toList();
    for (var entry in entries) {
      final key = entry.key;
      final value = entry.value;
      if (value is Map) {
        value[name] = data['local'];
        await G3S.instance.collection("$name.$key").add(value);
        data.remove(key);
      } else if (value is List) {
        for (var element in value) {
          if (element is Map) {
            element.putIfAbsent(name, () => data['local']);
            await G3S.instance.collection("$name.$key").add(element);
          }
        }
        data.remove(key);
      }
    }
    return data;
  }

  /// Insert the document [data] into local [Database] in a table specified by his [name]
  Future<void> _addLocal(Map<String, dynamic> data) async {
    final local = await G3S.instance.local;
    await local.insert('\"g3s.$name\"', data);
  }

  _addRemote(String primaryKey) {
    // {
    //   'collection': name,
    //   'method': 'create',
    //   'document': primaryKey,
    //   'datetime': DateTime.now().millisecondsSinceEpoch,
    //   'state': 0,
    // }
  }

  /// This [Future] creates a new document to the collection and insterts it into the
  /// stream, the local database and the remote database.
  ///
  /// This [Future] returns a [Model] object of the created data.
  Future<T> add(Map<String, dynamic> data) async {
    data = await _prepareData(data);
    _addDocument(data);
    _addStream(data);
    data = await _addNesteds(data);
    await _addLocal(data);
    _addRemote(data['local']);
    return await fromMap(data);
  }

  /// The [filter] argument describes the conditions of the query. It only supports equalities.
  ///
  /// This methods makes a filtering of date when the collection calls [get] or
  /// [snapshot] methods.
  Collection<T> where(Map<String, dynamic> filter) {
    _filter = filter;
    return this;
  }
}
