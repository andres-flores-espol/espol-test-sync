import 'dart:async';
import 'dart:convert';
import '../g3s.dart';

/// A [Document] refers to a document in a [Collection] and can be used to listen,
/// read, write and remove the document.
class Document<T extends Model> with DocumentMixin<T> {
  String _localKey;

  String get localKey => _localKey;

  Collection<T> _collection;

  /// Gets the collection reference for this [Document].
  Collection<T> get collection => _collection;

  bool _remote;

  /// Sets the [Collection] reference and the initial data.
  Document(Collection<T> collection, Map<String, dynamic> data, bool remote) {
    _localKey = data['local'];
    _collection = collection;
    _remote = remote;
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
    final documentList = await collection.where({'local': localKey}).get(forceLocal);
    return documentList.length != 0 ? documentList[0] : null;
  }

  Future<Map<String, dynamic>> _prepareData() async {
    final element = await get(true);
    return element.toMap();
  }

  /// Updates the data on the [Stream] of current [Document] and updates
  /// the [Document] on the [Stream] of his [Collection] reference.
  Map<String, dynamic> _updateStream(Map<String, dynamic> data, Map<String, dynamic> changes) {
    changes.forEach((key, value) {
      if (!(value is Map || value is List)) {
        data.update(key, (_) => value);
      }
    });
    change(data);

    final collection = this.collection.collection;
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

  Future<Map<String, dynamic>> _updateNested(
      Map<String, dynamic> data, Map<String, dynamic> changes, bool forceLocal) async {
    final name = collection.name;
    final entries = changes.entries.toList();
    for (var entry in entries) {
      final key = entry.key;
      final value = entry.value;
      if (value is Map) {
        final child = await G3S.instance.collection('$name.$key').doc(data[key]['local']).update(value, forceLocal);
        data.update(key, (_) => child?.toMap());
        changes.remove(key);
      } else if (value is List) {
        // Only pipelines
        for (var pipeline in value) {
          if (pipeline is Map) {
            if (pipeline.containsKey('\$add')) {
              if (pipeline['\$add'] is Map) {
                final pipelineAdd = Map<String, dynamic>.from(pipeline['\$add']);
                pipelineAdd[name] = data['local'];
                await G3S.instance.collection('$name.$key').add(pipelineAdd, forceLocal);
              }
            } else if (pipeline.containsKey('\$update')) {
              if (pipeline['\$update'] is Map) {
                pipeline['\$where'] = pipeline['\$where'] ?? {};
                if (pipeline['\$where'] is Map) {
                  final pipelineWhere = Map<String, dynamic>.from(pipeline['\$where']);
                  pipelineWhere[name] = data['local'];
                  final documentList = await G3S.instance.collection('$name.$key').where(pipelineWhere).get(true);
                  await Future.wait(documentList.map((e) async {
                    await G3S.instance.collection('$name.$key').doc(e.local).update(pipeline['\$update'], forceLocal);
                  }));
                }
              }
            } else if (pipeline.containsKey('\$delete')) {
              if (pipeline['\$delete'] is Map) {
                final pipelineDelete = Map<String, dynamic>.from(pipeline['\$delete']);
                pipelineDelete[name] = data['local'];
                final documentList = await G3S.instance.collection('$name.$key').where(pipelineDelete).get(true);
                await Future.wait(documentList.map((e) async {
                  await G3S.instance.collection('$name.$key').doc(e.local).delete(forceLocal);
                }));
              }
            }
          }
        }
        final children = await G3S.instance.collection('$name.$key').where({'$name': data['local']}).get(true);
        data.update(key, (_) => children.map((e) => e.toMap()).toList());
        changes.remove(key);
      }
    }
    return changes;
  }

  /// Updates the data of current [Document] at the local [Database].
  Future<void> _updateLocal(Map<String, dynamic> data, Map<String, dynamic> changes) async {
    final name = collection.name;
    final local = await G3S.instance.local;
    await local.update('\"g3s.$name\"', changes, where: 'local=?', whereArgs: [data['local']]);
  }

  void _updateRemote(Map<String, dynamic> data, Map<String, dynamic> changes, bool forceLocal) {
    if (!_remote || forceLocal) return;
    final g3s = G3S.instance;
    g3s.syncCollection.add({
      'collection': collection.name,
      'document': data['local'],
      'method': 'update',
      'arg': json.encode(changes),
      'datetime': (DateTime.now().millisecondsSinceEpoch / 1000).floor(),
    });
    g3s.emit();
  }

  /// Updates the current [Document] with specified [changes].
  Future<T> update(Map<String, dynamic> changes, [forceLocal = false]) async {
    var data = await _prepareData();
    data = _updateStream(data, changes);
    changes = await _updateNested(data, changes, forceLocal);
    await _updateLocal(data, changes);
    _updateRemote(data, changes, forceLocal);
    return await collection.fromMap(data);
  }

  /// Deletes the data from the [Stream] of current [Document] and deletes
  /// the [Document] from the [Stream] of his [Collection] reference.
  void _deleteStream(Map<String, dynamic> data) {
    collection.deleteDoc(data['local']);
    change(null);
  }

  Future<void> _deleteNested(Map<String, dynamic> data) async {
    final name = collection.name;
    final entries = data.entries.toList();
    for (var entry in entries) {
      final key = entry.key;
      final value = entry.value;
      if (value is Map) {
        await G3S.instance.collection('$name.$key').doc(value['local']).delete(true);
      } else if (value is List) {
        for (var element in value) {
          if (element is Map) {
            await G3S.instance.collection('$name.$key').doc(element['local']).delete(true);
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

  void _deleteRemote(Map<String, dynamic> data, bool forceLocal) {
    if (!_remote || forceLocal) return;
    final g3s = G3S.instance;
    final _data = Map<String, dynamic>.from(data);
    _data.removeWhere((key, value) => value is Map || value is List);
    g3s.syncCollection.add({
      'collection': collection.name,
      'document': data['remote'],
      'method': 'delete',
      'arg': json.encode(_data),
      'datetime': (DateTime.now().millisecondsSinceEpoch / 1000).floor(),
    });
    g3s.emit();
  }

  /// Deletes the current [Document].
  Future<T> delete([bool forceLocal = false]) async {
    var data = await _prepareData();
    _deleteStream(data);
    _deleteRemote(data, forceLocal);
    await _deleteNested(data);
    await _deleteLocal(data);
    return await collection.fromMap(data);
  }
}
