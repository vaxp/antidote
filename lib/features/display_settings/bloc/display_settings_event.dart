import 'package:equatable/equatable.dart';
import '../models/display_resolution.dart';

/// Base class for all display settings events
abstract class DisplaySettingsEvent extends Equatable {
  const DisplaySettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to initialize display settings
class InitializeDisplaySettings extends DisplaySettingsEvent {
  const InitializeDisplaySettings();
}

/// Event to set display orientation
class SetOrientation extends DisplaySettingsEvent {
  final String orientation;

  const SetOrientation(this.orientation);

  @override
  List<Object?> get props => [orientation];
}

/// Event to set resolution
class SetResolution extends DisplaySettingsEvent {
  final DisplayResolution resolution;

  const SetResolution(this.resolution);

  @override
  List<Object?> get props => [resolution];
}

/// Event to set refresh rate
class SetRefreshRate extends DisplaySettingsEvent {
  final String refreshRate;

  const SetRefreshRate(this.refreshRate);

  @override
  List<Object?> get props => [refreshRate];
}

/// Event to set brightness
class SetBrightness extends DisplaySettingsEvent {
  final double brightness;

  const SetBrightness(this.brightness);

  @override
  List<Object?> get props => [brightness];
}

/// Event to set display scale
class SetScale extends DisplaySettingsEvent {
  final int scale;

  const SetScale(this.scale);

  @override
  List<Object?> get props => [scale];
}

/// Event to toggle fractional scaling
class SetFractionalScaling extends DisplaySettingsEvent {
  final bool enabled;

  const SetFractionalScaling(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Event to toggle night light
class SetNightLight extends DisplaySettingsEvent {
  final bool enabled;

  const SetNightLight(this.enabled);

  @override
  List<Object?> get props => [enabled];
}
