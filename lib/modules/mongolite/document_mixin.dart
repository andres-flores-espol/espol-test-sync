import 'package:rxdart/rxdart.dart';

import 'mongolite.dart';

/// This class is intended to be used as a mixin, and should not be extended directly.
abstract class DocumentMixin {
  factory DocumentMixin._() => null;

  final _behaviorSubject = BehaviorSubject<Map<String, dynamic>>();
  void dispose() => _behaviorSubject?.close();

  Stream<Map<String, dynamic>> get stream => _behaviorSubject.stream;
  Function(Map<String, Map<String, dynamic>>) get change => _behaviorSubject.sink.add;
  Map<String, Map<String, dynamic>> get document => _behaviorSubject.value ?? {};

  Map<String, dynamic> updateStream(Map<String, dynamic> changes) {
    final data = document;
    changes.forEach((key, value) {
      data.update(key, (_) => value);
    });
    change(data);
    return data;
  }

  Future<void> updateLocal(String collection, String primaryKey, Map<String, dynamic> changes) async {
    final local = await Mongolite.instance.local;
    await local.update(collection, changes, where: 'local=?', whereArgs: [primaryKey]);
  }
}
