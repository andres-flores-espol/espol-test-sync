import 'package:band_names/modules/g3s/g3s.dart';
import 'package:band_names/models/invoice.dart';

class InvoiceSeller extends Model {
  static Collection<Invoice> get _invoiceCollection => G3S.instance.collection('invoice');
  static final Map<String, String> schema = {
    'local': 'TEXT PRIMARY KEY', // REQUIRED
    'remote': 'TEXT UNIQUE', // REQUIRED
    'name': 'TEXT',
    'rut': 'TEXT',
    'code': 'INTEGER',
    'phone': 'TEXT',
    'email': 'TEXT',
    'invoice': 'TEXT ${_invoiceCollection.reference}'
  };

  String name;
  String rut;
  int code;
  String phone;
  String email;
  String invoice;

  InvoiceSeller({
    String local,
    String remote,
    this.name,
    this.rut,
    this.code,
    this.phone,
    this.email,
    this.invoice,
  }) : super(local: local, remote: remote);

  static InvoiceSeller fromMap(Map<String, dynamic> obj) {
    if (obj == null) return null;
    if (obj.length == 0) return null;
    return InvoiceSeller(
      local: obj['local'],
      remote: obj['remote'] ?? obj['_id'] ?? obj['local'],
      name: obj['name'],
      rut: obj['rut'],
      code: obj['code'],
      phone: obj['phone'],
      email: obj['email'],
      invoice: obj['invoice'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'local': local,
      'remote': remote,
      'name': name,
      'rut': rut,
      'code': code,
      'phone': phone,
      'email': email,
      'invoice': invoice,
    };
  }
}
