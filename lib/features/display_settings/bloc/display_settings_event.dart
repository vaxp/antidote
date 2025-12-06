import 'package:equatable/equatable.dart';
import '../models/display_resolution.dart';


abstract class DisplaySettingsEvent extends Equatable {
  const DisplaySettingsEvent();

  @override
  List<Object?> get props => [];
}


class InitializeDisplaySettings extends DisplaySettingsEvent {
  const InitializeDisplaySettings();
}


class SetOrientation extends DisplaySettingsEvent {
  final String orientation;

  const SetOrientation(this.orientation);

  @override
  List<Object?> get props => [orientation];
}


class SetResolution extends DisplaySettingsEvent {
  final DisplayResolution resolution;

  const SetResolution(this.resolution);

  @override
  List<Object?> get props => [resolution];
}


class SetRefreshRate extends DisplaySettingsEvent {
  final String refreshRate;

  const SetRefreshRate(this.refreshRate);

  @override
  List<Object?> get props => [refreshRate];
}


class SetBrightness extends DisplaySettingsEvent {
  final double brightness;

  const SetBrightness(this.brightness);

  @override
  List<Object?> get props => [brightness];
}


class SetScale extends DisplaySettingsEvent {
  final int scale;

  const SetScale(this.scale);

  @override
  List<Object?> get props => [scale];
}


class SetFractionalScaling extends DisplaySettingsEvent {
  final bool enabled;

  const SetFractionalScaling(this.enabled);

  @override
  List<Object?> get props => [enabled];
}


class SetNightLight extends DisplaySettingsEvent {
  final bool enabled;

  const SetNightLight(this.enabled);

  @override
  List<Object?> get props => [enabled];
}
