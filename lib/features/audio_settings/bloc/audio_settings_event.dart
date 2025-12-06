import 'package:equatable/equatable.dart';
import '../models/audio_device.dart';


abstract class AudioSettingsEvent extends Equatable {
  const AudioSettingsEvent();

  @override
  List<Object?> get props => [];
}


class LoadAudioSettings extends AudioSettingsEvent {
  const LoadAudioSettings();
}


class RefreshAudioInfo extends AudioSettingsEvent {
  const RefreshAudioInfo();
}


class SetOutputDevice extends AudioSettingsEvent {
  final AudioDevice device;

  const SetOutputDevice(this.device);

  @override
  List<Object?> get props => [device];
}


class SetInputDevice extends AudioSettingsEvent {
  final AudioDevice device;

  const SetInputDevice(this.device);

  @override
  List<Object?> get props => [device];
}


class SetOutputVolume extends AudioSettingsEvent {
  final double volume;

  const SetOutputVolume(this.volume);

  @override
  List<Object?> get props => [volume];
}


class SetInputVolume extends AudioSettingsEvent {
  final double volume;

  const SetInputVolume(this.volume);

  @override
  List<Object?> get props => [volume];
}


class SetBalance extends AudioSettingsEvent {
  final double balance;

  const SetBalance(this.balance);

  @override
  List<Object?> get props => [balance];
}


class SetOveramplification extends AudioSettingsEvent {
  final bool enabled;

  const SetOveramplification(this.enabled);

  @override
  List<Object?> get props => [enabled];
}


class TestAudioOutput extends AudioSettingsEvent {
  const TestAudioOutput();
}
