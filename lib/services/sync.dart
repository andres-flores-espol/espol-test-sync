import 'dart:convert';

import 'package:band_names/services/collection.dart';
import 'package:flutter/material.dart';

class SyncService extends CollectionService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  final Map<String, dynamic> services = {};
  bool emiting = false;
  String token = 'ABC123';

  SyncService._internal() {
    name = 'syncs';
    find({'state': 0});
    socket.on('connect', (_) {
      if (!emiting) {
        emiting = true;
        emit();
      } else if (socket.sendBuffer.length == 0) {
        emit();
      } else {
        socket.emitBuffered();
      }
    });
  }

  void received(event) {
    socket.emit('sync_events.ready', [token, event['id']]);
  }

  Future<void> emit() async {
    final db = await dbProvider.database;
    var collection = await db.query(
      'syncs',
      where: "state=? AND method!=?",
      whereArgs: [0, 'find'],
      orderBy: 'datetime',
    );
    if (collection.length == 0) {
      collection = await db.query(
        'syncs',
        where: "state=? AND method==?",
        whereArgs: [0, 'find'],
        orderBy: 'datetime',
      );
      if (collection.length == 0) {
        print('sync ready');
        emiting = false;
        return;
      }
    }
    final event = collection[0];
    print(event);
    switch (event['method']) {
      case 'create':
        try {
          await syncCreateBy(event);
        } catch (e) {
          emit();
        }
        break;
      case 'find':
        try {
          await syncFindBy(event);
        } catch (e) {
          emit();
        }
        break;
      case 'updateOne':
        try {
          await syncUpdateOneBy(event);
        } catch (e) {
          emit();
        }
        break;
      case 'deleteOne':
        try {
          await syncDeleteOneBy(event);
        } catch (e) {
          emit();
        }
        break;
      default:
        print('Unknown method.');
    }
  }

  Future<void> syncCreateBy(Map<String, dynamic> event) async {
    final db = await dbProvider.database;
    final collection = await db.query(
      event['collection'],
      where: 'id=?',
      whereArgs: [event['document']],
      limit: 1,
    );
    if (collection.length == 0) {
      await deleteOne(event['id']);
      received(event);
      emit();
      return;
    }
    final document = collection[0];
    final data = {...document};
    data.remove('id');
    data.remove('_id');
    socket.emitWithAck(
      '${event['collection']}.create',
      [data, event, token],
      ack: (Map<String, dynamic> response) async {
        if (response['hasError']) return;
        if (!response['hasData']) return;
        final Map<String, dynamic> newDocument = response['data'];
        final changes = {'_id': newDocument['_id']};
        final db = await dbProvider.database;
        await db.update(
          event['collection'],
          changes,
          where: 'id=?',
          whereArgs: [event['document']],
        );
        services[event['collection']].updateDocument(
          event['document'],
          changes,
        );
        await deleteOne(event['id']);
        received(event);
        emit();
      },
    );
  }

  Future<void> syncFindBy(Map<String, dynamic> event) async {
    final query = json.decode(event['document']);
    socket.emitWithAck(
      '${event['collection']}.find',
      [query, event, token],
      ack: (Map<String, dynamic> response) async {
        if (response['hasError']) return;
        if (!response['hasData']) return;
        final collection = services[event['collection']].collection;
        final db = await dbProvider.database;
        final List<dynamic> documentList = response['data'];
        documentList.forEach((document) {
          Map<String, dynamic> newDocument = Map<String, dynamic>.from(document);
          final condition = (_, doc) => doc['_id'] == newDocument['_id'];
          collection.removeWhere(condition);
          db.delete(event['collection'], where: '_id=?', whereArgs: [newDocument['_id']]);
          final id = UniqueKey().toString().substring(1, 7);
          newDocument.remove('__v');
          newDocument = {'id': id, ...newDocument};
          db.insert(event['collection'], newDocument);
          collection.putIfAbsent(id, () => newDocument);
        });
        services[event['collection']].changeCollection(collection);
        await deleteOne(event['id']);
        received(event);
        emit();
      },
    );
  }

  Future<void> syncUpdateOneBy(Map<String, dynamic> event) async {
    final db = await dbProvider.database;
    final collection = await db.query(
      event['collection'],
      where: 'id=?',
      whereArgs: [event['document']],
      limit: 1,
    );
    if (collection.length == 0) {
      await deleteOne(event['id']);
      received(event);
      emit();
      return;
    }
    final document = collection[0];
    final data = {...document};
    data.remove('id');
    data.remove('_id');
    socket.emitWithAck(
      '${event['collection']}.updateOne',
      [
        {'_id': document['_id']},
        data,
        event,
        token
      ],
      ack: (Map<String, dynamic> response) async {
        await deleteOne(event['id']);
        received(event);
        emit();
      },
    );
  }

  Future<void> syncDeleteOneBy(Map<String, dynamic> event) async {
    socket.emitWithAck(
      '${event['collection']}.deleteOne',
      [
        {'_id': event['document']},
        event,
        token
      ],
      ack: (Map<String, dynamic> response) async {
        await deleteOne(event['id']);
        received(event);
        emit();
      },
    );
  }
}
