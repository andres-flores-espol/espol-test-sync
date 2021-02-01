import 'package:band_names/modules/g3s/g3s.dart';
import 'package:band_names/models/client.dart';

class ClientIncidence extends Model {
  static Collection<Client> get _clientCollection => G3S.instance.collection('client');
  static final Map<String, String> schema = {
    'local': 'TEXT PRIMARY KEY', // REQUIRED
    'remote': 'TEXT UNIQUE', // REQUIRED
    'incidence': 'TEXT',
    'action': 'TEXT',
    'deviceImage': 'TEXT',
    'cloudImage': 'TEXT',
    'client': 'TEXT ${_clientCollection.reference}',
  };

  String incidence;
  String action;
  String deviceImage;
  String cloudImage;
  String client;

  ClientIncidence({
    String local,
    String remote,
    this.incidence,
    this.action,
    this.deviceImage,
    this.cloudImage,
    this.client,
  }) : super(local: local, remote: remote);

  static ClientIncidence fromMap(Map<String, dynamic> obj) {
    if (obj == null) return null;
    if (obj.length == 0) return null;
    return ClientIncidence(
      local: obj['local'],
      remote: obj['remote'] ?? obj['_id'] ?? obj['local'],
      incidence: obj['incidence'],
      action: obj['action'],
      deviceImage: obj['deviceImage'],
      cloudImage: obj['cloudImage'],
      client: obj['client'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'local': local,
      'remote': remote,
      'incidence': incidence,
      'action': action,
      'deviceImage': deviceImage,
      'cloudImage': cloudImage,
      'client': client,
    };
  }
}
