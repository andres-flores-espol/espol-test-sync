import 'package:band_names/models/band_city.dart';
import 'package:flutter/material.dart';

import 'package:band_names/modules/g3s/g3s.dart';
import 'package:band_names/provider/db.dart';
import 'package:band_names/services/socket.dart';
import 'package:band_names/models/band.dart';

import 'package:band_names/pages/home.dart';
import 'package:band_names/pages/status.dart';

  void main() {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(MyApp());
  }

class MyApp extends StatelessWidget {
MyApp() {
  // print('----- SyncCronProvider -----');
  // SyncCronProvider();
  print('----- G3S -----');
  final gs3 = G3S.instance;
  print('----- DBProvider -----');
  gs3.setDatabaseProvider(DBProvider());
  print('----- SocketService -----');
  gs3.setIOSocket(SocketService().socket);
  print('----- Band -----');
  gs3.setSchema<Band>('band', Band.schema, Band.fromMap);
  print('----- BandCity -----');
  gs3.setSchema<BandCity>('band.city', BandCity.schema, BandCity.fromMap);
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
