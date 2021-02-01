import 'package:band_names/modules/g3s/g3s.dart';

class Term extends Model {
  static final Map<String, String> schema = {
    'local': 'TEXT PRIMARY KEY', // REQUIRED
    'remote': 'TEXT UNIQUE', // REQUIRED
    'code': 'TEXT',
    'name': 'TEXT',
    'days': 'INTEGER',
  };

  String code;
  String name;
  int days;

  Term({
    String local,
    String remote,
    this.code,
    this.name,
    this.days,
  }) : super(local: local, remote: remote);

  static Future<Term> fromMap(Map<String, dynamic> obj) async {
    if (obj == null) return null;
    if (obj.length == 0) return null;
    return Term(
      local: obj['local'],
      remote: obj['remote'] ?? obj['_id'] ?? obj['local'],
      code: obj['code'],
      name: obj['name'],
      days: obj['days'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'local': local,
      'remote': remote,
      'code': code,
      'name': name,
      'days': days,
    };
  }
}
