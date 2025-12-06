import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bluetooth_settings_event.dart';
import 'bluetooth_settings_state.dart';
import '../services/bluetooth_service.dart';


class BluetoothSettingsBloc
    extends Bloc<BluetoothSettingsEvent, BluetoothSettingsState> {
  final BluetoothService _bluetoothService;
  Timer? _scanTimer;

  BluetoothSettingsBloc({BluetoothService? bluetoothService})
    : _bluetoothService = bluetoothService ?? BluetoothService(),
      super(const BluetoothSettingsState()) {
    on<InitializeBluetooth>(_onInitializeBluetooth);
    on<ToggleBluetooth>(_onToggleBluetooth);
    on<StartBluetoothScan>(_onStartBluetoothScan);
    on<StopBluetoothScan>(_onStopBluetoothScan);
    on<RefreshDevices>(_onRefreshDevices);
    on<ConnectDevice>(_onConnectDevice);
    on<DisconnectDevice>(_onDisconnectDevice);
    on<DevicesUpdated>(_onDevicesUpdated);
    on<BluetoothStatusChanged>(_onBluetoothStatusChanged);

    
    _bluetoothService.onDevicesChanged = (devices) {
      add(DevicesUpdated(devices));
    };
  }

  Future<void> _onInitializeBluetooth(
    InitializeBluetooth event,
    Emitter<BluetoothSettingsState> emit,
  ) async {
    emit(state.copyWith(status: BluetoothSettingsStatus.initializing));

    try {
      final adapterPath = await _bluetoothService.findAdapter();
      final hasAdapter = adapterPath != null;

      bool bluetoothEnabled = false;
      if (hasAdapter) {
        bluetoothEnabled = await _bluetoothService.isBluetoothEnabled();
        _bluetoothService.listenToSignals();
      }

      emit(
        state.copyWith(
          status: BluetoothSettingsStatus.ready,
          hasAdapter: hasAdapter,
          adapterPath: adapterPath,
          bluetoothEnabled: bluetoothEnabled,
        ),
      );

      
      if (bluetoothEnabled && adapterPath != null) {
        add(const StartBluetoothScan());
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: BluetoothSettingsStatus.error,
          errorMessage: 'Failed to initialize bluetooth: $e',
        ),
      );
    }
  }

  Future<void> _onToggleBluetooth(
    ToggleBluetooth event,
    Emitter<BluetoothSettingsState> emit,
  ) async {
    final enabled = await _bluetoothService.toggleBluetooth(event.enabled);
    emit(state.copyWith(bluetoothEnabled: enabled));

    if (enabled && state.adapterPath != null) {
      await Future.delayed(const Duration(milliseconds: 500));
      add(const StartBluetoothScan());
    } else {
      add(const StopBluetoothScan());
      emit(state.copyWith(devices: []));
    }
  }

  Future<void> _onStartBluetoothScan(
    StartBluetoothScan event,
    Emitter<BluetoothSettingsState> emit,
  ) async {
    if (state.adapterPath == null || state.isScanning) return;

    emit(state.copyWith(isScanning: true));

    final success = await _bluetoothService.startScan(state.adapterPath!);
    if (success) {
      
      final devices = await _bluetoothService.fetchDevices();
      emit(state.copyWith(devices: devices));

      
      _scanTimer?.cancel();
      _scanTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => add(const RefreshDevices()),
      );
    } else {
      emit(state.copyWith(isScanning: false));
    }
  }

  Future<void> _onStopBluetoothScan(
    StopBluetoothScan event,
    Emitter<BluetoothSettingsState> emit,
  ) async {
    _scanTimer?.cancel();
    _scanTimer = null;

    if (state.adapterPath != null) {
      await _bluetoothService.stopScan(state.adapterPath!);
    }
    emit(state.copyWith(isScanning: false));
  }

  Future<void> _onRefreshDevices(
    RefreshDevices event,
    Emitter<BluetoothSettingsState> emit,
  ) async {
    final devices = await _bluetoothService.fetchDevices();
    emit(state.copyWith(devices: devices));
  }

  Future<void> _onConnectDevice(
    ConnectDevice event,
    Emitter<BluetoothSettingsState> emit,
  ) async {
    if (state.isScanning) {
      add(const StopBluetoothScan());
      await Future.delayed(const Duration(milliseconds: 200));
    }

    final success = await _bluetoothService.connectDevice(event.devicePath);
    if (!success) {
      emit(state.copyWith(errorMessage: 'Failed to connect device'));
    }

    
    add(const RefreshDevices());
    add(const StartBluetoothScan());
  }

  Future<void> _onDisconnectDevice(
    DisconnectDevice event,
    Emitter<BluetoothSettingsState> emit,
  ) async {
    await _bluetoothService.disconnectDevice(event.devicePath);
    add(const RefreshDevices());
  }

  void _onDevicesUpdated(
    DevicesUpdated event,
    Emitter<BluetoothSettingsState> emit,
  ) {
    emit(state.copyWith(devices: event.devices));
  }

  void _onBluetoothStatusChanged(
    BluetoothStatusChanged event,
    Emitter<BluetoothSettingsState> emit,
  ) {
    emit(state.copyWith(bluetoothEnabled: event.enabled));
  }

  @override
  Future<void> close() {
    _scanTimer?.cancel();
    _bluetoothService.dispose();
    return super.close();
  }
}
