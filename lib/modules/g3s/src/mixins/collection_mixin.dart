import 'package:rxdart/rxdart.dart';
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
}
