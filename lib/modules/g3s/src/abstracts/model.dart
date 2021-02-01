import '../../g3s.dart';

/// Abstract class definition for [Model].
///
/// Use [Model] abstract class to define inherited class for [G3S] collections
/// and documents.
///
/// **Example:**
///
/// ```dart
/// class SomeModel extends Model {
///   static final Map<String, String> schema = {
///     'local': 'TEXT PRIMARY KEY', // Required
///     'remote': 'TEXT UNIQUE', // Required
///     'someText': 'TEXT',
///     'someInteger': 'INTEGER',
///   }
///
///   String someText;
///   int someInteger;
///
///   SomeModel({
///     String local,
///     String remote,
///     this.someText,
///     this.someInteger,
///   }) : super(local: local, remote: remote);
///
///   // Required static method
///   static SomeModel fromMap(Map<String, dynamic> obj) {
///     return SomeModel(
///       local: obj['local'], // Required
///       remote: obj['remote'] ?? obj['_id'] ?? obj['local'], // Required
///       someText: obj['someText'],
///       SomeInteger: obj['SomeInteger'],
///     );
///   }
///
///   // Required method
///   @override
///   Map<String, dynamic> toMap() {
///     return {
///       'local': local, // Required
///       'remote': remote, // Required
///       'someText': someText,
///       'someInteger': someInteger,
///     };
///   }
/// }
/// ```
///
/// To make use of inherited class from [Model] type this at `main` function (????):
/// ```dart
/// final dbProvider = DBProvider();
/// G3S.instance.setDatabase(dbProvider);
/// G3S.instance.setSchema<SomeModel>(
///   'some_collection',
///   SomeModel.schema,
///   SomeModel.fromMap,
/// );
/// ```
abstract class Model {
  /// The [local] attribute refers to an hexadecimal [String] of an [ObjectId].
  ///
  /// Use as `TEXT PRIMARY KEY` of [G3S] local [Database] to select a
  /// [Document] of a [Collection] with `G3S.instance.collection('some_collection').doc(local)`.
  String local;

  /// The [remote] attribute refers to an hexadecimal [String] of an [ObjectId].
  ///
  /// Use as `TEXT UNIQUE` of [G3S] local [Database] to emit changes of a
  /// [Document] to the syncronization services.
  String remote;

  /// Sets the [local] and [remote] attributes with an [ObjectId] hexadecimal [String]
  /// value.
  Model({String local, String remote}) {
    this.local = ObjectId(local).str;
    this.remote = ObjectId(remote ?? this.local).str;
  }

  /// Transform a [Model] instance to a [Map] of [String] key and [dynamic] value.
  ///
  /// Requires to be implemented
  Map<String, dynamic> toMap() {
    throw "toMap method is not implemented";
  }

  toJson() => this.toMap();

  static Future<T> childOf<T extends Model>(
    Map<String, dynamic> parent,
    String collectionName,
    String field,
  ) async {
    final Collection<T> subCollection = G3S.instance.collection('$collectionName.$field');
    T child;
    if (!parent.containsKey(field)) {
      final childrenCollection = subCollection.where({collectionName: parent['local']});
      final children = await childrenCollection.get(true);
      child = children.isNotEmpty ? children[0] : null;
    } else if (parent[field] is String) {
      child = await subCollection.doc(parent[field]).get(true);
    } else if (parent[field] is Map) {
      parent[field][collectionName] = parent['local'];
      child = await subCollection.fromMap(parent[field]);
    }
    return child;
  }

  static Future<List<T>> childrenOf<T extends Model>(
    Map<String, dynamic> parent,
    String collectionName,
    String field,
  ) async {
    final Collection<T> subCollection = G3S.instance.collection('$collectionName.$field');
    List<T> children = List<T>();
    if (!parent.containsKey(field)) {
      final childrenCollection = subCollection.where({collectionName: parent['local']});
      children = await childrenCollection.get(true);
    } else {
      final currentField = parent[field];
      if (currentField is List) {
        if (currentField is List<String>) {
          children = await Future.wait<T>(currentField.map((child) => subCollection.doc(child).get(true)));
        } else if (currentField is List<Map>) {
          children = await Future.wait<T>(currentField.map((child) => subCollection.fromMap(child)));
        }
      }
    }
    return children;
  }
}
