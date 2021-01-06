import 'package:band_names/models/band_city.dart';
import 'package:band_names/modules/g3s/g3s.dart';

class Band extends Model {
  static Collection<BandCity> get _bandCityCollection => G3S.instance.collection('band.city');
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
  }) : super(local: local, remote: remote);

  static Future<Band> fromMap(Map<String, dynamic> obj) async {
    if (obj == null) return null;
    BandCity city;
    if (!obj.containsKey('city')) {
      final cityList = await _bandCityCollection.where({'band': obj['local']}).get(true);
      city = cityList.isNotEmpty ? cityList[0] : null;
    } else if (obj['city'] is String) {
      city = await _bandCityCollection.doc(obj['city']).get(true);
    } else if (obj['city'] is Map) {
      city = BandCity.fromMap(obj['city']);
    }
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

// void test() async {
//   // init
//   final dbProvider = DBProvider();
//   final socketService = SocketService();
//   G3S.instance.setDatabaseProvider(dbProvider);
//   G3S.instance.setIOSocket(socketService.socket);
//   G3S.instance.setSchema<Band>('bands', Band.schema, Band.fromMap);
//   // use
//   final g3s = G3S.instance;
//   final Collection<Band> bands = g3s.collection('bands');
//   // create
//   var doc = await bands.add({
//     'name': 'Metallica',
//     'votes': 0,
//   });
//   // read collection
//   final bandsStream = bands.snapshots();
//   bandsStream.listen((value) {
//     print(value);
//   });
//   final bandsFuture = bands.get();
//   bandsFuture.then((value) {
//     print(value);
//   });
//   // read collection with filters
//   final bandsFilteredStream = bands.where({'votes': 0}).snapshots();
//   bandsFilteredStream.listen((value) {
//     print(value);
//   });
//   final bandsFilteredFuture = bands.where({'votes': 0}).get();
//   bandsFilteredFuture.then((value) {
//     print(value);
//   });
//   // read document
//   final band = bands.doc(doc.local);
//   final bandStream = band.snapshots();
//   bandStream.listen((value) {
//     print(value);
//   });
//   final bandFuture = band.get();
//   bandFuture.then((value) {
//     print(value);
//   });
//   // update document
//   doc = await band.update({'votes': doc.votes + 1});
//   // delete document
//   await band.delete();
// }
