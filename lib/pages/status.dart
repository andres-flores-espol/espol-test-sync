import 'package:flutter/material.dart';

import 'package:band_names/services/socket.dart';

class StatusPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final socketService = SocketService();
    return Scaffold(
      body: Center(
        child: Text('${socketService.serverStatus}'),
      ),
    );
  }
}
