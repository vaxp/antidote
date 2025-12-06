import 'package:equatable/equatable.dart';

abstract class PowerSettingsEvent extends Equatable {
  const PowerSettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadPowerSettings extends PowerSettingsEvent {
  const LoadPowerSettings();
}

class RefreshPowerInfo extends PowerSettingsEvent {
  const RefreshPowerInfo();
}

class SetPowerProfile extends PowerSettingsEvent {
  final String profile;

  const SetPowerProfile(this.profile);

  @override
  List<Object?> get props => [profile];
}

class PerformPowerAction extends PowerSettingsEvent {
  final String action; // shutdown, reboot, suspend, logout, lock

  const PerformPowerAction(this.action);

  @override
  List<Object?> get props => [action];
}

class SetIdleTimeouts extends PowerSettingsEvent {
  final int dim;
  final int blank;
  final int suspend;

  const SetIdleTimeouts({
    required this.dim,
    required this.blank,
    required this.suspend,
  });

  @override
  List<Object?> get props => [dim, blank, suspend];
}

class RefreshIdleTimeouts extends PowerSettingsEvent {
  const RefreshIdleTimeouts();
}

class ProfileChangedExternally extends PowerSettingsEvent {
  final String profile;

  const ProfileChangedExternally(this.profile);

  @override
  List<Object?> get props => [profile];
}
