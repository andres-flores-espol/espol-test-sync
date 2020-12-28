import 'package:rxdart/rxdart.dart';

import '../../g3s.dart';

/// This class is intended to be used as a mixin, and should not be extended directly.
abstract class CollectionMixin {
  factory CollectionMixin._() => null;

  final _behaviorSubject = BehaviorSubject<Map<String, Map<String, dynamic>>>();
  void dispose() => _behaviorSubject?.close();

  Stream<Map<String, Map<String, dynamic>>> get stream => _behaviorSubject.stream;
  Function(Map<String, Map<String, dynamic>>) get change => _behaviorSubject.sink.add;
  Map<String, Map<String, dynamic>> get collection => _behaviorSubject.value ?? {};

  void addStream(Map<String, dynamic> data) {
    final collection = this.collection;
    collection.putIfAbsent(data['local'], () => data);
    change(collection);
  }

  Future<void> addLocal(String name, Map<String, dynamic> data) async {
    final local = await G3S.instance.local;
    await local.insert(name, data);
  }
}
