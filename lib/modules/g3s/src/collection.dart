import 'dart:async';
import 'dart:convert';
import '../g3s.dart';

/// A [Collection] object can be used for adding [Document]s, getting [Document]s,
/// and querying for [Document]s.
class Collection<T extends Model> with CollectionMixin {
  String _name;
  Function(Map<String, dynamic>) _fromMap;
  Map<String, dynamic> _filter = {};
  Map<String, dynamic> _currentFilter = {};
  bool loading = false;
  bool _remote;
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
  Collection(String name, Function(Map<String, dynamic>) fromMap, bool remote) {
    this._name = name;
    this._fromMap = fromMap;
    this._remote = remote;
  }

  /// Makes a [filter] query into [local] database in a table specified by his [name].
  Future<List<Map<String, dynamic>>> _selectLocal(Map<String, dynamic> filter, Map<String, String> orderBy) async {
    final local = await G3S.instance.local;
    final where = filter.keys.map((key) => '$key=?').join(' AND ');
    final whereArgs = filter.values.map((value) => value).toList();
    final order = orderBy.entries.map((e) => '${e.key} ${e.value}').join(', ');
    final documentList = await local.query(
      '\"g3s.$name\"',
      where: where.isNotEmpty ? where : null,
      whereArgs: whereArgs,
      orderBy: _order.isNotEmpty ? order : null,
    );
    return documentList.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Updates the [Stream] of current [Collection] with a specified [documentList].
  void _updateStream(List<Map<String, dynamic>> documentList) {
    final collection = Map<String, Map<String, dynamic>>();
    documentList.forEach((document) {
      collection.putIfAbsent(document['local'], () => document);
    });
    change(collection);
  }

  void _updateDocs(List<Map<String, dynamic>> documentList) {
    documentList.forEach((value) {
      if (_docs.containsKey(value['local'])) return;
      final newDocument = Document<T>(this, value, _remote);
      _docs.putIfAbsent(value['local'], () => newDocument);
    });
  }

  void _selectRemote(Map<String, dynamic> filter) async {
    if (G3S.instance.socket.disconnected || !_remote) {
      loading = false;
    } else {
      final g3s = G3S.instance;
      await g3s.syncCollection.add({
        'collection': name,
        'document': null,
        'method': 'select',
        'arg': json.encode(filter),
        'datetime': (DateTime.now().millisecondsSinceEpoch / 1000).floor(),
      });
      g3s.emit();
      // await Future.delayed(Duration(seconds: 3));
      // loading = false;
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
    final currentFilter = _currentFilter;
    final orderBy = Map<String, String>.from(_order);
    _selectLocal(currentFilter, orderBy).then((documentList) {
      _updateStream(documentList);
      _updateDocs(documentList);
      _selectRemote(currentFilter);
    });
    return stream.transform<List<T>>(_streamModel);
  }

  Future<void> _waitForIt() async {
    await Future.doWhile(() async {
      await Future.delayed(Duration(milliseconds: 33));
      return loading;
    });
  }

  /// Fetch the documents for this [Collection].
  Future<List<T>> get([bool forceLocal = false]) async {
    final filter = Map<String, dynamic>.from(_filter);
    final orderBy = Map<String, String>.from(_order);
    var documentList = await _selectLocal(filter, orderBy);
    _updateDocs(documentList);
    if (!forceLocal) {
      loading = true;
      _selectRemote(filter);
      await _waitForIt();
      documentList = await _selectLocal(filter, orderBy);
      _updateDocs(documentList);
    }
    where({});
    return await Future.wait(documentList.map((e) => fromMap(e)));
  }

  /// Returns a [Document] with the provided id.
  Document<T> doc(String localKey) {
    assert(localKey != null, "Document local key cannot be null");
    assert(_docs.containsKey(localKey), "Document does not exist for local key $localKey at $name Collection");
    return _docs[localKey];
  }

  Future<Map<String, dynamic>> _prepareData(Map<String, dynamic> data) async {
    assert(data != null);
    final _data = Map<String, dynamic>.from(data);
    return (await fromMap(_data)).toMap();
  }

  void _addDocument(Map<String, dynamic> data) {
    final _data = Map<String, dynamic>.from(data);
    assert(!_docs.containsKey(_data['local']), "Document already exist for key ${_data['local']} at $name Collection");
    final newDocument = Document<T>(this, _data, _remote);
    _docs.putIfAbsent(_data['local'], () => newDocument);
  }

  /// Adds a document [data] to the [Stream] of current [Collection] if matches with
  /// the specified [filter].
  void _addStream(Map<String, dynamic> data) {
    final _data = Map<String, dynamic>.from(data);
    final collection = this.collection;
    for (final entry in currentFilter.entries) {
      final key = entry.key;
      final value = entry.value;
      if (_data.containsKey(key)) {
        if (_data[key] != value) return;
      }
    }
    collection.putIfAbsent(_data['local'], () => _data);
    change(collection);
  }

  /// Creates new documents for nested datas
  Future<Map<String, dynamic>> _addNesteds(Map<String, dynamic> data) async {
    final _data = Map<String, dynamic>.from(data);
    final entries = _data.entries.toList();
    for (var entry in entries) {
      final key = entry.key;
      final value = entry.value;
      if (value is Map) {
        value[name] = _data['local'];
        await G3S.instance.collection("$name.$key").add(value, true);
        _data.remove(key);
      } else if (value is List) {
        for (var index in value.asMap().keys) {
          if (value[index] is Map) {
            value[index][name] = _data['local'];
            await G3S.instance.collection("$name.$key").add(value[index], true);
          }
        }
        _data.remove(key);
      }
    }
    return _data;
  }

  /// Insert the document [data] into local [Database] in a table specified by his [name]
  Future<void> _addLocal(Map<String, dynamic> data) async {
    final _data = Map<String, dynamic>.from(data);
    final local = await G3S.instance.local;
    await local.insert('\"g3s.$name\"', _data);
  }

  Map<String, dynamic> _clean(Map<String, dynamic> data, String parent) {
    final _data = Map<String, dynamic>.from(data);
    _data.remove('local');
    _data.remove('remote');
    _data.forEach((key, value) {
      if (value is Map) {
        value.remove(parent);
        _data.update(key, (value) => _clean(value, '$parent.$key'));
      }
      if (value is List) {
        _data.update(
          key,
          (value) => value.map(
            (element) {
              if (element is Map) {
                element.remove(parent);
                element = _clean(element, '$parent.$key');
              }
              return element;
            },
          ).toList(),
        );
      }
    });
    return _data;
  }

  _addRemote(Map<String, dynamic> data) async {
    if (G3S.instance.socket.disconnected || !_remote) return;
    final g3s = G3S.instance;
    final _data = _clean(data, name);
    await g3s.syncCollection.add({
      'collection': name,
      'document': data['local'],
      'method': 'create',
      'arg': json.encode(_data),
      'datetime': (DateTime.now().millisecondsSinceEpoch / 1000).floor(),
    });
    g3s.emit();
  }

  /// This [Future] creates a new document to the collection and insterts it into the
  /// stream, the local database and the remote database.
  ///
  /// This [Future] returns a [Model] object of the created data.
  Future<T> add(Map<String, dynamic> data, [bool forceLocal = false]) async {
    var _data = Map<String, dynamic>.from(data);
    _data = await _prepareData(_data);
    _addDocument(_data);
    _addStream(_data);
    if (!forceLocal) _addRemote(_data);
    _data = await _addNesteds(_data);
    await _addLocal(_data);
    return await fromMap(_data);
  }

  /// The [filter] argument describes the conditions of the query. It only supports equalities.
  ///
  /// This methods makes a filtering of date when the collection calls [get] or
  /// [snapshot] methods.
  Collection<T> where(Map<String, dynamic> filter) {
    _filter = filter;
    return this;
  }

  Map<String, String> _order = Map<String, String>();
  Map<String, String> get order => _order;

  Collection<T> orderBy(Map<String, String> order) {
    _order = order;
    return this;
  }

  /// DONT USE OUT OF DOCUMENT CLASS DEFINITION IN THE MODULE
  deleteDoc(String localKey) {
    final collection = this.collection;
    _docs.remove(localKey);
    collection.remove(localKey);
    change(collection);
  }
}
