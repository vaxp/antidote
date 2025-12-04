import 'package:equatable/equatable.dart';
import 'bluetooth_settings_event.dart';

/// Status of bluetooth settings
enum BluetoothSettingsStatus {
  initial,
  initializing,
  ready,
  error,
}

/// State class for bluetooth settings
class BluetoothSettingsState extends Equatable {
  final BluetoothSettingsStatus status;
  final bool bluetoothEnabled;
  final bool isScanning;
  final bool hasAdapter;
  final String? adapterPath;
  final List<BluetoothDevice> devices;
  final String? errorMessage;

  const BluetoothSettingsState({
    this.status = BluetoothSettingsStatus.initial,
    this.bluetoothEnabled = false,
    this.isScanning = false,
    this.hasAdapter = false,
    this.adapterPath,
    this.devices = const [],
    this.errorMessage,
  });

  /// Creates a copy of this state with the given fields replaced
  BluetoothSettingsState copyWith({
    BluetoothSettingsStatus? status,
    bool? bluetoothEnabled,
    bool? isScanning,
    bool? hasAdapter,
    String? adapterPath,
    List<BluetoothDevice>? devices,
    String? errorMessage,
  }) {
    return BluetoothSettingsState(
      status: status ?? this.status,
      bluetoothEnabled: bluetoothEnabled ?? this.bluetoothEnabled,
      isScanning: isScanning ?? this.isScanning,
      hasAdapter: hasAdapter ?? this.hasAdapter,
      adapterPath: adapterPath ?? this.adapterPath,
      devices: devices ?? this.devices,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        bluetoothEnabled,
        isScanning,
        hasAdapter,
        adapterPath,
        devices,
        errorMessage,
      ];
}
