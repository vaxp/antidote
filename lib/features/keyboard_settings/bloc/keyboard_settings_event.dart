import 'package:equatable/equatable.dart';
import '../models/input_source.dart';

/// Base class for all keyboard settings events
abstract class KeyboardSettingsEvent extends Equatable {
  const KeyboardSettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load initial keyboard settings
class LoadKeyboardSettings extends KeyboardSettingsEvent {
  const LoadKeyboardSettings();
}

/// Event to refresh keyboard settings periodically
class RefreshKeyboardSettings extends KeyboardSettingsEvent {
  const RefreshKeyboardSettings();
}

/// Event to add a new input source
class AddInputSource extends KeyboardSettingsEvent {
  final InputSource source;

  const AddInputSource(this.source);

  @override
  List<Object?> get props => [source];
}

/// Event to remove an existing input source
class RemoveInputSource extends KeyboardSettingsEvent {
  final InputSource source;

  const RemoveInputSource(this.source);

  @override
  List<Object?> get props => [source];
}

/// Event to change input source switching mode
class SetInputSourceSwitching extends KeyboardSettingsEvent {
  final String mode; // 'all-windows' or 'per-window'

  const SetInputSourceSwitching(this.mode);

  @override
  List<Object?> get props => [mode];
}

/// Event when adding input source fails
class InputSourceAddFailed extends KeyboardSettingsEvent {
  final String message;

  const InputSourceAddFailed(this.message);

  @override
  List<Object?> get props => [message];
}
