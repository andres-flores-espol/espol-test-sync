import 'package:band_names/models/band.dart';
import 'package:band_names/modules/fire_mongo/document.dart';
import 'package:band_names/modules/fire_mongo/fire_mongo.dart';

class Collection {
  String _name;
  String get name => _name;

  static final _regExp = RegExp(r"^[a-z]+$");

  Collection(String name) {
    this._name = name;
  }
  // Collection(this._name) {
  //   init();
  // }

  // Future<void> init() async {
  //   FireMongo.instance.getBuilder(this._name)(_name);
  // }

  final _docs = Map<String, Document>();

  Document doc(String id) {
    assert(_docs.containsKey(id), "Document does not exist for key $id");
    return _docs[id];
  }

  Future<Document> create(Map<String, dynamic> data) async {
    
    assert(data != null);
    final newDocument = Document(data);
    return newDocument;
  }

  Future<void> find({Map<String, dynamic> filter = const {}}) async {}
}
