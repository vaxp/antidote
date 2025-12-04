import 'package:equatable/equatable.dart';
import 'system_settings_event.dart';

/// Status of system settings
enum SystemSettingsStatus { initial, loading, loaded, error }

/// State class for system settings
class SystemSettingsState extends Equatable {
  final SystemSettingsStatus status;
  final SystemDialogType? activeDialog;
  final String? errorMessage;

  const SystemSettingsState({
    this.status = SystemSettingsStatus.initial,
    this.activeDialog,
    this.errorMessage,
  });

  /// Creates a copy of this state with the given fields replaced
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
