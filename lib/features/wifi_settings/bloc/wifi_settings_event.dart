import 'package:equatable/equatable.dart';


class WiFiNetwork extends Equatable {
  final String ssid;
  final int strength;
  final bool isSecure;
  final bool isConnected;
  final bool isSaved;

  const WiFiNetwork({
    required this.ssid,
    required this.strength,
    required this.isSecure,
    required this.isConnected,
    required this.isSaved,
  });

  @override
  List<Object?> get props => [ssid, strength, isSecure, isConnected, isSaved];
}


abstract class WiFiSettingsEvent extends Equatable {
  const WiFiSettingsEvent();

  @override
  List<Object?> get props => [];
}


class InitializeWiFi extends WiFiSettingsEvent {
  const InitializeWiFi();
}


class ToggleWiFi extends WiFiSettingsEvent {
  final bool enabled;

  const ToggleWiFi(this.enabled);

  @override
  List<Object?> get props => [enabled];
}


class StartWiFiScan extends WiFiSettingsEvent {
  const StartWiFiScan();
}


class RefreshNetworks extends WiFiSettingsEvent {
  const RefreshNetworks();
}


class ConnectToNetwork extends WiFiSettingsEvent {
  final WiFiNetwork network;
  final String? password;

  const ConnectToNetwork(this.network, {this.password});

  @override
  List<Object?> get props => [network, password];
}


class DisconnectNetwork extends WiFiSettingsEvent {
  const DisconnectNetwork();
}


class ForgetNetwork extends WiFiSettingsEvent {
  final WiFiNetwork network;

  const ForgetNetwork(this.network);

  @override
  List<Object?> get props => [network];
}


class PasswordRequired extends WiFiSettingsEvent {
  final WiFiNetwork network;

  const PasswordRequired(this.network);

  @override
  List<Object?> get props => [network];
}
