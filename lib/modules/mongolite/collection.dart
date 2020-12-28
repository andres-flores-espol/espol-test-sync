import 'dart:async';

import 'package:band_names/modules/mongolite/document.dart';
import 'package:band_names/modules/mongolite/model.dart';

class Collection<T extends Model> {
  String _name;
  T Function(Map<String, dynamic>) _fromMap;

  String get name => _name;
  T Function(Map<String, dynamic>) get fromMap => _fromMap;

  Collection(String name, T Function(Map<String, dynamic>) fromMap) {
    this._name = name;
    this._fromMap = fromMap;
  }

  StreamTransformer<Map<String, dynamic>, T> get streamModel {
    return StreamTransformer<Map<String, dynamic>, T>.fromHandlers(
      handleData: (data, sink) {
        sink.add(this.fromMap(data));
      },
    );
  }

  final _docs = Map<String, Document<T>>();

  Document<T> doc(String id) {
    assert(_docs.containsKey(id), "Document does not exist for key $id");
    return _docs[id];
  }

  Future<Document<T>> add(Map<String, dynamic> data) async {
    assert(data != null);
    final newDocument = Document<T>(this, data);
    return newDocument;
  }

  Future<void> find({Map<String, dynamic> filter = const {}}) async {}
}
