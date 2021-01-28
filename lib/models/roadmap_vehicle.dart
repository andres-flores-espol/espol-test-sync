import 'package:band_names/modules/g3s/g3s.dart';

import 'roadmap.dart';

class RoadmapVehicle extends Model {
  static Collection<Roadmap> get _roadmapCollection => G3S.instance.collection('roadmap');
  static final Map<String, String> schema = {
    'local': 'TEXT PRIMARY KEY', // REQUIRED
    'remote': 'TEXT', // REQUIRED
    'code': 'TEXT',
    'patent': 'TEXT',
    'maxWeight': 'INTEGER',
    'maxVolume': 'INTEGER',
    'roadmap': 'TEXT ${_roadmapCollection.reference}'
  };

  String code;
  String patent;
  int maxWeight;
  int maxVolume;
  String roadmap;

  RoadmapVehicle({
    String local,
    String remote,
    this.code,
    this.patent,
    this.maxWeight,
    this.maxVolume,
    this.roadmap,
  }) : super(local: local, remote: remote);

  static RoadmapVehicle fromMap(Map<String, dynamic> obj) {
    if (obj == null) return null;
    if (obj.length == 0) return null;
    return RoadmapVehicle(
      local: obj['local'],
      remote: obj['remote'] ?? obj['_id'] ?? obj['local'],
      code: obj['code'],
      patent: obj['patent'],
      maxWeight: obj['maxWeight'],
      maxVolume: obj['maxVolume'],
      roadmap: obj['roadmap'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'local': local,
      'remote': remote,
      'code': code,
      'patent': patent,
      'maxWeight': maxWeight,
      'maxVolume': maxVolume,
      'roadmap': roadmap,
    };
  }
}
