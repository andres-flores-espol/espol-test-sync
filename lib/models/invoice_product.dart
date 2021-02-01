import 'package:band_names/modules/g3s/g3s.dart';
import 'package:band_names/models/invoice.dart';
import 'package:band_names/models/invoice_product_incidence.dart';

class InvoiceProduct extends Model {
  static Collection<Invoice> get _invoiceCollection => G3S.instance.collection('invoice');
  static final Map<String, String> schema = {
    'local': 'TEXT PRIMARY KEY', // REQUIRED
    'remote': 'TEXT UNIQUE', // REQUIRED
    'sku': 'TEXT',
    'name': 'TEXT',
    'description': 'TEXT',
    'amount': 'INTEGER',
    'quantity': 'INTEGER',
    'imgS': 'TEXT',
    'imgM': 'TEXT',
    'ila': 'REAL',
    'discount': 'REAL',
    'invoice': 'TEXT ${_invoiceCollection.reference}',
  };

  String sku;
  String name;
  String description;
  int amount;
  int quantity;
  String imgS;
  String imgM;
  double ila;
  double discount;
  List<InvoiceProductIncidence> incidence;
  String invoice;

  InvoiceProduct({
    String local,
    String remote,
    this.sku,
    this.name,
    this.description,
    this.amount,
    this.quantity,
    this.imgS,
    this.imgM,
    this.ila,
    this.discount,
    this.incidence,
    this.invoice,
  }) : super(local: local, remote: remote){
    this.incidence.asMap().forEach((index, value) {
      this.incidence[index].invoiceProduct = this.local;
    });
  }

  static Future<InvoiceProduct> fromMap(Map<String, dynamic> obj) async {
    if (obj == null) return null;
    if (obj.length == 0) return null;
    List<InvoiceProductIncidence> incidence =
        await Model.childrenOf<InvoiceProductIncidence>(obj, 'invoice.product', 'incidence');
    return InvoiceProduct(
      local: obj['local'],
      remote: obj['remote'] ?? obj['_id'] ?? obj['local'],
      sku: obj['sku'],
      name: obj['name'],
      description: obj['description'],
      amount: obj['amount'],
      quantity: obj['quantity'],
      imgS: obj['imgS'],
      imgM: obj['imgM'],
      ila: obj['ila'] * 1.0,
      discount: obj['discount'] * 1.0,
      incidence: incidence,
      invoice: obj['invoice'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'local': local,
      'remote': remote,
      'sku': sku,
      'name': name,
      'description': description,
      'amount': amount,
      'quantity': quantity,
      'imgS': imgS,
      'imgM': imgM,
      'ila': ila,
      'discount': discount,
      'incidence': incidence.map((e) => e.toMap()).toList(),
      'invoice': invoice,
    };
  }
}
