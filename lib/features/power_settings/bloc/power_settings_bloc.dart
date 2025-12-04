import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'power_settings_event.dart';
import 'power_settings_state.dart';
import '../services/power_service.dart';

/// BLoC for managing power settings state
class PowerSettingsBloc extends Bloc<PowerSettingsEvent, PowerSettingsState> {
  final PowerService _powerService;
  Timer? _refreshTimer;

  PowerSettingsBloc({PowerService? powerService})
    : _powerService = powerService ?? PowerService(),
      super(const PowerSettingsState()) {
    on<LoadPowerSettings>(_onLoadPowerSettings);
    on<RefreshPowerInfo>(_onRefreshPowerInfo);
    on<SetPowerProfile>(_onSetPowerProfile);
    on<PerformPowerAction>(_onPerformPowerAction);
  }

  /// Starts the periodic refresh timer
  void startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => add(const RefreshPowerInfo()),
    );
  }

  /// Stops the periodic refresh timer
  void stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _onLoadPowerSettings(
    LoadPowerSettings event,
    Emitter<PowerSettingsState> emit,
  ) async {
    emit(state.copyWith(status: PowerSettingsStatus.loading));

    try {
      final results = await Future.wait([
        _powerService.getBatteryInfo(),
        _powerService.getPowerProfile(),
      ]);

      final batteryInfo = results[0] as Map<String, dynamic>;
      final profile = results[1] as String;

      emit(
        state.copyWith(
          status: PowerSettingsStatus.loaded,
          batteryLevel: batteryInfo['batteryLevel'] as double,
          isCharging: batteryInfo['isCharging'] as bool,
          activePowerProfile: profile,
        ),
      );

      startPeriodicRefresh();
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
      final results = await Future.wait([
        _powerService.getBatteryInfo(),
        _powerService.getPowerProfile(),
      ]);

      final batteryInfo = results[0] as Map<String, dynamic>;
      final profile = results[1] as String;

      emit(
        state.copyWith(
          batteryLevel: batteryInfo['batteryLevel'] as double,
          isCharging: batteryInfo['isCharging'] as bool,
          activePowerProfile: profile,
        ),
      );
    } catch (e) {
      // Silent refresh failure
    }
  }

  Future<void> _onSetPowerProfile(
    SetPowerProfile event,
    Emitter<PowerSettingsState> emit,
  ) async {
    final success = await _powerService.setPowerProfile(event.profile);
    if (success) {
      emit(state.copyWith(activePowerProfile: event.profile));
    }
  }

  Future<void> _onPerformPowerAction(
    PerformPowerAction event,
    Emitter<PowerSettingsState> emit,
  ) async {
    await _powerService.performPowerAction(event.action);
  }

  @override
  Future<void> close() {
    stopPeriodicRefresh();
    _powerService.dispose();
    return super.close();
  }
}
