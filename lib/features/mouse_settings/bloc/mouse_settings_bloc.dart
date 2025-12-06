import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'mouse_settings_event.dart';
import 'mouse_settings_state.dart';
import '../services/mouse_service.dart';

/// BLoC for managing mouse settings state
class MouseSettingsBloc extends Bloc<MouseSettingsEvent, MouseSettingsState> {
  final MouseService _mouseService;
  Timer? _refreshTimer;

  MouseSettingsBloc({MouseService? mouseService})
    : _mouseService = mouseService ?? MouseService(),
      super(const MouseSettingsState()) {
    on<LoadMouseSettings>(_onLoadMouseSettings);
    on<RefreshMouseSettings>(_onRefreshMouseSettings);
    on<ChangeTab>(_onChangeTab);
    on<SetPrimaryButton>(_onSetPrimaryButton);
    on<SetMousePointerSpeed>(_onSetMousePointerSpeed);
    on<SetMouseAcceleration>(_onSetMouseAcceleration);
    on<SetScrollDirection>(_onSetScrollDirection);
    on<SetTouchpadEnabled>(_onSetTouchpadEnabled);
    on<SetDisableWhileTyping>(_onSetDisableWhileTyping);
    on<SetTouchpadPointerSpeed>(_onSetTouchpadPointerSpeed);
    on<SetSecondaryClick>(_onSetSecondaryClick);
    on<SetTapToClick>(_onSetTapToClick);
  }

  void startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => add(const RefreshMouseSettings()),
    );
  }

  void stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _onLoadMouseSettings(
    LoadMouseSettings event,
    Emitter<MouseSettingsState> emit,
  ) async {
    emit(state.copyWith(status: MouseSettingsStatus.loading));

    try {
      final results = await Future.wait([
        _mouseService.getPrimaryButton(),
        _mouseService.getMousePointerSpeed(),
        _mouseService.getMouseAcceleration(),
        _mouseService.getScrollDirection(),
        _mouseService.getTouchpadEnabled(),
        _mouseService.getDisableWhileTyping(),
        _mouseService.getTouchpadPointerSpeed(),
        _mouseService.getSecondaryClick(),
        _mouseService.getTapToClick(),
      ]);

      emit(
        state.copyWith(
          status: MouseSettingsStatus.loaded,
          primaryButton: results[0] as String,
          mousePointerSpeed: results[1] as double,
          mouseAcceleration: results[2] as bool,
          scrollDirection: results[3] as String,
          touchpadEnabled: results[4] as bool,
          disableWhileTyping: results[5] as bool,
          touchpadPointerSpeed: results[6] as double,
          secondaryClick: results[7] as String,
          tapToClick: results[8] as bool,
        ),
      );

      startPeriodicRefresh();
    } catch (e) {
      emit(
        state.copyWith(
          status: MouseSettingsStatus.error,
          errorMessage: 'Failed to load settings: $e',
        ),
      );
    }
  }

  Future<void> _onRefreshMouseSettings(
    RefreshMouseSettings event,
    Emitter<MouseSettingsState> emit,
  ) async {
    // Silent refresh, don't change status
    try {
      final results = await Future.wait([
        _mouseService.getPrimaryButton(),
        _mouseService.getMousePointerSpeed(),
        _mouseService.getMouseAcceleration(),
        _mouseService.getScrollDirection(),
        _mouseService.getTouchpadEnabled(),
        _mouseService.getDisableWhileTyping(),
        _mouseService.getTouchpadPointerSpeed(),
        _mouseService.getSecondaryClick(),
        _mouseService.getTapToClick(),
      ]);

      emit(
        state.copyWith(
          primaryButton: results[0] as String,
          mousePointerSpeed: results[1] as double,
          mouseAcceleration: results[2] as bool,
          scrollDirection: results[3] as String,
          touchpadEnabled: results[4] as bool,
          disableWhileTyping: results[5] as bool,
          touchpadPointerSpeed: results[6] as double,
          secondaryClick: results[7] as String,
          tapToClick: results[8] as bool,
        ),
      );
    } catch (_) {}
  }

  void _onChangeTab(ChangeTab event, Emitter<MouseSettingsState> emit) {
    emit(state.copyWith(selectedTab: event.tabIndex));
  }

  Future<void> _onSetPrimaryButton(
    SetPrimaryButton event,
    Emitter<MouseSettingsState> emit,
  ) async {
    emit(state.copyWith(primaryButton: event.button));
    await _mouseService.setPrimaryButton(event.button);
  }

  Future<void> _onSetMousePointerSpeed(
    SetMousePointerSpeed event,
    Emitter<MouseSettingsState> emit,
  ) async {
    emit(state.copyWith(mousePointerSpeed: event.speed));
    await _mouseService.setMousePointerSpeed(event.speed);
  }

  Future<void> _onSetMouseAcceleration(
    SetMouseAcceleration event,
    Emitter<MouseSettingsState> emit,
  ) async {
    emit(state.copyWith(mouseAcceleration: event.enabled));
    await _mouseService.setMouseAcceleration(event.enabled);
  }

  Future<void> _onSetScrollDirection(
    SetScrollDirection event,
    Emitter<MouseSettingsState> emit,
  ) async {
    emit(state.copyWith(scrollDirection: event.direction));
    await _mouseService.setScrollDirection(event.direction);
  }

  Future<void> _onSetTouchpadEnabled(
    SetTouchpadEnabled event,
    Emitter<MouseSettingsState> emit,
  ) async {
    emit(state.copyWith(touchpadEnabled: event.enabled));
    await _mouseService.setTouchpadEnabled(event.enabled);
  }

  Future<void> _onSetDisableWhileTyping(
    SetDisableWhileTyping event,
    Emitter<MouseSettingsState> emit,
  ) async {
    emit(state.copyWith(disableWhileTyping: event.enabled));
    await _mouseService.setDisableWhileTyping(event.enabled);
  }

  Future<void> _onSetTouchpadPointerSpeed(
    SetTouchpadPointerSpeed event,
    Emitter<MouseSettingsState> emit,
  ) async {
    emit(state.copyWith(touchpadPointerSpeed: event.speed));
    await _mouseService.setTouchpadPointerSpeed(event.speed);
  }

  Future<void> _onSetSecondaryClick(
    SetSecondaryClick event,
    Emitter<MouseSettingsState> emit,
  ) async {
    emit(state.copyWith(secondaryClick: event.method));
    await _mouseService.setSecondaryClick(event.method);
  }

  Future<void> _onSetTapToClick(
    SetTapToClick event,
    Emitter<MouseSettingsState> emit,
  ) async {
    emit(state.copyWith(tapToClick: event.enabled));
    await _mouseService.setTapToClick(event.enabled);
  }

  @override
  Future<void> close() {
    stopPeriodicRefresh();
    _mouseService.dispose();
    return super.close();
  }
}
