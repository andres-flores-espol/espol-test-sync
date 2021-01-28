import 'package:flutter/material.dart';

import 'package:band_names/modules/g3s/g3s.dart';
import 'package:band_names/provider/db.dart';
import 'package:band_names/services/socket.dart';

import 'package:band_names/models/roadmap.dart';
import 'package:band_names/models/roadmap_expense.dart';
import 'package:band_names/models/roadmap_vehicle.dart';

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
    g3s.setSchema<Roadmap>('roadmap', Roadmap.schema, Roadmap.fromMap);
    g3s.setSchema<RoadmapVehicle>('roadmap.vehicle', RoadmapVehicle.schema, RoadmapVehicle.fromMap);
    g3s.setSchema<RoadmapExpense>('roadmap.expense', RoadmapExpense.schema, RoadmapExpense.fromMap);
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
