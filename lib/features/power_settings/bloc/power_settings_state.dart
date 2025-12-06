import 'package:equatable/equatable.dart';


enum PowerSettingsStatus { initial, loading, loaded, error }


class PowerSettingsState extends Equatable {
  final PowerSettingsStatus status;
  final double batteryLevel;
  final bool isCharging;
  final String activePowerProfile;
  final String? errorMessage;

  const PowerSettingsState({
    this.status = PowerSettingsStatus.initial,
    this.batteryLevel = 0.0,
    this.isCharging = false,
    this.activePowerProfile = 'balanced',
    this.errorMessage,
  });

  
  PowerSettingsState copyWith({
    PowerSettingsStatus? status,
    double? batteryLevel,
    bool? isCharging,
    String? activePowerProfile,
    String? errorMessage,
  }) {
    return PowerSettingsState(
      status: status ?? this.status,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isCharging: isCharging ?? this.isCharging,
      activePowerProfile: activePowerProfile ?? this.activePowerProfile,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    batteryLevel,
    isCharging,
    activePowerProfile,
    errorMessage,
  ];
}
