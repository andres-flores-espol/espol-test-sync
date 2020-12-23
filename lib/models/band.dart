import 'package:band_names/modules/fire_mongo/fire_mongo.dart';

class Band {
  static final Map<String, String> schema = {
    'name': 'TEXT',
    'votes': 'INTEGER',
  };

  String name;
  int votes;

  Band({this.name, this.votes});

  factory Band.fromMap(Map<String, dynamic> obj) {
    return Band(
      name: obj['name'],
      votes: obj['votes'],
    );
  }
}

// void test() {
//   // init
//   FireMongo.instance.setSchema('bands', Band.schema);
//   // use
//   FireMongo.instance.collection('bands').doc('123').get();
// }
