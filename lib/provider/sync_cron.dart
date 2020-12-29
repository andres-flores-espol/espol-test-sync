import 'package:band_names/services/socket.dart';
import 'package:band_names/services/sync.dart';
import 'package:cron/cron.dart';

class SyncCronProvider {
  static final SyncCronProvider _instance = SyncCronProvider._internal();
  factory SyncCronProvider() => _instance;
  SyncCronProvider._internal() {
    Cron cron = Cron();
    // Ejecuta cada 1 min
    cron.schedule(Schedule.parse('* * * * *'), () async {
      // print('Intenta conexión');
      connection();
    });
  }

  final SyncService _syncService = SyncService();

  void connection() async {
    if (_syncService.socketService.serverStatus == ServerStatus.Online) {
      // print('Tengo Internet');
      if (!_syncService.emiting) {
        _syncService.emiting = true;
        _syncService.emit();
      } else if (_syncService.socket.sendBuffer.length == 0) {
        _syncService.emit();
      } else {
        _syncService.socket.emitBuffered();
      }
    } else {
      // print('No tengo internet');
    }
  }
}
