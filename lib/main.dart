import 'package:flutter/material.dart';

import 'package:band_names/provider/sync_cron.dart';

import 'package:band_names/modules/g3s/g3s.dart';
import 'package:band_names/provider/db.dart';
import 'package:band_names/services/socket.dart';
import 'package:band_names/models/band.dart';

import 'package:band_names/pages/home.dart';
import 'package:band_names/pages/status.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp() {
    SyncCronProvider();
    final gs3 = G3S.instance;
    gs3.setDatabaseProvider(DBProvider());
    gs3.setIOSocket(SocketService().socket);
    gs3.setSchema<Band>('bands', Band.schema, Band.fromMap);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Material App',
      initialRoute: 'home',
      routes: {
        'home': (_) => HomePage(),
        'status': (_) => StatusPage(),
      },
    );
  }
}
