import 'package:equatable/equatable.dart';
import '../models/audio_device.dart';

/// Base class for all audio settings events
abstract class AudioSettingsEvent extends Equatable {
  const AudioSettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load initial audio settings
class LoadAudioSettings extends AudioSettingsEvent {
  const LoadAudioSettings();
}

/// Event to refresh audio info periodically
class RefreshAudioInfo extends AudioSettingsEvent {
  const RefreshAudioInfo();
}

/// Event to set output device
class SetOutputDevice extends AudioSettingsEvent {
  final AudioDevice device;

  const SetOutputDevice(this.device);

  @override
  List<Object?> get props => [device];
}

/// Event to set input device
class SetInputDevice extends AudioSettingsEvent {
  final AudioDevice device;

  const SetInputDevice(this.device);

  @override
  List<Object?> get props => [device];
}

/// Event to set output volume
class SetOutputVolume extends AudioSettingsEvent {
  final double volume;

  const SetOutputVolume(this.volume);

  @override
  List<Object?> get props => [volume];
}

/// Event to set input volume
class SetInputVolume extends AudioSettingsEvent {
  final double volume;

  const SetInputVolume(this.volume);

  @override
  List<Object?> get props => [volume];
}

/// Event to set audio balance
class SetBalance extends AudioSettingsEvent {
  final double balance;

  const SetBalance(this.balance);

  @override
  List<Object?> get props => [balance];
}

/// Event to toggle overamplification
class SetOveramplification extends AudioSettingsEvent {
  final bool enabled;

  const SetOveramplification(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Event to test audio output
class TestAudioOutput extends AudioSettingsEvent {
  const TestAudioOutput();
}
