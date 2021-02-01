import 'package:band_names/models/client_incidence.dart';
import 'package:flutter/material.dart';

import 'package:band_names/modules/g3s/g3s.dart';
import 'package:band_names/provider/db.dart';
import 'package:band_names/services/socket.dart';

import 'package:band_names/models/term.dart';
import 'package:band_names/models/roadmap.dart';
import 'package:band_names/models/roadmap_expense.dart';
import 'package:band_names/models/roadmap_vehicle.dart';
import 'package:band_names/models/city.dart';
import 'package:band_names/models/client.dart';
import 'package:band_names/models/invoice.dart';
import 'package:band_names/models/invoice_seller.dart';
import 'package:band_names/models/invoice_product.dart';
import 'package:band_names/models/invoice_product_incidence.dart';

import 'package:band_names/pages/home.dart';
import 'package:band_names/pages/status.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp() {
    // SyncCronProvider();
    final g3s = G3S.instance;
    g3s.setDatabaseProvider(DBProvider());
    g3s.setIOSocket(SocketService().socket);
    g3s.initSyncronization();
    // g3s.setSchema<Band>('band', Band.schema, Band.fromMap);
    // g3s.setSchema<BandCity>('band.city', BandCity.schema, BandCity.fromMap);
    g3s.setSchema<Term>(
      'term',
      Term.schema,
      Term.fromMap,
    );
    g3s.setSchema<Roadmap>(
      'roadmap',
      Roadmap.schema,
      Roadmap.fromMap,
    );
    g3s.setSchema<RoadmapVehicle>(
      'roadmap.vehicle',
      RoadmapVehicle.schema,
      RoadmapVehicle.fromMap,
    );
    g3s.setSchema<RoadmapExpense>(
      'roadmap.expense',
      RoadmapExpense.schema,
      RoadmapExpense.fromMap,
    );
    g3s.setSchema<City>(
      'city',
      City.schema,
      City.fromMap,
    );
    g3s.setSchema<Client>(
      'client',
      Client.schema,
      Client.fromMap,
    );
    g3s.setSchema<ClientIncidence>(
      'client.incidences',
      ClientIncidence.schema,
      ClientIncidence.fromMap,
    );
    g3s.setSchema<Invoice>(
      'invoice',
      Invoice.schema,
      Invoice.fromMap,
    );
    g3s.setSchema<InvoiceSeller>(
      'invoice.seller',
      InvoiceSeller.schema,
      InvoiceSeller.fromMap,
    );
    g3s.setSchema<InvoiceProduct>(
      'invoice.product',
      InvoiceProduct.schema,
      InvoiceProduct.fromMap,
    );
    g3s.setSchema<InvoiceProductIncidence>(
      'invoice.product.incidence',
      InvoiceProductIncidence.schema,
      InvoiceProductIncidence.fromMap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Material App',
      initialRoute: 'status',
      routes: {
        'home': (_) => HomePage(),
        'status': (_) => StatusPage(),
      },
    );
  }
}
