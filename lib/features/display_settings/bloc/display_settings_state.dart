import 'package:equatable/equatable.dart';
import '../models/display_resolution.dart';

/// Status of display settings
enum DisplaySettingsStatus { initial, loading, loaded, error }

/// State class for display settings
class DisplaySettingsState extends Equatable {
  final DisplaySettingsStatus status;

  // Display info
  final String displayServer; // 'X11' or 'Wayland'
  final String orientation;
  final DisplayResolution? currentResolution;
  final DisplayResolution? nativeResolution;
  final List<DisplayResolution> availableResolutions;
  final String refreshRate;
  final List<String> availableRefreshRates;

  // Scale
  final int scale;
  final bool fractionalScaling;

  // Brightness
  final double brightness;
  final double maxBrightness;
  final bool brightnessSupported;
  final String brightnessMethod;

  // Night light
  final bool nightLight;

  final String? errorMessage;

  const DisplaySettingsState({
    this.status = DisplaySettingsStatus.initial,
    this.displayServer = 'Unknown',
    this.orientation = 'Landscape',
    this.currentResolution,
    this.nativeResolution,
    this.availableResolutions = const [],
    this.refreshRate = '60.00 Hz',
    this.availableRefreshRates = const [],
    this.scale = 100,
    this.fractionalScaling = false,
    this.brightness = 100.0,
    this.maxBrightness = 100.0,
    this.brightnessSupported = false,
    this.brightnessMethod = 'none',
    this.nightLight = false,
    this.errorMessage,
  });

  /// Creates a copy of this state with the given fields replaced
  DisplaySettingsState copyWith({
    DisplaySettingsStatus? status,
    String? displayServer,
    String? orientation,
    DisplayResolution? currentResolution,
    DisplayResolution? nativeResolution,
    List<DisplayResolution>? availableResolutions,
    String? refreshRate,
    List<String>? availableRefreshRates,
    int? scale,
    bool? fractionalScaling,
    double? brightness,
    double? maxBrightness,
    bool? brightnessSupported,
    String? brightnessMethod,
    bool? nightLight,
    String? errorMessage,
  }) {
    return DisplaySettingsState(
      status: status ?? this.status,
      displayServer: displayServer ?? this.displayServer,
      orientation: orientation ?? this.orientation,
      currentResolution: currentResolution ?? this.currentResolution,
      nativeResolution: nativeResolution ?? this.nativeResolution,
      availableResolutions: availableResolutions ?? this.availableResolutions,
      refreshRate: refreshRate ?? this.refreshRate,
      availableRefreshRates:
          availableRefreshRates ?? this.availableRefreshRates,
      scale: scale ?? this.scale,
      fractionalScaling: fractionalScaling ?? this.fractionalScaling,
      brightness: brightness ?? this.brightness,
      maxBrightness: maxBrightness ?? this.maxBrightness,
      brightnessSupported: brightnessSupported ?? this.brightnessSupported,
      brightnessMethod: brightnessMethod ?? this.brightnessMethod,
      nightLight: nightLight ?? this.nightLight,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    displayServer,
    orientation,
    currentResolution,
    nativeResolution,
    availableResolutions,
    refreshRate,
    availableRefreshRates,
    scale,
    fractionalScaling,
    brightness,
    maxBrightness,
    brightnessSupported,
    brightnessMethod,
    nightLight,
    errorMessage,
  ];
}
