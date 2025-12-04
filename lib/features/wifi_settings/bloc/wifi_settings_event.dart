import 'package:equatable/equatable.dart';

/// Represents a WiFi network
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

/// Base class for all WiFi settings events
abstract class WiFiSettingsEvent extends Equatable {
  const WiFiSettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to initialize WiFi settings
class InitializeWiFi extends WiFiSettingsEvent {
  const InitializeWiFi();
}

/// Event to toggle WiFi on/off
class ToggleWiFi extends WiFiSettingsEvent {
  final bool enabled;

  const ToggleWiFi(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Event to start scanning for networks
class StartWiFiScan extends WiFiSettingsEvent {
  const StartWiFiScan();
}

/// Event to refresh network list
class RefreshNetworks extends WiFiSettingsEvent {
  const RefreshNetworks();
}

/// Event to connect to a network
class ConnectToNetwork extends WiFiSettingsEvent {
  final WiFiNetwork network;
  final String? password;

  const ConnectToNetwork(this.network, {this.password});

  @override
  List<Object?> get props => [network, password];
}

/// Event to disconnect from current network
class DisconnectNetwork extends WiFiSettingsEvent {
  const DisconnectNetwork();
}

/// Event to forget a saved network
class ForgetNetwork extends WiFiSettingsEvent {
  final WiFiNetwork network;

  const ForgetNetwork(this.network);

  @override
  List<Object?> get props => [network];
}

/// Event when password is required for connection
class PasswordRequired extends WiFiSettingsEvent {
  final WiFiNetwork network;

  const PasswordRequired(this.network);

  @override
  List<Object?> get props => [network];
}
