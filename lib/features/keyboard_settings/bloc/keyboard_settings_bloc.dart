import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'keyboard_settings_event.dart';
import 'keyboard_settings_state.dart';
// ignore: unused_import
import '../models/input_source.dart';
import '../services/keyboard_service.dart';

/// BLoC for managing keyboard settings state
class KeyboardSettingsBloc
    extends Bloc<KeyboardSettingsEvent, KeyboardSettingsState> {
  final KeyboardService _keyboardService;
  Timer? _refreshTimer;

  KeyboardSettingsBloc({KeyboardService? keyboardService})
    : _keyboardService = keyboardService ?? KeyboardService(),
      super(const KeyboardSettingsState()) {
    on<LoadKeyboardSettings>(_onLoadKeyboardSettings);
    on<RefreshKeyboardSettings>(_onRefreshKeyboardSettings);
    on<AddInputSource>(_onAddInputSource);
    on<RemoveInputSource>(_onRemoveInputSource);
    on<SetInputSourceSwitching>(_onSetInputSourceSwitching);
  }

  /// Starts the periodic refresh timer
  void startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => add(const RefreshKeyboardSettings()),
    );
  }

  /// Stops the periodic refresh timer
  void stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _onLoadKeyboardSettings(
    LoadKeyboardSettings event,
    Emitter<KeyboardSettingsState> emit,
  ) async {
    emit(state.copyWith(status: KeyboardSettingsStatus.loading));

    try {
      final results = await Future.wait([
        _keyboardService.getCurrentSources(),
        _keyboardService.getAvailableSources(),
      ]);

      emit(
        state.copyWith(
          status: KeyboardSettingsStatus.loaded,
          currentSources: results[0],
          availableSources: results[1],
          inputSourceSwitching: 'all-windows', // Default fallback
        ),
      );

      startPeriodicRefresh();
    } catch (e) {
      emit(
        state.copyWith(
          status: KeyboardSettingsStatus.error,
          errorMessage: 'Failed to load keyboard settings: $e',
        ),
      );
    }
  }

  Future<void> _onRefreshKeyboardSettings(
    RefreshKeyboardSettings event,
    Emitter<KeyboardSettingsState> emit,
  ) async {
    try {
      final currentSources = await _keyboardService.getCurrentSources();
      emit(state.copyWith(currentSources: currentSources));
    } catch (e) {
      // Silent refresh failure, don't show error
    }
  }

  Future<void> _onAddInputSource(
    AddInputSource event,
    Emitter<KeyboardSettingsState> emit,
  ) async {
    final success = await _keyboardService.addInputSource(
      event.source,
      state.currentSources,
    );

    if (success) {
      final currentSources = await _keyboardService.getCurrentSources();
      emit(state.copyWith(currentSources: currentSources));
    } else {
      emit(state.copyWith(errorMessage: 'Failed to add input source'));
    }
  }

  Future<void> _onRemoveInputSource(
    RemoveInputSource event,
    Emitter<KeyboardSettingsState> emit,
  ) async {
    final success = await _keyboardService.removeInputSource(
      event.source,
      state.currentSources,
    );

    if (success) {
      final currentSources = await _keyboardService.getCurrentSources();
      emit(state.copyWith(currentSources: currentSources));
    }
  }

  Future<void> _onSetInputSourceSwitching(
    SetInputSourceSwitching event,
    Emitter<KeyboardSettingsState> emit,
  ) async {
    // Feature removed: input source switching per window is not supported by current daemon
    emit(state.copyWith(inputSourceSwitching: event.mode));
  }

  @override
  Future<void> close() {
    stopPeriodicRefresh();
    return super.close();
  }
}
