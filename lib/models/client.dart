import 'package:band_names/modules/g3s/g3s.dart';
import 'package:band_names/models/term.dart';
import 'package:band_names/models/roadmap.dart';
import 'package:band_names/models/city.dart';
import 'package:band_names/models/client_incidence.dart';

class Client extends Model {
  static Collection<Term> get _termCollection => G3S.instance.collection('term');
  static Collection<Roadmap> get _roadmapCollection => G3S.instance.collection('roadmap');
  static Collection<City> get _cityCollection => G3S.instance.collection('city');
  static final Map<String, String> schema = {
    'local': 'TEXT PRIMARY KEY', // REQUIRED
    'remote': 'TEXT UNIQUE', // REQUIRED
    'name': 'TEXT',
    'rut': 'TEXT',
    'envelope': 'INTEGER',
    'city': 'TEXT ${_cityCollection.reference}',
    'address': 'TEXT',
    'type': 'TEXT',
    'phone': 'TEXT',
    'lon': 'TEXT',
    'lat': 'TEXT',
    'roadmap': 'TEXT ${_roadmapCollection.reference}',
    'state': 'INTEGER',
    'term': 'TEXT ${_termCollection.reference}',
  };

  String name;
  String rut;
  int envelope;
  String city;
  String address;
  String type;
  String phone;
  String lon;
  String lat;
  String roadmap;
  int state;
  String term;
  List<ClientIncidence> incidences;

  Client({
    String local,
    String remote,
    this.name,
    this.rut,
    this.envelope,
    this.city,
    this.address,
    this.type,
    this.phone,
    this.lon,
    this.lat,
    this.roadmap,
    this.state,
    this.term,
    this.incidences,
  }) : super(local: local, remote: remote);

  static Future<Client> fromMap(Map<String, dynamic> obj) async {
    if (obj == null) return null;
    if (obj.length == 0) return null;
    List<ClientIncidence> incidences = await Model.childrenOf<ClientIncidence>(obj, 'client', 'incidences');
    return Client(
      local: obj['local'],
      remote: obj['remote'] ?? obj['_id'] ?? obj['local'],
      name: obj['name'],
      rut: obj['rut'],
      envelope: obj['envelope'],
      city: obj['city'],
      address: obj['address'],
      type: obj['type'],
      phone: obj['phone'],
      lon: obj['lon'],
      lat: obj['lat'],
      roadmap: obj['roadmap'],
      state: obj['state'],
      term: obj['term'],
      incidences: incidences,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'local': local,
      'remote': remote,
      'name': name,
      'rut': rut,
      'envelope': envelope,
      'city': city,
      'address': address,
      'type': type,
      'phone': phone,
      'lon': lon,
      'lat': lat,
      'roadmap': roadmap,
      'state': state,
      'term': term,
      'incidences': incidences.map((e) => e.toMap()).toList(),
    };
  }
}
