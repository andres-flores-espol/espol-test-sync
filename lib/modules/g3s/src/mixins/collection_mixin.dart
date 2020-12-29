import 'package:rxdart/rxdart.dart';
import 'package:sqflite/sqflite.dart';

import '../../g3s.dart';

/// This class is intended to be used as a mixin, and should not be extended directly.
abstract class CollectionMixin {
  factory CollectionMixin._() => null;

  final _behaviorSubject = BehaviorSubject<Map<String, Map<String, dynamic>>>();

  /// Closes the stream.
  ///
  /// This method is executed when the instance is deleted.
  void dispose() => _behaviorSubject?.close();

  /// [Stream] access for [Collection] data.
  Stream<Map<String, Map<String, dynamic>>> get stream => _behaviorSubject.stream;

  /// Changes the data of current [Collection].
  Function(Map<String, Map<String, dynamic>>) get change => _behaviorSubject.sink.add;

  /// Gets the data of current [Collection].
  Map<String, Map<String, dynamic>> get collection => _behaviorSubject.value ?? {};

  /// Adds a document [data] to the [Stream] of current [Collection] if matches with 
  /// the specified [filter].
  void addStream(Map<String, dynamic> data, Map<String, dynamic> filter) {
    final collection = this.collection;
    for (final entry in filter.entries) {
      final key = entry.key;
      final value = entry.value;
      if (data.containsKey(key)) {
        if (data[key] != value) return;
      }
    }
    collection.putIfAbsent(data['local'], () => data);
    change(collection);
  }

  /// Insert the document [data] into local [Database] in a table specified by his [name]
  Future<void> addLocal(String name, Map<String, dynamic> data) async {
    final local = await G3S.instance.local;
    await local.insert(name, data);
  }

  /// Makes a [filter] query into [local] database in a table specified by his [name].
  Future<List<Map<String, dynamic>>> findLocal(Database local, String name, Map<String, dynamic> filter) async {
    final where = filter.keys.map((key) => '$key=?').join(' AND ');
    final whereArgs = filter.values.map((value) => value).toList();
    final documentList = await local.query(
      name,
      where: where.isNotEmpty ? where : 'TRUE',
      whereArgs: whereArgs,
    );
    return documentList;
  }

  /// Updates the [Stream] of current [Collection] with a specified [documentList].
  Map<String, Map<String, dynamic>> updateStream(List<Map<String, dynamic>> documentList) {
    final collection = this.collection;
    collection.clear();
    documentList.forEach((document) {
      final doc = Map<String, dynamic>.from(document);
      collection.putIfAbsent(doc['local'], () => doc);
    });
    change(collection);
    return collection;
  }
}
