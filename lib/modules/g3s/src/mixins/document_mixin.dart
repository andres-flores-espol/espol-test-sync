import 'package:rxdart/rxdart.dart';

import '../../g3s.dart';

/// This class is intended to be used as a mixin, and should not be extended directly.
abstract class DocumentMixin<T extends Model> {
  factory DocumentMixin._() => null;

  Collection<T> _collection;

  /// Gets the collection reference for this [Document].
  Collection<T> get collection => _collection;
  /// Sets the collection parent of this [Document].
  /// 
  /// Do not use this method out of [Document] constructor.
  void setCollection(Collection<T> collection) {
    _collection = collection;
  }

  final _behaviorSubject = BehaviorSubject<Map<String, dynamic>>();

  /// Closes the stream.
  /// 
  /// This method is executed when the instance is deleted.
  void dispose() => _behaviorSubject?.close();

  /// [Stream] access for [Document] data.
  Stream<Map<String, dynamic>> get stream => _behaviorSubject.stream;
  /// Changes the data of current [Document].
  Function(Map<String, dynamic>) get change => _behaviorSubject.sink.add;
  /// Gets the data of current [Document].
  Map<String, dynamic> get document => _behaviorSubject.value ?? {};

  /// Updates the data on the [Stream] of current [Document] and updates 
  /// the [Document] on the [Stream] of his [Collection] reference.
  Map<String, dynamic> updateStream(Map<String, dynamic> changes) {
    final data = document;
    final collection = this.collection.collection;
    changes.forEach((key, value) {
      data.update(key, (_) => value);
    });
    change(data);
    for (final entry in this.collection.filter.entries) {
      final key = entry.key;
      final value = entry.value;
      if (data.containsKey(key)) {
        if (data[key] != value) {
          collection.remove(data['local']);
          this.collection.change(collection);
          return data;
        }
      }
    }
    collection[data['local']] = data;
    this.collection.change(collection);
    return data;
  }

  /// Updates the data of current [Document] at the local [Database].
  Future<void> updateLocal(String collection, String primaryKey, Map<String, dynamic> changes) async {
    final local = await G3S.instance.local;
    await local.update(collection, changes, where: 'local=?', whereArgs: [primaryKey]);
  }

  /// Deletes the data from the [Stream] of current [Document] and deletes 
  /// the [Document] from the [Stream] of his [Collection] reference.
  Map<String, dynamic> deleteStream() {
    final data = document;
    final collection = this.collection.collection;
    collection.remove(data['local']);
    change(null);
    this.collection.change(collection);
    return data;
  }

  /// Deletes the data of current [Document] from the local [Database].
  Future<void> deleteLocal(String collection, String primaryKey) async {
    final local = await G3S.instance.local;
    await local.delete(collection, where: 'local=?', whereArgs: [primaryKey]);
  }
}
