import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:band_names/services/socket.dart';
import 'package:band_names/modules/g3s/g3s.dart';
import 'package:band_names/models/roadmap.dart';

final encoder = JsonEncoder.withIndent('  ');
void pretty(Object object) {
  print(encoder.convert(object));
}

class StatusPage extends StatelessWidget {
  final socketService = SocketService();
  @override
  Widget build(BuildContext context) {
    _asyncFuture();
    return Scaffold(
      body: Center(
        child: StreamBuilder<ServerStatus>(
            stream: socketService.serverStatusStream,
            builder: (context, snapshot) {
              return Text('${snapshot.data ?? ServerStatus.Connecting}');
            }),
      ),
    );
  }

  Future<void> _asyncFuture() async {
    await Future.doWhile(() async {
      await Future.delayed(Duration(milliseconds: 33));
      return !G3S.instance.socket.connected;
    });

    final roadmapCollection = G3S.instance.collection('roadmap');
    Roadmap roadmap = await roadmapCollection.add({
      'code': 83781,
      'weight': 5168,
      'volume': 13,
      'nBox': 144,
      'nPallet': 0,
      'nCreditnote': 0,
      'nDebitnote': 0,
      'nEnvelopes': 0,
      'roadmapDocument': false,
      'manifestPacking': false,
      'zone': 'Supermercados Concepcion',
      'observation': '',
      'state': 0,
      'iduser': '5f5e407733ba5112c475d35b',
      'vehicle': {
        'code': 'F075',
        'patent': '',
        'maxWeight': 0,
        'maxVolume': 0,
      },
      'expense': [],
    });

    final roadmaps = await roadmapCollection.get();
    await Future.wait(roadmaps.map((roadmap) => roadmapCollection.doc(roadmap.local).delete()));
//     final bandCollection = G3S.instance.collection('band');
//     // final bandStream = bandCollection.where({'votes': 2}).snapshots();
//     // bandStream.listen((bandList) {
//     // });
//     // final bandList = await bandCollection.get();
//     // Band band = bandList.isNotEmpty ? bandList[0] : null;
//     print("=============create=============");
//     Band band = await bandCollection.add({
//       'name': 'M2U',
//       'votes': 0,
//       'city': {
//         'name': 'Tokyo',
//         'country': 'Japan',
//       },
//     });
//     print(band.toMap());
//     print("=============getall=============");
//     print((await bandCollection.get()).length);
//     print("=============getone=============");
//     band = await bandCollection.doc(band.local).get();
//     print(band.toMap());
//     print("=============delete=============");
//     band = await bandCollection.doc(band.local).delete();
//     print(band.toMap());
//     print("==========================");
//     // print((await bandCollection.get()).length);
//     // print("==========================");
//     // band = await bandCollection.doc(band.local).update({
//     //   'votes': band.votes + 1,
//     //   'city': {
//     //     'name': 'Kyoto',
//     //   },
//     // });

//     // band = await bandCollection.doc(band.local).delete();
  }
}
