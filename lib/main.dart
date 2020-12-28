import 'package:band_names/pages/status.dart';
import 'package:band_names/provider/sync_cron.dart';
import 'package:flutter/material.dart';

import 'package:band_names/pages/home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SyncCronProvider();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
