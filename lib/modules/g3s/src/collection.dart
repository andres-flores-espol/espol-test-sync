import 'dart:async';
// import 'dart:convert';
import '../g3s.dart';

/// A [Collection] object can be used for adding [Document]s, getting [Document]s,
/// and querying for [Document]s.
class Collection<T extends Model> with CollectionMixin {
  String _name;
  T Function(Map<String, dynamic>) _fromMap;

  /// The [name] of the [Collection]
  String get name => _name;

  /// Method from an inherited [Model] class to get an inherited [Model] object from
  /// a [Map] object.
  T Function(Map<String, dynamic>) get fromMap => _fromMap;

  /// Sets the [name] of the [Collection] and the [fromMap] method of the Model.
  Collection(String name, T Function(Map<String, dynamic>) fromMap) {
    this._name = '"g3s.$name"';
    this._fromMap = fromMap;
  }

  StreamTransformer<Map<String, Map<String, dynamic>>, List<T>> get _streamModel {
    return StreamTransformer<Map<String, Map<String, dynamic>>, List<T>>.fromHandlers(
      handleData: (data, sink) {
        sink.add(data.values.map((e) => fromMap(e)).toList());
      },
    );
  }

  /// Notifies of query results at this [Collection].
  Stream<List<T>> snapshots() {
    return stream.transform<List<T>>(_streamModel);
  }

  bool _loading = false;

  /// Fetch the documents for this [Collection].
  Future<List<T>> get() async {
    await Future.doWhile(() async {
      await Future.delayed(Duration(milliseconds: 33));
      return _loading;
    });
    final collection = this.collection;
    return collection.values.map((e) => fromMap(e)).toList();
  }

  final _docs = Map<String, Document<T>>();

  /// Returns a [Document] with the provided id.
  Document<T> doc(String id) {
    assert(id != null, "Document id cannot be null");
    assert(_docs.containsKey(id), "Document does not exist for key $id");
    return _docs[id];
  }

  /// Calls the synchronization system of collections to create a document into the
  /// remote database.
  addRemote(String primaryKey) {
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
    assert(data != null);
    data = fromMap(data).toMap();
    assert(!_docs.containsKey(data['local']), "Document already exist for key ${data['local']}");
    final newDocument = Document<T>(this, data);
    _docs.putIfAbsent(data['local'], () => newDocument);
    addStream(data, filter);
    await addLocal(name, data);
    addRemote(data['local']);
    return fromMap(data);
  }

  Map<String, dynamic> _filter = {};

  /// The current filter of this [Collection].
  Map<String, dynamic> get filter => _filter;

  findRemote() {
    // {
    //   'collection': name,
    //   'method': 'find',
    //   'document': json.encode(filter),
    //   'datetime': DateTime.now().millisecondsSinceEpoch,
    //   'state': 0,
    // };
    _loading = false;
  }

  /// Makes a query to the local database and updates the stream.
  ///
  /// If there is a connection to the sync server, it queries the remote database and updates the stream.
  ///
  /// The [filter] argument describes the conditions of the query. It only supports equalities.
  ///
  /// The [forceLocal] argument forces the function to only get the data from the local database.
  Collection<T> where(Map<String, dynamic> filter, {bool forceLocal = false}) {
    _filter = filter;
    _loading = true;
    G3S.instance.local.then((local) async {
      final documentList = await findLocal(local, name, filter);
      final collection = updateStream(documentList);
      collection.forEach((key, value) {
        if (_docs.containsKey(key)) return;
        final newDocument = Document<T>(this, value);
        _docs.putIfAbsent(value['local'], () => newDocument);
      });
      if (forceLocal || G3S.instance.socket.disconnected) {
        _loading = false;
        return;
      }
      findRemote();
    });
    return this;
  }
}
