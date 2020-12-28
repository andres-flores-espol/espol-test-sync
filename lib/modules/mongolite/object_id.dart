import 'dart:math';

/// Class to create an [ObjectId] as in MongoDB.
class ObjectId {
  static final _random = Random();
  static final _regExp = RegExp(r"^[0-9a-fA-F]+$");
  static final _maxTimestamp = pow(8, 4);
  static final _maxRandom = pow(8, 5);
  static final _maxCount = pow(8, 3);
  static int _count = _random.nextInt(_maxCount) % _maxCount;

  String _hexadecimal;

  /// Construct an [ObjectId] instance with the specified hexadecimal.
  ///
  /// The [hexadecimal] argument must be a non-empty hexadecimal [String], representing a 12
  /// byte number.
  ///
  /// The 12-byte number consits of:
  ///
  /// - a 4-byte *timestamp value*, representing the [ObjectId]’s creation, measured in
  /// seconds since the Unix epoch.
  /// - a 5-byte *random value*.
  /// - a 3-byte *incrementing counter*, initialized to a random value.
  /// 
  /// If the [hexadecimal] argument is null, a new one is generated.
  ObjectId(String hexadecimal) {
    if (hexadecimal == null) {
      final int timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000) % _maxTimestamp;
      final int random = _random.nextInt(_maxRandom) % _maxRandom;
      _count = (_count + 1) % _maxCount;
      final hexTimestamp = timestamp.toRadixString(16).padLeft(8, '0');
      final hexRandom = random.toRadixString(16).padLeft(10, '0');
      final hexCount = _count.toRadixString(16).padLeft(6, '0');
      hexadecimal = '$hexTimestamp$hexRandom$hexCount';
    }
    assert(hexadecimal.isNotEmpty, "ObjectId hexadecimal must be a non-empty string");
    assert(_regExp.hasMatch(hexadecimal), "ObjectId hexadecimal must be an hexadecimal string");
    assert(hexadecimal.length == 24, "ObjectId hexadecimal must be 24 characters length");
    this._hexadecimal = hexadecimal.toLowerCase();
  }

  /// Returns the hexadecimal [String] representation of the [ObjectId].
  String get str => '$_hexadecimal';

  /// Returns the timestamp portion of the [ObjectId] as a [DateTime].
  DateTime getTimestamp() {
    final hexTimestamp = _hexadecimal.substring(0, 8);
    final timestamp = int.parse(hexTimestamp, radix: 16);
    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  }

  /// Returns the Dart representation in the form of a [String] literal `ObjectId(...)`.
  @override
  String toString() => 'ObjectId("$_hexadecimal")';

  /// Returns the representation of the [ObjectId] as a hexadecimal [String]. The returned 
  /// string is the `str` attribute.
  String valueOf() => str;
}
