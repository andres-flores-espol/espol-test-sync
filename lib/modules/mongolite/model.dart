import 'package:band_names/modules/mongolite/object_id.dart';

/// Abstract class definition for [Model].
///
/// Use [Model] abstract class to define inherited class for [Mongolite] collections
/// and documents.
///
/// **Example:**
///
/// ```dart
/// class SomeModel extends Model {
///   static final Map<String, String> schema = {
///     'local': 'TEXT PRIMARY KEY,', // Required
///     'remote': 'TEXT UNIQUE,', // Required
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
///     return Band(
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
/// Mongolite.instance.setDatabase(dbProvider);
/// Mongolite.instance.setSchema<SomeModel>(
///   'some_collection',
///   SomeModel.schema,
///   SomeModel.fromMap,
/// );
/// ```
abstract class Model {
  /// The [local] attribute refers to an hexadecimal [String] of an [ObjectId].
  /// 
  /// Use as `TEXT PRIMARY KEY` of [Mongolite] local [Database] to select a
  /// [Document] of a [Collection] with `Mongolite.instance.collection('some_collection').doc(local)`.
  String local;
  
  /// The [remote] attribute refers to an hexadecimal [String] of an [ObjectId].
  /// 
  /// Use as `TEXT UNIQUE` of [Mongolite] local [Database] to emit changes of a 
  /// [Document] to the syncronization services.
  String remote;

  /// Sets the [local] and [remote] attributes with an [ObjectId] hexadecimal [String]
  /// value.
  Model({String local, String remote}) {
    this.local = ObjectId(local).str;
    this.remote = ObjectId(remote ?? local).str;
  }

  /// Transform a [Model] instance to a [Map] of [String] key and [dynamic] value.
  /// 
  /// Requires to be implemented
  Map<String, dynamic> toMap() {
    throw "toMap method is not implemented";
  }
}
