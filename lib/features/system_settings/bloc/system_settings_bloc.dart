import 'package:flutter_bloc/flutter_bloc.dart';
import 'system_settings_event.dart';
import 'system_settings_state.dart';

/// BLoC for managing system settings state
/// Note: This BLoC primarily manages dialog navigation state.
/// Individual dialogs handle their own state internally.
class SystemSettingsBloc
    extends Bloc<SystemSettingsEvent, SystemSettingsState> {
  SystemSettingsBloc() : super(const SystemSettingsState()) {
    on<LoadSystemSettings>(_onLoadSystemSettings);
    on<ShowDialog>(_onShowDialog);
  }

  Future<void> _onLoadSystemSettings(
    LoadSystemSettings event,
    Emitter<SystemSettingsState> emit,
  ) async {
    emit(state.copyWith(status: SystemSettingsStatus.loaded));
  }

  void _onShowDialog(ShowDialog event, Emitter<SystemSettingsState> emit) {
    emit(state.copyWith(activeDialog: event.dialogType));
  }
}
