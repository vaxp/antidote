import 'package:equatable/equatable.dart';
import '../models/input_source.dart';


abstract class KeyboardSettingsEvent extends Equatable {
  const KeyboardSettingsEvent();

  @override
  List<Object?> get props => [];
}


class LoadKeyboardSettings extends KeyboardSettingsEvent {
  const LoadKeyboardSettings();
}


class RefreshKeyboardSettings extends KeyboardSettingsEvent {
  const RefreshKeyboardSettings();
}


class AddInputSource extends KeyboardSettingsEvent {
  final InputSource source;

  const AddInputSource(this.source);

  @override
  List<Object?> get props => [source];
}


class RemoveInputSource extends KeyboardSettingsEvent {
  final InputSource source;

  const RemoveInputSource(this.source);

  @override
  List<Object?> get props => [source];
}


class SetInputSourceSwitching extends KeyboardSettingsEvent {
  final String mode; 

  const SetInputSourceSwitching(this.mode);

  @override
  List<Object?> get props => [mode];
}


class InputSourceAddFailed extends KeyboardSettingsEvent {
  final String message;

  const InputSourceAddFailed(this.message);

  @override
  List<Object?> get props => [message];
}
