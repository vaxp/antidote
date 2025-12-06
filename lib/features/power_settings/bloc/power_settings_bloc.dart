import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'power_settings_event.dart';
import 'power_settings_state.dart';
import '../services/power_service.dart';

class PowerSettingsBloc extends Bloc<PowerSettingsEvent, PowerSettingsState> {
  final PowerService _powerService;
  StreamSubscription? _batterySubscription;
  StreamSubscription? _timeoutsSubscription;
  StreamSubscription? _profileSubscription;

  PowerSettingsBloc({PowerService? powerService})
    : _powerService = powerService ?? PowerService(),
      super(const PowerSettingsState()) {
    on<LoadPowerSettings>(_onLoadPowerSettings);
    on<RefreshPowerInfo>(_onRefreshPowerInfo);
    on<SetPowerProfile>(_onSetPowerProfile);
    on<ProfileChangedExternally>(_onProfileChangedExternally);
    on<PerformPowerAction>(_onPerformPowerAction);
    on<SetIdleTimeouts>(_onSetIdleTimeouts);
    on<RefreshIdleTimeouts>(_onRefreshIdleTimeouts);
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

    _batterySubscription?.cancel();
    _batterySubscription = _powerService.batteryChangedStream.listen((data) {
      add(const RefreshPowerInfo());
    });

    _timeoutsSubscription?.cancel();
    _timeoutsSubscription = _powerService.idleTimeoutsChangedStream.listen((
      data,
    ) {
      add(const RefreshIdleTimeouts());
    });

    _profileSubscription?.cancel();
    _profileSubscription = _powerService.profileChangedStream.listen((profile) {
      add(ProfileChangedExternally(profile));
    });

    try {
      final batteryInfo = await _powerService.getBatteryInfo();
      final timeouts = await _powerService.getIdleTimeouts();
      final activeProfile = await _powerService.getActiveProfile();

      emit(
        state.copyWith(
          status: PowerSettingsStatus.loaded,
          batteryLevel: batteryInfo['percentage'] as double,
          isCharging: batteryInfo['charging'] as bool,
          activePowerProfile: activeProfile,
          dimTimeout: timeouts['dim'],
          blankTimeout: timeouts['blank'],
          suspendTimeout: timeouts['suspend'],
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

  Future<void> _onRefreshIdleTimeouts(
    RefreshIdleTimeouts event,
    Emitter<PowerSettingsState> emit,
  ) async {
    try {
      final timeouts = await _powerService.getIdleTimeouts();
      emit(
        state.copyWith(
          dimTimeout: timeouts['dim'],
          blankTimeout: timeouts['blank'],
          suspendTimeout: timeouts['suspend'],
        ),
      );
    } catch (_) {}
  }

  Future<void> _onSetPowerProfile(
    SetPowerProfile event,
    Emitter<PowerSettingsState> emit,
  ) async {
    emit(state.copyWith(activePowerProfile: event.profile));
    await _powerService.setActiveProfile(event.profile);
  }

  Future<void> _onProfileChangedExternally(
    ProfileChangedExternally event,
    Emitter<PowerSettingsState> emit,
  ) async {
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

  Future<void> _onSetIdleTimeouts(
    SetIdleTimeouts event,
    Emitter<PowerSettingsState> emit,
  ) async {
    // Optimistic update
    emit(
      state.copyWith(
        dimTimeout: event.dim,
        blankTimeout: event.blank,
        suspendTimeout: event.suspend,
      ),
    );
    await _powerService.setIdleTimeouts(event.dim, event.blank, event.suspend);
  }

  @override
  Future<void> close() {
    _batterySubscription?.cancel();
    _timeoutsSubscription?.cancel();
    _profileSubscription?.cancel();
    _powerService.disconnect();
    return super.close();
  }
}
