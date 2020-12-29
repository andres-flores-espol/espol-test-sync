import 'package:band_names/models/band.dart';
// import 'package:band_names/services/bands.dart';
import 'package:band_names/modules/g3s/g3s.dart';
import 'package:band_names/services/socket.dart';
// import 'package:band_names/services/sync.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final bandsCollection = G3S.instance.collection('bands');
  final socketService = SocketService();
  // final bandService = BandService();
  // final syncService = SyncService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BandNames', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 10.0),
            child: serverStatus(),
          )
        ],
      ),
      body: _content(context),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        elevation: 1,
        onPressed: () => addNewBand(context),
      ),
    );
  }

  Widget _content(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // StreamBuilder(
          //   stream: syncService.collectionStream,
          //   builder: (BuildContext context, AsyncSnapshot<Map<String, Map<String, dynamic>>> snapshot) {
          //     if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          //     final syncs = snapshot.data.values.toList();
          //     return Column(
          //       children:
          //           syncs.map((s) => Text('${s['collection']}.${s['method']}-${s['document']}-${s['state']}')).toList(),
          //     );
          //   },
          // ),
          StreamBuilder<List<Band>>(
            stream: bandsCollection.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
              final bands = snapshot.data;
              return Column(
                children: bands.map(_bandTile).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget serverStatus() {
    return StreamBuilder(
      stream: socketService.serverStatusStream,
      builder: (BuildContext context, AsyncSnapshot<ServerStatus> snapshot) {
        if (!snapshot.hasData) return Icon(Icons.cloud_off, color: Colors.red[300]);
        if (snapshot.data == ServerStatus.Online) return Icon(Icons.cloud_done, color: Colors.green[300]);
        return Icon(Icons.cloud_off, color: Colors.red[300]);
      },
    );
  }

  Widget _bandTile(Band band) {
    return Dismissible(
      key: Key(band.local),
      direction: DismissDirection.startToEnd,
      onDismissed: (direction) {
        bandsCollection.doc(band.local).delete();
      },
      background: Container(
          padding: EdgeInsets.only(left: 8.0),
          color: Colors.red,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Delete Band', style: TextStyle(color: Colors.white)),
          )),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(band.name.substring(0, 2)),
          backgroundColor: Colors.blue[100],
        ),
        title: Text(band.name),
        trailing: Text('${band.votes}', style: TextStyle(fontSize: 20)),
        onTap: () => _incrementVotes(band),
      ),
    );
  }

  addNewBand(BuildContext context) {
    final textController = new TextEditingController();
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('New band name:'),
          content: TextField(
            controller: textController,
          ),
          actions: <Widget>[
            MaterialButton(
                child: Text('Add'),
                elevation: 5,
                textColor: Colors.blue,
                onPressed: () => addBandToList(context, textController.text))
          ],
        );
      },
    );
  }

  void addBandToList(BuildContext context, String name) {
    if (name.length > 1) {
      bandsCollection.add({
        'name': name,
        'votes': 0,
      });
    }
    Navigator.pop(context);
  }

  void _incrementVotes(Band band) {
    final changes = {
      'votes': band.votes + 1,
    };
    bandsCollection.doc(band.local).update(changes);
  }
}
