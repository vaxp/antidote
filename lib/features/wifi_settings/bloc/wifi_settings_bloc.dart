import 'package:flutter_bloc/flutter_bloc.dart';
import 'wifi_settings_event.dart';
import 'wifi_settings_state.dart';
import '../services/wifi_service.dart';


class WiFiSettingsBloc extends Bloc<WiFiSettingsEvent, WiFiSettingsState> {
  final WiFiService _wifiService;

  WiFiSettingsBloc({WiFiService? wifiService})
      : _wifiService = wifiService ?? WiFiService(),
        super(const WiFiSettingsState()) {
    on<InitializeWiFi>(_onInitializeWiFi);
    on<ToggleWiFi>(_onToggleWiFi);
    on<StartWiFiScan>(_onStartWiFiScan);
    on<RefreshNetworks>(_onRefreshNetworks);
    on<ConnectToNetwork>(_onConnectToNetwork);
    on<ForgetNetwork>(_onForgetNetwork);
    on<PasswordRequired>(_onPasswordRequired);
  }

  Future<void> _onInitializeWiFi(
    InitializeWiFi event,
    Emitter<WiFiSettingsState> emit,
  ) async {
    emit(state.copyWith(status: WiFiSettingsStatus.loading));

    try {
      final wifiEnabled = await _wifiService.isWiFiEnabled();
      emit(state.copyWith(wifiEnabled: wifiEnabled));

      if (wifiEnabled && await _wifiService.isWiFiAvailable()) {
        await _wifiService.startScan();
        final networks = await _wifiService.fetchNetworks();
        emit(state.copyWith(
          status: WiFiSettingsStatus.loaded,
          networks: networks,
        ));
      } else {
        emit(state.copyWith(status: WiFiSettingsStatus.loaded));
      }
    } catch (e) {
      emit(state.copyWith(
        status: WiFiSettingsStatus.error,
        errorMessage: 'Failed to initialize: $e',
      ));
    }
  }

  Future<void> _onToggleWiFi(
    ToggleWiFi event,
    Emitter<WiFiSettingsState> emit,
  ) async {
    final enabled = await _wifiService.toggleWiFi(event.enabled);
    emit(state.copyWith(wifiEnabled: enabled));

    if (enabled) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (await _wifiService.isWiFiAvailable()) {
        add(const StartWiFiScan());
      }
    } else {
      emit(state.copyWith(networks: []));
    }
  }

  Future<void> _onStartWiFiScan(
    StartWiFiScan event,
    Emitter<WiFiSettingsState> emit,
  ) async {
    if (state.isScanning) return;

    emit(state.copyWith(isScanning: true));
    
    final success = await _wifiService.startScan();
    if (success) {
      final networks = await _wifiService.fetchNetworks();
      emit(state.copyWith(
        isScanning: false,
        networks: networks,
      ));
    } else {
      emit(state.copyWith(
        isScanning: false,
        errorMessage: 'Wi-Fi is not available. Please enable Wi-Fi first.',
      ));
    }
  }

  Future<void> _onRefreshNetworks(
    RefreshNetworks event,
    Emitter<WiFiSettingsState> emit,
  ) async {
    final networks = await _wifiService.fetchNetworks();
    emit(state.copyWith(networks: networks));
  }

  Future<void> _onConnectToNetwork(
    ConnectToNetwork event,
    Emitter<WiFiSettingsState> emit,
  ) async {
    
    if (!event.network.isSaved && event.network.isSecure && event.password == null) {
      emit(state.copyWith(passwordRequiredFor: event.network));
      return;
    }

    emit(state.copyWith(
      status: WiFiSettingsStatus.connecting,
      connectingTo: event.network.ssid,
    ));

    final success = await _wifiService.connectToNetwork(event.network, event.password);
    
    if (success) {
      final networks = await _wifiService.fetchNetworks();
      emit(state.copyWith(
        status: WiFiSettingsStatus.loaded,
        networks: networks,
      ));
    } else {
      emit(state.copyWith(
        status: WiFiSettingsStatus.error,
        errorMessage: 'Failed to connect to ${event.network.ssid}',
      ));
    }
  }

  Future<void> _onForgetNetwork(
    ForgetNetwork event,
    Emitter<WiFiSettingsState> emit,
  ) async {
    final success = await _wifiService.forgetNetwork(event.network);
    
    if (success) {
      final networks = await _wifiService.fetchNetworks();
      emit(state.copyWith(networks: networks));
    } else {
      emit(state.copyWith(
        errorMessage: 'Failed to forget network: ${event.network.ssid}',
      ));
    }
  }

  void _onPasswordRequired(
    PasswordRequired event,
    Emitter<WiFiSettingsState> emit,
  ) {
    emit(state.copyWith(passwordRequiredFor: event.network));
  }

  @override
  Future<void> close() {
    _wifiService.dispose();
    return super.close();
  }
}
