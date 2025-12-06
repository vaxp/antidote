import 'package:equatable/equatable.dart';


abstract class SystemSettingsEvent extends Equatable {
  const SystemSettingsEvent();

  @override
  List<Object?> get props => [];
}


class LoadSystemSettings extends SystemSettingsEvent {
  const LoadSystemSettings();
}


class ShowDialog extends SystemSettingsEvent {
  final SystemDialogType dialogType;

  const ShowDialog(this.dialogType);

  @override
  List<Object?> get props => [dialogType];
}


enum SystemDialogType {
  regionLanguage,
  dateTime,
  users,
  remoteDesktop,
  secureShell,
  about,
}
