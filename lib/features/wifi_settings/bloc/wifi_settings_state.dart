import 'package:equatable/equatable.dart';
import 'wifi_settings_event.dart';


enum WiFiSettingsStatus {
  initial,
  loading,
  loaded,
  scanning,
  connecting,
  error,
}


class WiFiSettingsState extends Equatable {
  final WiFiSettingsStatus status;
  final bool wifiEnabled;
  final bool isScanning;
  final List<WiFiNetwork> networks;
  final String? connectingTo;
  final WiFiNetwork? passwordRequiredFor;
  final String? errorMessage;

  const WiFiSettingsState({
    this.status = WiFiSettingsStatus.initial,
    this.wifiEnabled = true,
    this.isScanning = false,
    this.networks = const [],
    this.connectingTo,
    this.passwordRequiredFor,
    this.errorMessage,
  });

  
  WiFiSettingsState copyWith({
    WiFiSettingsStatus? status,
    bool? wifiEnabled,
    bool? isScanning,
    List<WiFiNetwork>? networks,
    String? connectingTo,
    WiFiNetwork? passwordRequiredFor,
    String? errorMessage,
  }) {
    return WiFiSettingsState(
      status: status ?? this.status,
      wifiEnabled: wifiEnabled ?? this.wifiEnabled,
      isScanning: isScanning ?? this.isScanning,
      networks: networks ?? this.networks,
      connectingTo: connectingTo,
      passwordRequiredFor: passwordRequiredFor,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    wifiEnabled,
    isScanning,
    networks,
    connectingTo,
    passwordRequiredFor,
    errorMessage,
  ];
}
