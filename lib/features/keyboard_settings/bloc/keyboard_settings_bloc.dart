import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'keyboard_settings_event.dart';
import 'keyboard_settings_state.dart';

// ignore: unused_import
import '../models/input_source.dart';
import '../services/keyboard_service.dart';


class KeyboardSettingsBloc
    extends Bloc<KeyboardSettingsEvent, KeyboardSettingsState> {
  final KeyboardService _keyboardService;

  KeyboardSettingsBloc({KeyboardService? keyboardService})
    : _keyboardService = keyboardService ?? KeyboardService(),
      super(const KeyboardSettingsState()) {
    on<LoadKeyboardSettings>(_onLoadKeyboardSettings);
    on<AddInputSource>(_onAddInputSource);
    on<RemoveInputSource>(_onRemoveInputSource);
    on<SetInputSourceSwitching>(_onSetInputSourceSwitching);
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
          inputSourceSwitching: 'all-windows', 
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: KeyboardSettingsStatus.error,
          errorMessage: 'Failed to load keyboard settings: $e',
        ),
      );
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
    
    emit(state.copyWith(inputSourceSwitching: event.mode));
  }
}
