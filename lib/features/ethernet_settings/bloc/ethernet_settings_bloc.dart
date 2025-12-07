import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:antidote/core/services/network_service.dart';
import 'ethernet_settings_event.dart';
import 'ethernet_settings_state.dart';

class EthernetSettingsBloc
    extends Bloc<EthernetSettingsEvent, EthernetSettingsState> {
  NetworkService? _networkService;

  EthernetSettingsBloc() : super(const EthernetSettingsState()) {
    on<InitializeEthernet>(_onInitializeEthernet);
    on<RefreshInterfaces>(_onRefreshInterfaces);
    on<EnableInterface>(_onEnableInterface);
    on<DisableInterface>(_onDisableInterface);
  }

  Future<void> _onInitializeEthernet(
    InitializeEthernet event,
    Emitter<EthernetSettingsState> emit,
  ) async {
    emit(state.copyWith(status: EthernetSettingsStatus.loading));

    _networkService = NetworkService();
    final connected = await _networkService!.connect().timeout(
      const Duration(seconds: 3),
      onTimeout: () => false,
    );

    if (!connected) {
      emit(
        state.copyWith(
          status: EthernetSettingsStatus.error,
          errorMessage: 'Failed to connect to Network Daemon',
        ),
      );
      return;
    }

    try {
      final interfaces = await _networkService!.getEthernetInterfaces();
      emit(
        state.copyWith(
          status: EthernetSettingsStatus.loaded,
          interfaces: interfaces,
        ),
      );
    } catch (e) {
      debugPrint('Ethernet init error: $e');
      emit(
        state.copyWith(
          status: EthernetSettingsStatus.error,
          errorMessage: 'Failed to load Ethernet settings: $e',
        ),
      );
    }
  }

  Future<void> _onRefreshInterfaces(
    RefreshInterfaces event,
    Emitter<EthernetSettingsState> emit,
  ) async {
    if (_networkService == null) return;

    final interfaces = await _networkService!.getEthernetInterfaces();
    emit(state.copyWith(interfaces: interfaces));
  }

  Future<void> _onEnableInterface(
    EnableInterface event,
    Emitter<EthernetSettingsState> emit,
  ) async {
    if (_networkService == null) return;

    // Optimistic update - immediately update Switch UI
    final updatedInterfaces = state.interfaces.map((iface) {
      if (iface.name == event.name) {
        return iface.copyWith(enabled: true);
      }
      return iface;
    }).toList();
    emit(state.copyWith(interfaces: updatedInterfaces));

    final success = await _networkService!.enableEthernet(event.name);
    if (success) {
      // Refresh to get actual state from daemon
      add(const RefreshInterfaces());
    } else {
      // Revert on failure
      final revertedInterfaces = state.interfaces.map((iface) {
        if (iface.name == event.name) {
          return iface.copyWith(enabled: false);
        }
        return iface;
      }).toList();
      emit(
        state.copyWith(
          interfaces: revertedInterfaces,
          errorMessage: 'Failed to enable ${event.name}',
        ),
      );
    }
  }

  Future<void> _onDisableInterface(
    DisableInterface event,
    Emitter<EthernetSettingsState> emit,
  ) async {
    if (_networkService == null) return;

    // Optimistic update - immediately update Switch UI
    final updatedInterfaces = state.interfaces.map((iface) {
      if (iface.name == event.name) {
        return iface.copyWith(enabled: false);
      }
      return iface;
    }).toList();
    emit(state.copyWith(interfaces: updatedInterfaces));

    final success = await _networkService!.disableEthernet(event.name);
    if (success) {
      // Refresh to get actual state from daemon
      add(const RefreshInterfaces());
    } else {
      // Revert on failure
      final revertedInterfaces = state.interfaces.map((iface) {
        if (iface.name == event.name) {
          return iface.copyWith(enabled: true);
        }
        return iface;
      }).toList();
      emit(
        state.copyWith(
          interfaces: revertedInterfaces,
          errorMessage: 'Failed to disable ${event.name}',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _networkService?.disconnect();
    return super.close();
  }
}
