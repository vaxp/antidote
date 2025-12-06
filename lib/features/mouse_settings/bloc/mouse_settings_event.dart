import 'package:equatable/equatable.dart';


abstract class MouseSettingsEvent extends Equatable {
  const MouseSettingsEvent();

  @override
  List<Object?> get props => [];
}


class LoadMouseSettings extends MouseSettingsEvent {
  const LoadMouseSettings();
}


class RefreshMouseSettings extends MouseSettingsEvent {
  const RefreshMouseSettings();
}


class ChangeTab extends MouseSettingsEvent {
  final int tabIndex;

  const ChangeTab(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}




class SetPrimaryButton extends MouseSettingsEvent {
  final String button; 

  const SetPrimaryButton(this.button);

  @override
  List<Object?> get props => [button];
}


class SetMousePointerSpeed extends MouseSettingsEvent {
  final double speed;

  const SetMousePointerSpeed(this.speed);

  @override
  List<Object?> get props => [speed];
}


class SetMouseAcceleration extends MouseSettingsEvent {
  final bool enabled;

  const SetMouseAcceleration(this.enabled);

  @override
  List<Object?> get props => [enabled];
}


class SetScrollDirection extends MouseSettingsEvent {
  final String direction; 

  const SetScrollDirection(this.direction);

  @override
  List<Object?> get props => [direction];
}




class SetTouchpadEnabled extends MouseSettingsEvent {
  final bool enabled;

  const SetTouchpadEnabled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}


class SetDisableWhileTyping extends MouseSettingsEvent {
  final bool enabled;

  const SetDisableWhileTyping(this.enabled);

  @override
  List<Object?> get props => [enabled];
}


class SetTouchpadPointerSpeed extends MouseSettingsEvent {
  final double speed;

  const SetTouchpadPointerSpeed(this.speed);

  @override
  List<Object?> get props => [speed];
}


class SetSecondaryClick extends MouseSettingsEvent {
  final String method; 

  const SetSecondaryClick(this.method);

  @override
  List<Object?> get props => [method];
}


class SetTapToClick extends MouseSettingsEvent {
  final bool enabled;

  const SetTapToClick(this.enabled);

  @override
  List<Object?> get props => [enabled];
}
