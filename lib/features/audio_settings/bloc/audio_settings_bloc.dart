import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'audio_settings_event.dart';
import 'audio_settings_state.dart';
import '../models/audio_device.dart';
import '../services/audio_service.dart';


class AudioSettingsBloc extends Bloc<AudioSettingsEvent, AudioSettingsState> {
  final AudioService _audioService;
  Timer? _refreshTimer;

  AudioSettingsBloc({AudioService? audioService})
      : _audioService = audioService ?? AudioService(),
        super(const AudioSettingsState()) {
    on<LoadAudioSettings>(_onLoadAudioSettings);
    on<RefreshAudioInfo>(_onRefreshAudioInfo);
    on<SetOutputDevice>(_onSetOutputDevice);
    on<SetInputDevice>(_onSetInputDevice);
    on<SetOutputVolume>(_onSetOutputVolume);
    on<SetInputVolume>(_onSetInputVolume);
    on<SetBalance>(_onSetBalance);
    on<SetOveramplification>(_onSetOveramplification);
    on<TestAudioOutput>(_onTestAudioOutput);
  }

  
  void startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => add(const RefreshAudioInfo()),
    );
  }

  
  void stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _onLoadAudioSettings(
    LoadAudioSettings event,
    Emitter<AudioSettingsState> emit,
  ) async {
    emit(state.copyWith(status: AudioSettingsStatus.loading));

    try {
      final results = await Future.wait([
        _audioService.getOutputDevices(),
        _audioService.getInputDevices(),
        _audioService.getOutputVolume(),
        _audioService.getInputVolume(),
        _audioService.getBalance(),
      ]);

      final outputDevices = results[0] as List<AudioDevice>;
      final inputDevices = results[1] as List<AudioDevice>;
      final outputVolume = results[2] as double;
      final inputVolume = results[3] as double;
      final balance = results[4] as double;

      
      AudioDevice? selectedOutput;
      AudioDevice? selectedInput;
      
      if (outputDevices.isNotEmpty) {
        selectedOutput = outputDevices.firstWhere(
          (d) => d.isDefault,
          orElse: () => outputDevices.first,
        );
      }
      
      if (inputDevices.isNotEmpty) {
        selectedInput = inputDevices.firstWhere(
          (d) => d.isDefault,
          orElse: () => inputDevices.first,
        );
      }

      emit(state.copyWith(
        status: AudioSettingsStatus.loaded,
        outputDevices: outputDevices,
        selectedOutputDevice: selectedOutput,
        outputVolume: outputVolume,
        inputDevices: inputDevices,
        selectedInputDevice: selectedInput,
        inputVolume: inputVolume,
        balance: balance,
      ));

      startPeriodicRefresh();
    } catch (e) {
      emit(state.copyWith(
        status: AudioSettingsStatus.error,
        errorMessage: 'Failed to load audio settings: $e',
      ));
    }
  }

  Future<void> _onRefreshAudioInfo(
    RefreshAudioInfo event,
    Emitter<AudioSettingsState> emit,
  ) async {
    try {
      final results = await Future.wait([
        _audioService.getOutputVolume(),
        _audioService.getInputVolume(),
        _audioService.getBalance(),
      ]);

      emit(state.copyWith(
        
        // ignore: unnecessary_cast
        outputVolume: results[0] as double,
        
        // ignore: unnecessary_cast
        inputVolume: results[1] as double,
        
        // ignore: unnecessary_cast
        balance: results[2] as double,
      ));
    } catch (e) {
      
    }
  }

  Future<void> _onSetOutputDevice(
    SetOutputDevice event,
    Emitter<AudioSettingsState> emit,
  ) async {
    final success = await _audioService.setOutputDevice(event.device);
    if (success) {
      emit(state.copyWith(selectedOutputDevice: event.device));
    }
  }

  Future<void> _onSetInputDevice(
    SetInputDevice event,
    Emitter<AudioSettingsState> emit,
  ) async {
    final success = await _audioService.setInputDevice(event.device);
    if (success) {
      emit(state.copyWith(selectedInputDevice: event.device));
    }
  }

  Future<void> _onSetOutputVolume(
    SetOutputVolume event,
    Emitter<AudioSettingsState> emit,
  ) async {
    
    emit(state.copyWith(outputVolume: event.volume));
    await _audioService.setOutputVolume(event.volume);
  }

  Future<void> _onSetInputVolume(
    SetInputVolume event,
    Emitter<AudioSettingsState> emit,
  ) async {
    emit(state.copyWith(inputVolume: event.volume));
    await _audioService.setInputVolume(event.volume);
  }

  Future<void> _onSetBalance(
    SetBalance event,
    Emitter<AudioSettingsState> emit,
  ) async {
    emit(state.copyWith(balance: event.balance));
    await _audioService.setBalance(event.balance, state.outputVolume);
  }

  Future<void> _onSetOveramplification(
    SetOveramplification event,
    Emitter<AudioSettingsState> emit,
  ) async {
    emit(state.copyWith(overamplification: event.enabled));
  }

  Future<void> _onTestAudioOutput(
    TestAudioOutput event,
    Emitter<AudioSettingsState> emit,
  ) async {
    await _audioService.testOutput();
  }

  @override
  Future<void> close() {
    stopPeriodicRefresh();
    return super.close();
  }
}
