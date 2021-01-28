import 'package:band_names/modules/g3s/g3s.dart';

import 'roadmap.dart';

class RoadmapExpense extends Model {
  static Collection<Roadmap> get _roadmapCollection => G3S.instance.collection('roadmap');
  static final Map<String, String> schema = {
    'local': 'TEXT PRIMARY KEY', // REQUIRED
    'remote': 'TEXT', // REQUIRED
    'code': 'INTEGER',
    'price': 'INTEGER',
    'type': 'TEXT',
    'image': 'TEXT',
    'roadmap': 'TEXT ${_roadmapCollection.reference}'
  };

  int code;
  int price;
  String type;
  String image;
  String roadmap;

  RoadmapExpense({
    String local,
    String remote,
    this.code,
    this.price,
    this.type,
    this.image,
    this.roadmap,
  }) : super(local: local, remote: remote);

  static RoadmapExpense fromMap(Map<String, dynamic> obj) {
    if (obj == null) return null;
    if (obj.length == 0) return null;
    return RoadmapExpense(
      local: obj['local'],
      remote: obj['remote'] ?? obj['_id'] ?? obj['local'],
      code: obj['code'],
      price: obj['price'],
      type: obj['type'],
      image: obj['image'],
      roadmap: obj['roadmap'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'local': local,
      'remote': remote,
      'code': code,
      'price': price,
      'type': type,
      'image': image,
      'roadmap': roadmap,
    };
  }
}
