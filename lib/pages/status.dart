import 'package:band_names/models/band.dart';
import 'package:band_names/modules/g3s/g3s.dart';
import 'package:flutter/material.dart';

import 'package:band_names/services/socket.dart';

class StatusPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final socketService = SocketService();
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
    final bandCollection = G3S.instance.collection('band');
    // final bandStream = bandCollection.where({'votes': 2}).snapshots();
    // bandStream.listen((bandList) {
    //   print('stream: $bandList');
    // });
    // final bandList = await bandCollection.get();
    // print('future: $bandList');
    // Band band = bandList.isNotEmpty ? bandList[0] : null;
    // print('bandList[0]: ${band.toMap()}');
    Band band = await bandCollection.add({
      'name': 'M2U',
      'votes': 0,
      'city': {
        'name': 'Tokyo',
        'country': 'Japan',
      },
    });
    print('add: ${band.toMap()}');
    band = await bandCollection.doc(band.local).get();
    print('doc().get: ${band.toMap()}');
    band = await bandCollection.doc(band.local).update({
      'votes': band.votes + 1,
      'city': {
        'name': 'Kyoto',
      },
    });
    print('doc().update: ${band.toMap()}');
    band = await bandCollection.doc(band.local).delete();
    print('doc().delete: ${band.toMap()}');
  }
}
