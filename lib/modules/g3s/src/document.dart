import 'dart:async';
import '../g3s.dart';

class Document<T extends Model> with DocumentMixin {
  Collection<T> _collection;

  Document(Collection<T> collection, Map<String, dynamic> data) {
    this._collection = collection;
    change(data);
  }

  StreamTransformer<Map<String, dynamic>, T> get _streamModel {
    return StreamTransformer<Map<String, dynamic>, T>.fromHandlers(
      handleData: (data, sink) {
        sink.add(_collection.fromMap(data));
      },
    );
  }

  Stream<T> snapshots() {
    return stream.transform<T>(_streamModel);
  }

  Future<T> get() async {
    var data = document;
    return _collection.fromMap(data);
  }

  void updateRemote(String primaryKey) {
    // {
    //   'collection': _collection.name,
    //   'method': 'updateOne',
    //   'document': primaryKey,
    //   'datetime': DateTime.now().millisecondsSinceEpoch,
    //   'state': 0,
    // };
  }

  Future<T> update(Map<String, dynamic> changes) async {
    final data = updateStream(changes);
    await updateLocal(_collection.name, data['local'], changes);
    updateRemote(data['local']);
    return _collection.fromMap(data);
  }

  void deleteRemote(String primaryKey) {
    // {
    //   'collection': _collection.name,
    //   'method': 'deleteOne',
    //   'document': primaryKey,
    //   'datetime': DateTime.now().millisecondsSinceEpoch,
    //   'state': 0,
    // };
  }

  Future<T> delete() async {
    final data = deleteStream();
    await deleteLocal(_collection.name, data['local']);
    deleteRemote(data['local']);
    return _collection.fromMap(data);
  }
}
