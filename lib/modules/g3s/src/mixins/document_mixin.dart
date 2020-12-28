import 'package:rxdart/rxdart.dart';

import '../../g3s.dart';

/// This class is intended to be used as a mixin, and should not be extended directly.
abstract class DocumentMixin {
  factory DocumentMixin._() => null;

  final _behaviorSubject = BehaviorSubject<Map<String, dynamic>>();
  void dispose() => _behaviorSubject?.close();

  Stream<Map<String, dynamic>> get stream => _behaviorSubject.stream;
  Function(Map<String, dynamic>) get change => _behaviorSubject.sink.add;
  Map<String, dynamic> get document => _behaviorSubject.value ?? {};

  Map<String, dynamic> updateStream(Map<String, dynamic> changes) {
    final data = document;
    changes.forEach((key, value) {
      data.update(key, (_) => value);
    });
    change(data);
    return data;
  }

  Future<void> updateLocal(String collection, String primaryKey, Map<String, dynamic> changes) async {
    final local = await G3S.instance.local;
    await local.update(collection, changes, where: 'local=?', whereArgs: [primaryKey]);
  }

  Map<String, dynamic> deleteStream() {
    final data = document;
    change(null);
    return data;
  }

  Future<void> deleteLocal(String collection, String primaryKey) async {
    final local = await G3S.instance.local;
    await local.delete(collection, where: 'local=?', whereArgs: [primaryKey]);
  }
}
