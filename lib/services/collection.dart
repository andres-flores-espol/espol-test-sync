import 'package:band_names/provider/db.dart';
import 'package:band_names/services/socket.dart';
import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';
import 'package:socket_io_client/socket_io_client.dart';

abstract class CollectionService {
  SocketService _socketService = SocketService();
  DBProvider _dbProvider = DBProvider();
  String name = '';

  final _behaviorSubject = BehaviorSubject<Map<String, Map<String, dynamic>>>();
  void dispose() => _behaviorSubject?.close();
  Stream<Map<String, Map<String, dynamic>>> get collectionStream => _behaviorSubject.stream;
  Function(Map<String, Map<String, dynamic>>) get changeCollection => _behaviorSubject.sink.add;
  Map<String, Map<String, dynamic>> get collection => _behaviorSubject.value ?? {};

  SocketService get socketService => _socketService;
  Socket get socket => socketService.socket;
  DBProvider get dbProvider => _dbProvider;

  void createDocument(String id, Map<String, dynamic> document) {
    final collection = this.collection;
    collection.putIfAbsent(id, () => document);
    changeCollection(collection);
  }

  void updateDocument(String id, Map<String, dynamic> changes) {
    final collection = this.collection;
    collection.update(id, (document) {
      changes.forEach((key, value) {
        document.update(key, (_) => value);
      });
      return document;
    });
    changeCollection(collection);
  }

  void deleteDocument(String id) {
    final collection = this.collection;
    collection.remove(id);
    changeCollection(collection);
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> newDocument) async {
    final id = UniqueKey().toString().substring(1, 7);
    final db = await dbProvider.database;
    final document = {
      'id': id,
      '_id': id,
      ...newDocument,
    };
    await db.insert(name, document);
    createDocument(id, document);
    return document;
  }

  Future<void> select(Map<String, dynamic> query) async {
    final collection = this.collection;
    final db = await dbProvider.database;
    final where = query.keys.map((key) => "$key=?").join(' AND ');
    final whereArgs = query.values.map((value) => value).toList();
    final documentList = await db.query(
      name,
      where: where.isNotEmpty ? where : 'TRUE',
      whereArgs: whereArgs,
    );
    documentList.forEach((document) {
      final doc = Map<String, dynamic>.from(document);
      collection.putIfAbsent(document['id'], () => doc);
    });
    changeCollection(collection);
  }

  Future<Map<String, dynamic>> updateOne(String id, changes) async {
    final db = await dbProvider.database;
    final document = collection[id];
    await db.update(name, changes, where: 'id=?', whereArgs: [id]);
    updateDocument(id, changes);
    return document;
  }

  Future<Map<String, dynamic>> deleteOne(String id) async {
    final db = await dbProvider.database;
    final document = collection[id];
    await db.delete(name, where: 'id=?', whereArgs: [id]);
    deleteDocument(id);
    return document;
  }
}
