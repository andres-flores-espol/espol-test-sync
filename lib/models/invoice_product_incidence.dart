import 'package:band_names/modules/g3s/g3s.dart';
import 'package:band_names/models/invoice_product.dart';

class InvoiceProductIncidence extends Model {
  static Collection<InvoiceProduct> get _invoiceProductCollection => G3S.instance.collection('invoice.product');
  static final Map<String, String> schema = {
    'local': 'TEXT PRIMARY KEY', // REQUIRED
    'remote': 'TEXT UNIQUE', // REQUIRED
    'diff': 'INTEGER',
    'name': 'TEXT',
    'invoice.product': 'TEXT ${_invoiceProductCollection.reference}',
  };

  int diff;
  String name;
  String invoiceProduct;

  InvoiceProductIncidence({
    String local,
    String remote,
    this.diff,
    this.name,
    this.invoiceProduct,
  }) : super(local: local, remote: remote);

  static InvoiceProductIncidence fromMap(Map<String, dynamic> obj) {
    if (obj == null) return null;
    if (obj.length == 0) return null;
    return InvoiceProductIncidence(
      local: obj['local'],
      remote: obj['remote'] ?? obj['_id'] ?? obj['local'],
      diff: obj['diff'],
      name: obj['name'],
      invoiceProduct: obj['invoice.product'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'local': local,
      'remote': remote,
      'diff': diff,
      'name': name,
      'invoice.product': invoiceProduct,
    };
  }
}
