import 'package:band_names/modules/g3s/g3s.dart';

import 'band.dart';

class BandCity extends Model {
  static Collection<Band> get _bandCollection => G3S.instance.collection('band');
  static final Map<String, String> schema = {
    'local': 'TEXT PRIMARY KEY', // REQUIRED
    'remote': 'TEXT UNIQUE', // REQUIRED
    'name': 'TEXT',
    'country': 'TEXT',
    'band': 'TEXT ${_bandCollection.reference}'
  };

  String name;
  String country;
  String band;

  BandCity({
    String local,
    String remote,
    this.name,
    this.country,
    this.band,
  }) : super(local: local, remote: remote);

  static BandCity fromMap(Map<String, dynamic> obj) {
    if (obj == null) return null;
    if (obj.length == 0) return null;
    return BandCity(
      local: obj['local'],
      remote: obj['remote'] ?? obj['_id'] ?? obj['local'],
      name: obj['name'],
      country: obj['country'],
      band: obj['band'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'local': local,
      'remote': remote,
      'name': name,
      'country': country,
      'band': band,
    };
  }
}
