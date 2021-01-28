import '../g3s.dart';

class Sync extends Model {
  static final Map<String, String> schema = {
    'local': 'TEXT PRIMARY KEY', // REQUIRED
    'remote': 'TEXT UNIQUE', // REQUIRED BUT USELESS
    'collection': 'TEXT',
    'document': 'TEXT',
    'method': 'TEXT',
    'arg': 'TEXT',
    'datetime': 'INTEGER',
  };

  String collection;
  String document;
  String method;
  String arg;
  int datetime;

  Sync({
    String local,
    String remote,
    this.collection,
    this.document,
    this.method,
    this.arg,
    this.datetime,
  }) : super(local: local, remote: remote);

  static Future<Sync> fromMap(Map<String, dynamic> obj) async {
    if (obj == null) return null;
    return Sync(
      local: obj['local'],
      remote: obj['remote'] ?? obj['_id'] ?? obj['local'],
      collection: obj['collection'],
      document: obj['document'],
      method: obj['method'],
      arg: obj['arg'],
      datetime: obj['datetime'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'local': local,
      'remote': remote,
      'collection': collection,
      'document': document,
      'method': method,
      'arg': arg,
      'datetime': datetime,
    };
  }
}
