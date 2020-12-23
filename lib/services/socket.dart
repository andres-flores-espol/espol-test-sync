import 'package:band_names/services/sync.dart';
import 'package:rxdart/rxdart.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

enum ServerStatus { Online, Offline, Connecting }

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  final _behaviorSubject = BehaviorSubject<ServerStatus>();
  void dispose() => _behaviorSubject?.close();
  Stream<ServerStatus> get serverStatusStream => _behaviorSubject.stream;
  Function(ServerStatus) get changeServerStatus => _behaviorSubject.sink.add;
  ServerStatus get serverStatus => _behaviorSubject.value;
  
  IO.Socket _socket;
  IO.Socket get socket => this._socket;

  SocketService._internal() {
    changeServerStatus(ServerStatus.Connecting);
    createSocket();
  }

  void createSocket() {
    this._socket = IO.io('http://192.168.2.6:3000', {
      'transports': ['websocket'],
      'autoConnect': true,
    });
    IO.EVENTS.forEach((event) {
      this._socket.on(event, (_) => print('IO.Socket: $event' + (_ != null ? ': $_' : '')));
    });
    this._socket.on('connect', (_) {
      changeServerStatus(ServerStatus.Online);
    });
    this._socket.on('disconnect', (_) {
      changeServerStatus(ServerStatus.Offline);
    });
  }


}
