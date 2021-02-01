import 'package:band_names/modules/g3s/g3s.dart';
import 'package:band_names/models/roadmap.dart';

class City extends Model {
  static Collection<Roadmap> get _roadmapCollection => G3S.instance.collection('roadmap');
  static final Map<String, String> schema = {
    'local': 'TEXT PRIMARY KEY', // REQUIRED
    'remote': 'TEXT UNIQUE', // REQUIRED
    'name': 'TEXT',
    'state': 'INTEGER',
    'roadmap': 'TEXT ${_roadmapCollection.reference}',
  };

  String name;
  int state;
  String roadmap;

  City({
    String local,
    String remote,
    this.name,
    this.state,
    this.roadmap,
  }) : super(local: local, remote: remote);

  static Future<City> fromMap(Map<String, dynamic> obj) async {
    if (obj == null) return null;
    if (obj.length == 0) return null;
    return City(
      local: obj['local'],
      remote: obj['remote'] ?? obj['_id'] ?? obj['local'],
      name: obj['name'],
      state: obj['state'],
      roadmap: obj['roadmap'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'local': local,
      'remote': remote,
      'name': name,
      'state': state,
      'roadmap': roadmap,
    };
  }
}
