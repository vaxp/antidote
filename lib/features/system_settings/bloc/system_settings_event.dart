import 'package:equatable/equatable.dart';

/// Base class for all system settings events
abstract class SystemSettingsEvent extends Equatable {
  const SystemSettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load initial settings
class LoadSystemSettings extends SystemSettingsEvent {
  const LoadSystemSettings();
}

/// Event to show a specific dialog
class ShowDialog extends SystemSettingsEvent {
  final SystemDialogType dialogType;

  const ShowDialog(this.dialogType);

  @override
  List<Object?> get props => [dialogType];
}

/// Types of dialogs in system settings
enum SystemDialogType {
  regionLanguage,
  dateTime,
  users,
  remoteDesktop,
  secureShell,
  about,
}
