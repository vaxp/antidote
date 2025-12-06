import 'package:dbus/dbus.dart';

class DBusService {
  static final DBusService _instance = DBusService._internal();
  late final DBusClient _client;

  factory DBusService() {
    return _instance;
  }

  DBusService._internal() {
    _client = DBusClient.session();
  }

  DBusClient get client => _client;

  Future<void> dispose() async {
    await _client.close();
  }
}
