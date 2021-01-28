import 'package:band_names/models/roadmap_expense.dart';
import 'package:band_names/models/roadmap_vehicle.dart';
import 'package:band_names/modules/g3s/g3s.dart';

class Roadmap extends Model {
  static final Map<String, String> schema = {
    'local': 'TEXT PRIMARY KEY', // REQUIRED
    'remote': 'TEXT UNIQUE', // REQUIRED
    'code': 'INTEGER',
    'weight': 'INTEGER',
    'volume': 'INTEGER',
    'nBox': 'INTEGER',
    'nPallet': 'INTEGER',
    'nCreditnote': 'INTEGER',
    'nDebitnote': 'INTEGER',
    'nEnvelopes': 'INTEGER',
    'roadmapDocument': 'BOOLEAN',
    'manifestPacking': 'BOOLEAN',
    'zone': 'TEXT',
    'observation': 'TEXT',
    'state': 'INTEGER',
    'iduser': 'TEXT',
  };

  int code;
  int weight;
  int volume;
  int nBox;
  int nPallet;
  int nCreditnote;
  int nDebitnote;
  int nEnvelopes;
  bool roadmapDocument;
  bool manifestPacking;
  String zone;
  String observation;
  int state;
  String iduser;
  RoadmapVehicle vehicle;
  List<RoadmapExpense> expense;

  Roadmap({
    String local,
    String remote,
    this.code,
    this.weight,
    this.volume,
    this.nBox,
    this.nPallet,
    this.nCreditnote,
    this.nDebitnote,
    this.nEnvelopes,
    this.roadmapDocument,
    this.manifestPacking,
    this.zone,
    this.observation,
    this.state,
    this.iduser,
    this.vehicle,
    this.expense,
  }) : super(local: local, remote: remote) {
    this.vehicle.roadmap = this.local;
    this.expense.asMap().forEach((index, value) {
      this.expense[index].roadmap = this.local;
    });
  }

  static Future<Roadmap> fromMap(Map<String, dynamic> obj) async {
    if (obj == null) return null;
    if (obj.length == 0) return null;
    RoadmapVehicle vehicle = await Model.childOf<RoadmapVehicle>(obj, 'roadmap', 'vehicle');
    List<RoadmapExpense> expense = await Model.childrenOf<RoadmapExpense>(obj, 'roadmap', 'expense');
    return Roadmap(
      local: obj['local'],
      remote: obj['remote'] ?? obj['_id'] ?? obj['local'],
      code: obj['code'],
      weight: obj['weight'],
      volume: obj['volume'],
      nBox: obj['nBox'],
      nPallet: obj['nPallet'],
      nCreditnote: obj['nCreditnote'],
      nDebitnote: obj['nDebitnote'],
      nEnvelopes: obj['nEnvelopes'],
      roadmapDocument: obj['roadmapDocument'] == 1,
      manifestPacking: obj['manifestPacking'] == 1,
      zone: obj['zone'],
      observation: obj['observation'],
      state: obj['state'],
      iduser: obj['iduser'],
      vehicle: vehicle,
      expense: expense,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'local': local,
      'remote': remote,
      'code': code,
      'weight': weight,
      'volume': volume,
      'nBox': nBox,
      'nPallet': nPallet,
      'nCreditnote': nCreditnote,
      'nDebitnote': nDebitnote,
      'nEnvelopes': nEnvelopes,
      'roadmapDocument': roadmapDocument ? 1 : 0,
      'manifestPacking': manifestPacking ? 1 : 0,
      'zone': zone,
      'observation': observation,
      'state': state,
      'iduser': iduser,
      'vehicle': vehicle?.toMap(),
      'expense': expense.map((e) => e.toMap()).toList(),
    };
  }
}
