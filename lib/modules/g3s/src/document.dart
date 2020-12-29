import 'dart:async';
import '../g3s.dart';

/// A [Document] refers to a document in a [Collection] and can be used to listen,
/// read, write and remove the document.
class Document<T extends Model> with DocumentMixin<T> {

  /// Sets the [Collection] reference and the initial data.
  Document(Collection<T> collection, Map<String, dynamic> data) {
    this.setCollection(collection);
    change(data);
  }

  StreamTransformer<Map<String, dynamic>, T> get _streamModel {
    return StreamTransformer<Map<String, dynamic>, T>.fromHandlers(
      handleData: (data, sink) {
        sink.add(collection.fromMap(data));
      },
    );
  }

  /// Notifies the data of this [Document].
  Stream<T> snapshots() {
    return stream.transform<T>(_streamModel);
  }

  /// Fetch the data of this [Document].
  Future<T> get() async {
    var data = document;
    return collection.fromMap(data);
  }

  void updateRemote(String primaryKey) {
    // {
    //   'collection': collection.name,
    //   'method': 'updateOne',
    //   'document': primaryKey,
    //   'datetime': DateTime.now().millisecondsSinceEpoch,
    //   'state': 0,
    // };
  }

  /// Updates the current [Document] with specified [changes].
  Future<T> update(Map<String, dynamic> changes) async {
    final data = updateStream(changes);
    await updateLocal(collection.name, data['local'], changes);
    updateRemote(data['local']);
    return collection.fromMap(data);
  }

  void deleteRemote(String primaryKey) {
    // {
    //   'collection': collection.name,
    //   'method': 'deleteOne',
    //   'document': primaryKey,
    //   'datetime': DateTime.now().millisecondsSinceEpoch,
    //   'state': 0,
    // };
  }

  /// Deletes the current [Document].
  Future<T> delete() async {
    final data = deleteStream();
    await deleteLocal(collection.name, data['local']);
    deleteRemote(data['local']);
    return collection.fromMap(data);
  }
}
