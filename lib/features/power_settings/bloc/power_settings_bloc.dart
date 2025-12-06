import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'power_settings_event.dart';
import 'power_settings_state.dart';
import '../services/power_service.dart';

/// BLoC for managing power settings state
class PowerSettingsBloc extends Bloc<PowerSettingsEvent, PowerSettingsState> {
  final PowerService _powerService;
  StreamSubscription? _batterySubscription;

  PowerSettingsBloc({PowerService? powerService})
    : _powerService = powerService ?? PowerService(),
      super(const PowerSettingsState()) {
    on<LoadPowerSettings>(_onLoadPowerSettings);
    on<RefreshPowerInfo>(_onRefreshPowerInfo);
    on<SetPowerProfile>(_onSetPowerProfile);
    on<PerformPowerAction>(_onPerformPowerAction);
  }

  Future<void> _onLoadPowerSettings(
    LoadPowerSettings event,
    Emitter<PowerSettingsState> emit,
  ) async {
    emit(state.copyWith(status: PowerSettingsStatus.loading));

    final connected = await _powerService.connect();
    if (!connected) {
      emit(
        state.copyWith(
          status: PowerSettingsStatus.error,
          errorMessage: 'Failed to connect to Power Daemon',
        ),
      );
      return;
    }

    // Subscribe to battery updates
    _batterySubscription?.cancel();
    _batterySubscription = _powerService.batteryChangedStream.listen((data) {
      add(const RefreshPowerInfo());
    });

    try {
      final batteryInfo = await _powerService.getBatteryInfo();

      // Note: Power Profiles are not yet supported by the daemon, defaulting to 'balanced'

      emit(
        state.copyWith(
          status: PowerSettingsStatus.loaded,
          batteryLevel: batteryInfo['percentage'] as double,
          isCharging: batteryInfo['charging'] as bool,
          activePowerProfile: 'balanced',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PowerSettingsStatus.error,
          errorMessage: 'Failed to load power settings: $e',
        ),
      );
    }
  }

  Future<void> _onRefreshPowerInfo(
    RefreshPowerInfo event,
    Emitter<PowerSettingsState> emit,
  ) async {
    try {
      final batteryInfo = await _powerService.getBatteryInfo();
      emit(
        state.copyWith(
          batteryLevel: batteryInfo['percentage'] as double,
          isCharging: batteryInfo['charging'] as bool,
        ),
      );
    } catch (_) {}
  }

  Future<void> _onSetPowerProfile(
    SetPowerProfile event,
    Emitter<PowerSettingsState> emit,
  ) async {
    // Placeholder: Power profiles not implemented in daemon yet
    emit(state.copyWith(activePowerProfile: event.profile));
  }

  Future<void> _onPerformPowerAction(
    PerformPowerAction event,
    Emitter<PowerSettingsState> emit,
  ) async {
    switch (event.action) {
      case 'shutdown':
        await _powerService.shutdown();
        break;
      case 'reboot':
        await _powerService.reboot();
        break;
      case 'suspend':
        await _powerService.suspend();
        break;
      case 'logout':
        await _powerService.logout();
        break;
      case 'lock':
        await _powerService.lockScreen();
        break;
    }
  }

  @override
  Future<void> close() {
    _batterySubscription?.cancel();
    _powerService.disconnect();
    return super.close();
  }
}
