import 'package:flutter_bloc/flutter_bloc.dart';
import 'display_settings_event.dart';
import 'display_settings_state.dart';
import '../services/display_service.dart';
import '../models/display_resolution.dart';


class DisplaySettingsBloc
    extends Bloc<DisplaySettingsEvent, DisplaySettingsState> {
  final DisplayService _displayService;

  DisplaySettingsBloc({DisplayService? displayService})
    : _displayService = displayService ?? DisplayService(),
      super(const DisplaySettingsState()) {
    on<InitializeDisplaySettings>(_onInitializeDisplaySettings);
    on<SetOrientation>(_onSetOrientation);
    on<SetResolution>(_onSetResolution);
    on<SetRefreshRate>(_onSetRefreshRate);
    on<SetBrightness>(_onSetBrightness);
    on<SetScale>(_onSetScale);
    on<SetFractionalScaling>(_onSetFractionalScaling);
    on<SetNightLight>(_onSetNightLight);
  }

  Future<void> _onInitializeDisplaySettings(
    InitializeDisplaySettings event,
    Emitter<DisplaySettingsState> emit,
  ) async {
    emit(state.copyWith(status: DisplaySettingsStatus.loading));

    try {
      
      final displayServer = await _displayService.detectDisplayServer();
      emit(state.copyWith(displayServer: displayServer));

      
      final displayInfo = await _displayService.getX11DisplayInfo();
      final availableResolutions = await _displayService
          .getX11AvailableResolutions();

      DisplayResolution? currentResolution;
      DisplayResolution? nativeResolution;
      List<String> availableRefreshRates = [];

      if (displayInfo.isNotEmpty) {
        final width = displayInfo['width'] as int;
        final height = displayInfo['height'] as int;
        final aspectRatio = displayInfo['aspectRatio'] as String;

        currentResolution = DisplayResolution(
          width: width,
          height: height,
          aspectRatio: aspectRatio,
        );

        
        if (availableResolutions.isNotEmpty) {
          nativeResolution = availableResolutions.firstWhere(
            (r) => r.isNative,
            orElse: () => availableResolutions.first,
          );
        }

        availableRefreshRates = await _displayService
            .getX11AvailableRefreshRates(width, height);
      }

      
      final brightnessInfo = await _displayService.initBrightness();

      
      final nightLight = await _displayService.getNightLightStatus();

      
      final scale = await _displayService.getScale();

      emit(
        state.copyWith(
          status: DisplaySettingsStatus.loaded,
          orientation: displayInfo['orientation'] as String? ?? 'Landscape',
          currentResolution: currentResolution,
          nativeResolution: nativeResolution,
          availableResolutions: availableResolutions,
          refreshRate: displayInfo['refreshRate'] as String? ?? '60.00 Hz',
          availableRefreshRates: availableRefreshRates,
          scale: scale,
          brightness: brightnessInfo['brightness'] as double,
          maxBrightness: brightnessInfo['maxBrightness'] as double,
          brightnessSupported: brightnessInfo['brightnessSupported'] as bool,
          brightnessMethod: brightnessInfo['brightnessMethod'] as String,
          nightLight: nightLight,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DisplaySettingsStatus.error,
          errorMessage: 'Failed to initialize display settings: $e',
        ),
      );
    }
  }

  Future<void> _onSetOrientation(
    SetOrientation event,
    Emitter<DisplaySettingsState> emit,
  ) async {
    final success = await _displayService.setOrientation(
      event.orientation,
      state.displayServer,
    );
    if (success) {
      emit(state.copyWith(orientation: event.orientation));
    }
  }

  Future<void> _onSetResolution(
    SetResolution event,
    Emitter<DisplaySettingsState> emit,
  ) async {
    final success = await _displayService.setResolution(event.resolution);
    if (success) {
      emit(state.copyWith(currentResolution: event.resolution));

      
      final refreshRates = await _displayService.getX11AvailableRefreshRates(
        event.resolution.width,
        event.resolution.height,
      );
      emit(state.copyWith(availableRefreshRates: refreshRates));
    }
  }

  Future<void> _onSetRefreshRate(
    SetRefreshRate event,
    Emitter<DisplaySettingsState> emit,
  ) async {
    final success = await _displayService.setRefreshRate(event.refreshRate);
    if (success) {
      emit(state.copyWith(refreshRate: event.refreshRate));
    }
  }

  Future<void> _onSetBrightness(
    SetBrightness event,
    Emitter<DisplaySettingsState> emit,
  ) async {
    emit(state.copyWith(brightness: event.brightness));
    await _displayService.setBrightness(
      event.brightness,
      state.brightnessMethod,
      state.maxBrightness,
    );
  }

  Future<void> _onSetScale(
    SetScale event,
    Emitter<DisplaySettingsState> emit,
  ) async {
    final success = await _displayService.setScale(event.scale);
    if (success) {
      emit(state.copyWith(scale: event.scale));
    }
  }

  Future<void> _onSetFractionalScaling(
    SetFractionalScaling event,
    Emitter<DisplaySettingsState> emit,
  ) async {
    final success = await _displayService.setFractionalScaling(event.enabled);
    if (success) {
      emit(state.copyWith(fractionalScaling: event.enabled));
    }
  }

  Future<void> _onSetNightLight(
    SetNightLight event,
    Emitter<DisplaySettingsState> emit,
  ) async {
    final success = await _displayService.setNightLight(event.enabled);
    if (success) {
      emit(state.copyWith(nightLight: event.enabled));
    }
  }

  @override
  Future<void> close() {
    _displayService.dispose();
    return super.close();
  }
}
