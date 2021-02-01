import 'package:band_names/modules/g3s/g3s.dart';
import 'package:band_names/models/term.dart';
import 'package:band_names/models/roadmap.dart';
import 'package:band_names/models/client.dart';
import 'package:band_names/models/invoice_product.dart';
import 'package:band_names/models/invoice_seller.dart';

class Invoice extends Model {
  static Collection<Term> get _termCollection => G3S.instance.collection('term');
  static Collection<Roadmap> get _roadmapCollection => G3S.instance.collection('roadmap');
  static Collection<Client> get _clientCollection => G3S.instance.collection('client');
  static final Map<String, String> schema = {
    'local': 'TEXT PRIMARY KEY', // REQUIRED
    'remote': 'TEXT UNIQUE', // REQUIRED
    'code': 'INTEGER',
    'nOrder': 'INTEGER',
    'totalAmount': 'INTEGER',
    'netValue': 'INTEGER',
    'iva': 'INTEGER',
    'ila': 'INTEGER',
    'term': 'TEXT ${_termCollection.reference}',
    'roadmap': 'TEXT ${_roadmapCollection.reference}',
    'client': 'TEXT ${_clientCollection.reference}',
    'type': 'TEXT',
    'state': 'INTEGER',
    'incidence': 'TEXT',
  };

  int code;
  int nOrder;
  int totalAmount;
  int netValue;
  int iva;
  int ila;
  String term;
  String roadmap;
  String client;
  String type;
  int state;
  String incidence;
  List<InvoiceProduct> product;
  InvoiceSeller seller;

  Invoice({
    String local,
    String remote,
    this.code,
    this.nOrder,
    this.totalAmount,
    this.netValue,
    this.iva,
    this.ila,
    this.term,
    this.roadmap,
    this.client,
    this.type,
    this.state,
    this.incidence,
    this.product,
    this.seller,
  }) : super(local: local, remote: remote) {
    this.seller?.invoice = this.local;
    this.product?.asMap()?.forEach((index, value) {
      this.product[index]?.invoice = this.local;
    });
  }

  static Future<Invoice> fromMap(Map<String, dynamic> obj) async {
    if (obj == null) return null;
    if (obj.length == 0) return null;
    List<InvoiceProduct> product = await Model.childrenOf<InvoiceProduct>(obj, 'invoice', 'product');
    InvoiceSeller seller = await Model.childOf<InvoiceSeller>(obj, 'invoice', 'seller');
    return Invoice(
      local: obj['local'],
      remote: obj['remote'] ?? obj['_id'] ?? obj['local'],
      code: obj['code'],
      nOrder: obj['nOrder'],
      totalAmount: obj['totalAmount'],
      netValue: obj['netValue'],
      iva: obj['iva'],
      ila: obj['ila'],
      term: obj['term'],
      roadmap: obj['roadmap'],
      client: obj['client'],
      type: obj['type'],
      state: obj['state'],
      incidence: obj['incidence'],
      product: product,
      seller: seller,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'local': local,
      'remote': remote,
      'code': code,
      'nOrder': nOrder,
      'totalAmount': totalAmount,
      'netValue': netValue,
      'iva': iva,
      'ila': ila,
      'term': term,
      'roadmap': roadmap,
      'client': client,
      'type': type,
      'state': state,
      'incidence': incidence,
      'product': product.map((e) => e.toMap()).toList(),
      'seller': seller?.toMap(),
    };
  }
}
