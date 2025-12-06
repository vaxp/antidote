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
  final String action; 

  const PerformPowerAction(this.action);

  @override
  List<Object?> get props => [action];
}
