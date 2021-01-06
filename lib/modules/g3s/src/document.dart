import 'dart:async';
import '../g3s.dart';

/// A [Document] refers to a document in a [Collection] and can be used to listen,
/// read, write and remove the document.
class Document<T extends Model> with DocumentMixin<T> {
  String _localKey;

  String get localKey => _localKey;

  /// Sets the [Collection] reference and the initial data.
  Document(Collection<T> collection, Map<String, dynamic> data) {
    this.setCollection(collection);
    _localKey = data['local'];
    change(data);
  }

  StreamTransformer<Map<String, dynamic>, T> get _streamModel {
    return StreamTransformer<Map<String, dynamic>, T>.fromHandlers(
      handleData: (data, sink) async {
        sink.add(await collection.fromMap(data));
      },
    );
  }

  /// Notifies the data of this [Document].
  Stream<T> snapshots() {
    final collectionFuture = collection.where({'local': localKey}).get(false);
    collectionFuture.then((documentList) {
      change(documentList.isNotEmpty ? documentList[0]?.toMap() ?? null : null);
    });
    return stream.transform<T>(_streamModel);
  }

  /// Fetch the data of this [Document].
  Future<T> get([bool forceLocal = false]) async {
    return (await collection.where({'local': localKey}).get(forceLocal))[0];
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
    return await collection.fromMap(data);
  }

  Future<Map<String, dynamic>> _prepareData() async {
    var data = document;
    data = (await collection.fromMap(data)).toMap();
    return data;
  }

  /// Deletes the data from the [Stream] of current [Document] and deletes
  /// the [Document] from the [Stream] of his [Collection] reference.
  void _deleteStream(Map<String, dynamic> data) {
    final collection = this.collection.collection;
    collection.remove(data['local']);
    change(null);
    this.collection.change(collection);
  }

  Future<void> _deleteNested(Map<String, dynamic> data) async {
    final name = collection.name;
    final entries = data.entries.toList();
    for (var entry in entries) {
      final key = entry.key;
      final value = entry.value;
      if (value is Map) {
        await G3S.instance.collection('$name.$key').doc(value['local']).delete();
      } else if (value is List) {
        for (var element in value) {
          if (element is Map) {
            await G3S.instance.collection('$name.$key').doc(element['local']).delete();
          }
        }
      }
    }
  }

  /// Deletes the data of current [Document] from the local [Database].
  Future<void> _deleteLocal(Map<String, dynamic> data) async {
    final name = collection.name;
    final local = await G3S.instance.local;
    await local.delete('\"g3s.$name\"', where: 'local=?', whereArgs: [data['local']]);
  }

  void _deleteRemote(Map<String, dynamic> data) {
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
    var data = await _prepareData();
    _deleteStream(data);
    await _deleteNested(data);
    await _deleteLocal(data);
    _deleteRemote(data);
    return await collection.fromMap(data);
  }
}
