import 'package:equatable/equatable.dart';


abstract class BluetoothSettingsEvent extends Equatable {
  const BluetoothSettingsEvent();

  @override
  List<Object?> get props => [];
}


class InitializeBluetooth extends BluetoothSettingsEvent {
  const InitializeBluetooth();
}


class ToggleBluetooth extends BluetoothSettingsEvent {
  final bool enabled;

  const ToggleBluetooth(this.enabled);

  @override
  List<Object?> get props => [enabled];
}


class StartBluetoothScan extends BluetoothSettingsEvent {
  const StartBluetoothScan();
}


class StopBluetoothScan extends BluetoothSettingsEvent {
  const StopBluetoothScan();
}


class RefreshDevices extends BluetoothSettingsEvent {
  const RefreshDevices();
}


class ConnectDevice extends BluetoothSettingsEvent {
  final String devicePath;

  const ConnectDevice(this.devicePath);

  @override
  List<Object?> get props => [devicePath];
}


class DisconnectDevice extends BluetoothSettingsEvent {
  final String devicePath;

  const DisconnectDevice(this.devicePath);

  @override
  List<Object?> get props => [devicePath];
}


class DevicesUpdated extends BluetoothSettingsEvent {
  final List<BluetoothDevice> devices;

  const DevicesUpdated(this.devices);

  @override
  List<Object?> get props => [devices];
}


class BluetoothStatusChanged extends BluetoothSettingsEvent {
  final bool enabled;

  const BluetoothStatusChanged(this.enabled);

  @override
  List<Object?> get props => [enabled];
}


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
