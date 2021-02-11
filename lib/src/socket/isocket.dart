import 'dart:typed_data';


abstract class ISocket {
  String get address;

  int get port;

  void close();

  void listen(void Function(Uint8List) onData);

  void write(String message);
}
