import 'dart:async';
import '../g3s.dart';

class Collection<T extends Model> with CollectionMixin {
  String _name;
  T Function(Map<String, dynamic>) _fromMap;

  String get name => _name;
  T Function(Map<String, dynamic>) get fromMap => _fromMap;

  Collection(String name, T Function(Map<String, dynamic>) fromMap) {
    this._name = name;
    this._fromMap = fromMap;
  }

  StreamTransformer<Map<String, dynamic>, List<T>> get _streamModel {
    return StreamTransformer<Map<String, dynamic>, List<T>>.fromHandlers(
      handleData: (data, sink) {
        sink.add(data.values.map((e) => fromMap(e)));
      },
    );
  }

  Stream<List<T>> snapshots() {
    return stream.transform<List<T>>(_streamModel);
  }

  Future<List<T>> get() async {
    var data = collection;
    return data.values.map((e) => fromMap(e));
  }

  final _docs = Map<String, Document<T>>();

  Document<T> doc(String id) {
    assert(_docs.containsKey(id), "Document does not exist for key $id");
    return _docs[id];
  }

  addRemote(String primaryKey) {
    // {
    //   'collection': name,
    //   'method': 'create',
    //   'document': primaryKey,
    //   'datetime': DateTime.now().millisecondsSinceEpoch,
    //   'state': 0,
    // }
  }

  Future<T> add(Map<String, dynamic> data) async {
    assert(data != null);
    data = fromMap(data).toMap();
    assert(_docs.containsKey(data['local']), "Document already exist for key ${data['local']}");
    final newDocument = Document<T>(this, data);
    _docs.putIfAbsent(data['local'], () => newDocument);
    addStream(data);
    await addLocal(name, data);
    addRemote(data['local']);
    return fromMap(data);
  }

  Map<String, dynamic> _filter = {};
  Map<String, dynamic> get filter => _filter;
  Collection<T> find([Map<String, dynamic> filter]) {
    _filter = filter;
    return this;
  }
}
