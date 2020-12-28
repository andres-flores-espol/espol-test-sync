import 'package:band_names/modules/mongolite/mongolite.dart';
import 'package:band_names/modules/mongolite/model.dart';
import 'package:band_names/provider/db.dart';

class Band extends Model {
  static final Map<String, String> schema = {
    'local': 'TEXT PRIMARY KEY,', // REQUIRED
    'remote': 'TEXT UNIQUE,', // REQUIRED
    'name': 'TEXT',
    'votes': 'INTEGER',
  };

  String name;
  int votes;

  Band({
    String local,
    String remote,
    this.name,
    this.votes,
  }) : super(local: local, remote: remote);

  static Band fromMap(Map<String, dynamic> obj) {
    return Band(
      local: obj['local'],
      remote: obj['remote'] ?? obj['_id'] ?? obj['local'],
      name: obj['name'],
      votes: obj['votes'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'local': local,
      'remote': remote,
      'name': name,
      'votes': votes,
    };
  }
}

void test() async {
  // init
  final dbProvider = DBProvider();
  Mongolite.instance.setDatabase(dbProvider);
  Mongolite.instance.setSchema<Band>('bands', Band.schema, Band.fromMap);
  // use
  Band band = await Mongolite.instance.collection('bands').doc('123').get();
  print(band);
}
