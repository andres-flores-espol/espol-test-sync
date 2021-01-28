import 'package:band_names/models/band_city.dart';
import 'package:band_names/modules/g3s/g3s.dart';

class Band extends Model {
  static final Map<String, String> schema = {
    'local': 'TEXT PRIMARY KEY', // REQUIRED
    'remote': 'TEXT UNIQUE', // REQUIRED
    'name': 'TEXT',
    'votes': 'INTEGER',
  };

  String name;
  int votes;
  BandCity city;

  Band({
    String local,
    String remote,
    this.name,
    this.votes,
    this.city,
  }) : super(local: local, remote: remote) {
    this.city.band = this.local;
  }

  static Future<Band> fromMap(Map<String, dynamic> obj) async {
    if (obj == null) return null;
    if (obj.length == 0) return null;
    BandCity city = await Model.childOf<BandCity>(obj, 'band', 'city');
    return Band(
      local: obj['local'],
      remote: obj['remote'] ?? obj['_id'] ?? obj['local'],
      name: obj['name'],
      votes: obj['votes'],
      city: city,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'local': local,
      'remote': remote,
      'name': name,
      'votes': votes,
      'city': city?.toMap(),
    };
  }
}
