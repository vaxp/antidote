import 'package:equatable/equatable.dart';

/// Base class for all bluetooth settings events
abstract class BluetoothSettingsEvent extends Equatable {
  const BluetoothSettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to initialize bluetooth settings
class InitializeBluetooth extends BluetoothSettingsEvent {
  const InitializeBluetooth();
}

/// Event to toggle bluetooth on/off
class ToggleBluetooth extends BluetoothSettingsEvent {
  final bool enabled;

  const ToggleBluetooth(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Event to start device scanning
class StartBluetoothScan extends BluetoothSettingsEvent {
  const StartBluetoothScan();
}

/// Event to stop device scanning
class StopBluetoothScan extends BluetoothSettingsEvent {
  const StopBluetoothScan();
}

/// Event to refresh discovered devices
class RefreshDevices extends BluetoothSettingsEvent {
  const RefreshDevices();
}

/// Event to connect to a device
class ConnectDevice extends BluetoothSettingsEvent {
  final String devicePath;

  const ConnectDevice(this.devicePath);

  @override
  List<Object?> get props => [devicePath];
}

/// Event to disconnect from a device
class DisconnectDevice extends BluetoothSettingsEvent {
  final String devicePath;

  const DisconnectDevice(this.devicePath);

  @override
  List<Object?> get props => [devicePath];
}

/// Event when devices list is updated from DBus signal
class DevicesUpdated extends BluetoothSettingsEvent {
  final List<BluetoothDevice> devices;

  const DevicesUpdated(this.devices);

  @override
  List<Object?> get props => [devices];
}

/// Event when bluetooth adapter status changes
class BluetoothStatusChanged extends BluetoothSettingsEvent {
  final bool enabled;

  const BluetoothStatusChanged(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Represents a bluetooth device
class BluetoothDevice extends Equatable {
  final String path;
  final String name;
  final String address;
  final bool connected;
  final bool paired;
  final int rssi;

  const BluetoothDevice({
    required this.path,
    required this.name,
    required this.address,
    required this.connected,
    required this.paired,
    required this.rssi,
  });

  @override
  List<Object?> get props => [path, name, address, connected, paired, rssi];
}
