import 'dart:convert';
import 'package:band_names/services/collection.dart';
import 'package:band_names/services/sync.dart';

class BandService extends CollectionService {
  static final BandService _instance = BandService._internal();
  factory BandService() => _instance;

  final _syncService = SyncService();

  BandService._internal() {
    name = 'bands';
    _syncService.services.putIfAbsent(name, () => this);
    find({});
    socket.on('create', (data) {
      // print(data);
    });
  }

  @override
  Future<Map<String, dynamic>> create(Map<String, dynamic> newDocument) async {
    final document = await super.create(newDocument);
    await _syncService.create({
      'collection': 'bands',
      'method': 'create',
      'document': document['_id'],
      'datetime': DateTime.now().millisecondsSinceEpoch,
      'state': 0,
    });
    if (!_syncService.emiting) {
      _syncService.emiting = true;
      _syncService.emit();
    } else {
      socket.emitBuffered();
    }
    return document;
  }

  @override
  Future<void> find(Map<String, dynamic> query) async {
    await super.find(query);
    await _syncService.create({
      'collection': 'bands',
      'method': 'find',
      'document': json.encode(query),
      'datetime': DateTime.now().millisecondsSinceEpoch,
      'state': 0,
    });
    if (!_syncService.emiting) {
      _syncService.emiting = true;
      _syncService.emit();
    } else {
      socket.emitBuffered();
    }
  }

  @override
  Future<Map<String, dynamic>> updateOne(String id, changes) async {
    final document = await super.updateOne(id, changes);
    await _syncService.create({
      'collection': 'bands',
      'method': 'updateOne',
      'document': document['id'],
      'datetime': DateTime.now().millisecondsSinceEpoch,
      'state': 0,
    });
    if (!_syncService.emiting) {
      _syncService.emiting = true;
      _syncService.emit();
    } else {
      socket.emitBuffered();
    }
    return document;
  }

  @override
  Future<Map<String, dynamic>> deleteOne(String id) async {
    final document = await super.deleteOne(id);
    await _syncService.create({
      'collection': 'bands',
      'method': 'deleteOne',
      'document': document['_id'],
      'datetime': DateTime.now().millisecondsSinceEpoch,
      'state': 0,
    });
    if (!_syncService.emiting) {
      _syncService.emiting = true;
      _syncService.emit();
    } else {
      socket.emitBuffered();
    }
    return document;
  }
}
