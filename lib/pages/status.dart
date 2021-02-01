import 'package:band_names/models/invoice.dart';
import 'package:band_names/modules/g3s/src/sync.dart';
import 'package:flutter/material.dart';
import 'package:band_names/services/socket.dart';
import 'package:band_names/modules/g3s/g3s.dart';
import 'package:band_names/models/term.dart';
import 'package:band_names/models/roadmap.dart';
import 'package:band_names/models/city.dart';
import 'package:band_names/models/client.dart';

class StatusPage extends StatelessWidget {
  final socketService = SocketService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<ServerStatus>(
          stream: socketService.serverStatusStream,
          builder: (context, snapshot) {
            return Text('${snapshot.data ?? ServerStatus.Connecting}');
          },
        ),
        actions: [
          FlatButton(
            child: Icon(Icons.sync),
            onPressed: G3S.instance.emit,
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          StreamBuilder<List<Invoice>>(
            stream: G3S.instance.collection('invoice').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
              if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
              return Column(
                children: snapshot.data.map((e) => Text(encoder.convert(e))).toList(),
              );
            },
          ),
          StreamBuilder<List<Sync>>(
            stream: G3S.instance.syncCollection.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
              if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
              return Column(
                children: snapshot.data.map((e) => Text('${e.collection}.${e.method}(${e.document})')).toList(),
              );
            },
          ),
        ]),
      ),
      floatingActionButton: StreamBuilder<List<Sync>>(
        stream: G3S.instance.syncCollection.snapshots(),
        builder: (context, snapshot) {
          return FloatingActionButton(
            child: Icon(Icons.cloud_upload),
            onPressed: _asyncFuture,
          );
        },
      ),
    );
  }

  Future<void> _asyncFuture() async {
    Collection<Term> termCollection = G3S.instance.collection('term');
    Collection<Roadmap> roadmapCollection = G3S.instance.collection('roadmap');
    Collection<City> cityCollection = G3S.instance.collection('city');
    Collection<Client> clientCollection = G3S.instance.collection('client');
    Collection<Invoice> invoiceCollection = G3S.instance.collection('invoice');

    print("OBTENGO LOS TIPOS DE PLAZO");
    var terms = await termCollection.get();

    print("CREO UNA HOJA DE RUTA");
    var roadmap = await roadmapCollection.add({
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

    print("CREO UNA CIUDAD");
    var city = await cityCollection.add({
      'name': 'Collipulli',
      'state': 0,
      'roadmap': roadmap.local,
    });

    print("CREO UN CLIENTE");
    var client = await clientCollection.add({
      'name': 'COMERCIAL MAYOR LIMITADA',
      'rut': '0076102105-2',
      'envelope': 0,
      'city': city.local,
      'address': 'AV. COLON 2856',
      'type': 'A',
      'phone': '41-2138309',
      'lon': '-73.1025',
      'lat': '-36.7376',
      'roadmap': roadmap.local,
      'state': 0,
      'term': terms[1].local,
      'incidences': [],
    });

    print("CREO UNA FACTURA");
    var invoice = await invoiceCollection.add({
      'code': 2968940,
      'nOrder': 5086876,
      'totalAmount': 87898,
      'netValue': 73864,
      'iva': 14034,
      'ila': 0,
      'term': terms[1].local,
      'roadmap': roadmap.local,
      'client': client.local,
      'type': 'Invoice',
      'state': 0,
      'product': [
        {
          'imgS': '',
          'imgM': 'http://190.151.18.4/espol/catalogo/fotos_ipad/M093-6.jpg',
          'ila': 0,
          'discount': 0.21960000000000002,
          'sku': 'M093-60000',
          'name': 'Pasta dental Aquafresh little teeth 1x63gr',
          'description': 'Pasta dental infantil little teeth, protección con fluor para niños entre 2 y 5 años.',
          'amount': 1193,
          'quantity': 24,
          'incidence': []
        }
      ],
      'seller': {
        'name': 'FERNANDO REYES SOTO',
        'rut': '',
        'code': 634,
        'phone': '+56982321860',
        'email': 'FERNANDO.REYES@ESPOL.CL'
      },
    });

    print("ACTUALIZO LA FACTURA");
    await invoiceCollection.doc(invoice.local).update({
      'state': 1,
      'seller': {
        'rut': '19717817-5',
      },
      'product': [
        {
          '$add': {
            'sku': 'AY77-10000',
            'name': 'Pasta dental Aquafresh Advanced 1x125ml',
            'amount': 1101,
            'quantity': 60,
            'imgS': '',
            'imgM': 'http://190.151.18.4/espol/catalogo/fotos_ipad/AY77-1.jpg',
            'ila': 0,
            'discount': 0.22010000000000002,
            'incidence': []
          }
        },
        {
          '$delete': {
            'sku': 'M093-60000',
          }
        },
        {
          '$update': {
            'quantity': 100,
            'incidence': [
              {
                '$add': {
                  'diff': 20,
                  'name': 'Producto no solicitado',
                }
              },
              {
                '$update': {
                  'diff': 100,
                },
                '$where': {
                  'name': 'Producto no solicitado',
                }
              },
              {
                '$delete': {
                  'name': 'Producto no solicitado',
                }
              }
            ]
          },
          '$where': {
            'sku': 'AY77-10000',
          }
        }
      ]
    });

    print("ELIMINAR TODO");
    final invoices = await invoiceCollection.get();
    final clients = await clientCollection.get();
    final cities = await cityCollection.get();
    final roadmaps = await roadmapCollection.get();
    await Future.wait(invoices.map((invoice) => invoiceCollection.doc(invoice.local).delete()));
    await Future.wait(clients.map((client) => clientCollection.doc(client.local).delete()));
    await Future.wait(cities.map((city) => cityCollection.doc(city.local).delete()));
    await Future.wait(roadmaps.map((roadmap) => roadmapCollection.doc(roadmap.local).delete()));
//     final bandCollection = G3S.instance.collection('band');
//     // final bandStream = bandCollection.where({'votes': 2}).snapshots();
//     // bandStream.listen((bandList) {
//     // });
//     // final bandList = await bandCollection.get();
//     // Band band = bandList.isNotEmpty ? bandList[0] : null;
//     print('=============create=============');
//     Band band = await bandCollection.add({
//       'name': 'M2U',
//       'votes': 0,
//       'city': {
//         'name': 'Tokyo',
//         'country': 'Japan',
//       },
//     });
//     print(band.toMap());
//     print('=============getall=============');
//     print((await bandCollection.get()).length);
//     print('=============getone=============');
//     band = await bandCollection.doc(band.local).get();
//     print(band.toMap());
//     print('=============delete=============');
//     band = await bandCollection.doc(band.local).delete();
//     print(band.toMap());
//     print('==========================');
//     // print((await bandCollection.get()).length);
//     // print('==========================');
//     // band = await bandCollection.doc(band.local).update({
//     //   'votes': band.votes + 1,
//     //   'city': {
//     //     'name': 'Kyoto',
//     //   },
//     // });

//     // band = await bandCollection.doc(band.local).delete();
  }
}
