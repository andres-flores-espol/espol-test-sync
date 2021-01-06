import 'package:rxdart/rxdart.dart';

import '../../g3s.dart';

const add = "\$add";
const update = "\$update";
const where = "\$where";
const delete = "\$delete";

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
      if (!(value is List || value is Map)) {
        data.update(key, (_) => value);
      }
    });
    change(data);
    for (final entry in this.collection.currentFilter.entries) {
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
  Future<void> updateLocal(String name, String primaryKey, Map<String, dynamic> changes) async {
    final doc = (await collection.fromMap(document)).toMap();
    final entries = changes.entries.toList();
    for (var entry in entries) {
      final key = entry.key;
      final value = entry.value;
      if (value is Map) {
        await G3S.instance.collection('$name.$key').doc(doc[key]['local']).update(value);
        changes.remove(key);
      } else if (value is List) {
        // Only pipelines
        for (var pipeline in value) {
          if (pipeline is Map) {
            if (pipeline.containsKey('$add')) {
              if (pipeline['$add'] is Map) {
                await G3S.instance.collection('$name.$key').add(pipeline['$add']);
              }
            } else if (pipeline.containsKey('$update')) {
              if (pipeline['$update'] is Map) {
                pipeline['$where'] = pipeline['$where'] ?? {};
                if (pipeline['$where'] is Map) {
                  final documentList = await G3S.instance.collection('$name.$key').where(pipeline['$where']).get();
                  await Future.wait(documentList.map((e) async {
                    await G3S.instance.collection('$name.$key').doc(e.local).update(pipeline['$update']);
                  }));
                }
              }
            } else if (pipeline.containsKey('$delete')) {
              if (pipeline['$delete'] is Map) {
                final documentList = await G3S.instance.collection('$name.$key').where(pipeline['$delete']).get();
                await Future.wait(documentList.map((e) async {
                  await G3S.instance.collection('$name.$key').doc(e.local).delete();
                }));
              }
            }
          }
        }
        changes.remove(key);
      }
    }
    final local = await G3S.instance.local;
    await local.update('\"g3s.$name\"', changes, where: 'local=?', whereArgs: [primaryKey]);
  }
}
