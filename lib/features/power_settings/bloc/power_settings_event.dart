import 'package:equatable/equatable.dart';

/// Base class for all power settings events
abstract class PowerSettingsEvent extends Equatable {
  const PowerSettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load initial power settings
class LoadPowerSettings extends PowerSettingsEvent {
  const LoadPowerSettings();
}

/// Event to refresh power info periodically
class RefreshPowerInfo extends PowerSettingsEvent {
  const RefreshPowerInfo();
}

/// Event to change power profile
class SetPowerProfile extends PowerSettingsEvent {
  final String profile; // 'balanced', 'power-saver', 'performance'

  const SetPowerProfile(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Event to perform a power action
class PerformPowerAction extends PowerSettingsEvent {
  final String action; // 'shutdown', 'reboot', 'suspend', 'logout'

  const PerformPowerAction(this.action);

  @override
  List<Object?> get props => [action];
}
