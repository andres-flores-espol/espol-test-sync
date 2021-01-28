import 'package:rxdart/rxdart.dart';

import '../../g3s.dart';

const add = "\$add";
const update = "\$update";
const where = "\$where";
const delete = "\$delete";

/// This class is intended to be used as a mixin, and should not be extended directly.
abstract class DocumentMixin<T extends Model> {
  factory DocumentMixin._() => null;

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
}
