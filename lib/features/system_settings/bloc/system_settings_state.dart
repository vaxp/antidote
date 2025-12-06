import 'package:equatable/equatable.dart';
import 'system_settings_event.dart';


enum SystemSettingsStatus { initial, loading, loaded, error }


class SystemSettingsState extends Equatable {
  final SystemSettingsStatus status;
  final SystemDialogType? activeDialog;
  final String? errorMessage;

  const SystemSettingsState({
    this.status = SystemSettingsStatus.initial,
    this.activeDialog,
    this.errorMessage,
  });

  
  SystemSettingsState copyWith({
    SystemSettingsStatus? status,
    SystemDialogType? activeDialog,
    bool clearDialog = false,
    String? errorMessage,
  }) {
    return SystemSettingsState(
      status: status ?? this.status,
      activeDialog: clearDialog ? null : (activeDialog ?? this.activeDialog),
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, activeDialog, errorMessage];
}
