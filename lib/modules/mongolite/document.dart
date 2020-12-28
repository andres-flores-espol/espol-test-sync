import 'dart:async';
import 'package:band_names/modules/mongolite/document_mixin.dart';
import 'package:band_names/modules/mongolite/collection.dart';
import 'package:band_names/modules/mongolite/model.dart';

class Document<T extends Model> with DocumentMixin {
  Collection<T> _collection;

  Document(Collection<T> collection, Map<String, dynamic> data) {
    this._collection = collection;
    change(data);
  }

  Future<T> get() async {
    var data = document;
    final doc = _collection.fromMap(data);
    return doc;
  }

  Stream<T> snapshots() {
    return stream.transform<T>(_collection.streamModel);
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

  Future<void> update(Map<String, dynamic> changes) async {
    final data = updateStream(changes);
    await updateLocal(_collection.name, data['local'], changes);
    updateRemote(data['local']);
  }
}
