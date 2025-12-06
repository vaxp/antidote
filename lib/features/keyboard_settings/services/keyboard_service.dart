import 'package:flutter/foundation.dart';
import '../models/input_source.dart';

/// Service class that handles all system calls for keyboard settings
/// This separates the system interaction logic from the BLoC
import 'package:dbus/dbus.dart';
import 'layout_repository.dart';

/// Service class that handles all system calls for keyboard settings
/// This separates the system interaction logic from the BLoC
class KeyboardService {
  final LayoutRepository _layoutRepository = LayoutRepository();
  DBusClient? _client;
  DBusRemoteObject? _object;

  Future<void> _connect() async {
    if (_client != null) return;
    _client = DBusClient.session();
    _object = DBusRemoteObject(
      _client!,
      name: 'org.venom.Input',
      path: DBusObjectPath('/org/venom/Input'),
    );
  }

  Future<void> dispose() async {
    await _client?.close();
    _client = null;
    _object = null;
  }

  /// Get currently configured input sources
  Future<List<InputSource>> getCurrentSources() async {
    try {
      await _connect();
      final response = await _object!.callMethod(
        'org.venom.Input',
        'GetLayouts',
        [],
        replySignature: DBusSignature('s'),
      );

      final activeStr = response.values[0].asString();
      if (activeStr.isEmpty) return [];

      final layoutIds = activeStr.split(',');
      final List<InputSource> sources = [];

      // Fetch all available layouts to look up names
      // TODO: Consider caching this if performance becomes an issue
      final allLayouts = await _layoutRepository.getSystemLayouts();
      final layoutMap = {for (var l in allLayouts) l.id: l.name};

      for (final id in layoutIds) {
        final name = layoutMap[id] ?? id;
        sources.add(InputSource(id: id, name: name, type: 'xkb'));
      }
      return sources;
    } catch (e) {
      debugPrint('Get current sources error: $e');
      return [];
    }
  }

  /// Get all available input sources
  Future<List<InputSource>> getAvailableSources() async {
    try {
      final layouts = await _layoutRepository.getSystemLayouts();
      return layouts
          .map((l) => InputSource(id: l.id, name: l.name, type: 'xkb'))
          .toList();
    } catch (e) {
      debugPrint('Get available sources error: $e');
      return [];
    }
  }

  /// Add an input source
  Future<bool> addInputSource(
    InputSource source,
    List<InputSource> currentSources,
  ) async {
    try {
      if (currentSources.any((s) => s.id == source.id)) {
        return false;
      }

      final newSources = [...currentSources, source];
      final layoutsString = newSources.map((s) => s.id).join(',');

      await _connect();
      await _object!.callMethod('org.venom.Input', 'SetLayouts', [
        DBusString(layoutsString),
      ], replySignature: DBusSignature('b'));

      return true;
    } catch (e) {
      debugPrint('Add input source error: $e');
      return false;
    }
  }

  /// Remove an input source
  Future<bool> removeInputSource(
    InputSource source,
    List<InputSource> currentSources,
  ) async {
    try {
      final newSources = currentSources
          .where((s) => s.id != source.id)
          .toList();
      final layoutsString = newSources.map((s) => s.id).join(',');

      await _connect();
      await _object!.callMethod('org.venom.Input', 'SetLayouts', [
        DBusString(layoutsString),
      ], replySignature: DBusSignature('b'));

      return true;
    } catch (e) {
      debugPrint('Remove input source error: $e');
      return false;
    }
  }
}
