import 'package:rxdart/rxdart.dart';

class Document {
  final _behaviorSubject = BehaviorSubject<Map<String, dynamic>>();
  void dispose() => _behaviorSubject?.close();

  Document(Map<String, dynamic> data) {
    set(data);
  }

  void set(Map<String, dynamic> data) {
    _behaviorSubject.sink.add(data);
  }

  Stream<Map<String, dynamic>> snapshots() {
    return _behaviorSubject.stream;
  }

  // Future<Map<String, dynamic>> get() async {
    
  //   await Future.doWhile(() => );
  // }
}
