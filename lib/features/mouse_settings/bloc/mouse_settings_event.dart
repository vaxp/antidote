import 'package:equatable/equatable.dart';

/// Base class for all mouse settings events
abstract class MouseSettingsEvent extends Equatable {
  const MouseSettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load initial settings
class LoadMouseSettings extends MouseSettingsEvent {
  const LoadMouseSettings();
}

/// Event to refresh settings periodically
class RefreshMouseSettings extends MouseSettingsEvent {
  const RefreshMouseSettings();
}

/// Event to change selected tab
class ChangeTab extends MouseSettingsEvent {
  final int tabIndex;

  const ChangeTab(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

// Mouse Events

/// Event to set primary button
class SetPrimaryButton extends MouseSettingsEvent {
  final String button; // 'left' or 'right'

  const SetPrimaryButton(this.button);

  @override
  List<Object?> get props => [button];
}

/// Event to set mouse pointer speed
class SetMousePointerSpeed extends MouseSettingsEvent {
  final double speed;

  const SetMousePointerSpeed(this.speed);

  @override
  List<Object?> get props => [speed];
}

/// Event to set mouse acceleration
class SetMouseAcceleration extends MouseSettingsEvent {
  final bool enabled;

  const SetMouseAcceleration(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Event to set scroll direction
class SetScrollDirection extends MouseSettingsEvent {
  final String direction; // 'traditional' or 'natural'

  const SetScrollDirection(this.direction);

  @override
  List<Object?> get props => [direction];
}

// Touchpad Events

/// Event to toggle touchpad
class SetTouchpadEnabled extends MouseSettingsEvent {
  final bool enabled;

  const SetTouchpadEnabled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Event to set disable while typing
class SetDisableWhileTyping extends MouseSettingsEvent {
  final bool enabled;

  const SetDisableWhileTyping(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Event to set touchpad pointer speed
class SetTouchpadPointerSpeed extends MouseSettingsEvent {
  final double speed;

  const SetTouchpadPointerSpeed(this.speed);

  @override
  List<Object?> get props => [speed];
}

/// Event to set secondary click method
class SetSecondaryClick extends MouseSettingsEvent {
  final String method; // 'two-finger' or 'corner'

  const SetSecondaryClick(this.method);

  @override
  List<Object?> get props => [method];
}

/// Event to set tap to click
class SetTapToClick extends MouseSettingsEvent {
  final bool enabled;

  const SetTapToClick(this.enabled);

  @override
  List<Object?> get props => [enabled];
}
