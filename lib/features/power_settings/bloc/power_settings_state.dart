import 'package:equatable/equatable.dart';

enum PowerSettingsStatus { initial, loading, loaded, error }

class PowerSettingsState extends Equatable {
  final PowerSettingsStatus status;
  final double batteryLevel;
  final bool isCharging;
  final String activePowerProfile;
  final int dimTimeout;
  final int blankTimeout;
  final int suspendTimeout;
  final String? errorMessage;

  const PowerSettingsState({
    this.status = PowerSettingsStatus.initial,
    this.batteryLevel = 0.0,
    this.isCharging = false,
    this.activePowerProfile = 'balanced',
    this.dimTimeout = 0,
    this.blankTimeout = 0,
    this.suspendTimeout = 0,
    this.errorMessage,
  });

  PowerSettingsState copyWith({
    PowerSettingsStatus? status,
    double? batteryLevel,
    bool? isCharging,
    String? activePowerProfile,
    int? dimTimeout,
    int? blankTimeout,
    int? suspendTimeout,
    String? errorMessage,
  }) {
    return PowerSettingsState(
      status: status ?? this.status,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isCharging: isCharging ?? this.isCharging,
      activePowerProfile: activePowerProfile ?? this.activePowerProfile,
      dimTimeout: dimTimeout ?? this.dimTimeout,
      blankTimeout: blankTimeout ?? this.blankTimeout,
      suspendTimeout: suspendTimeout ?? this.suspendTimeout,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    batteryLevel,
    isCharging,
    activePowerProfile,
    dimTimeout,
    blankTimeout,
    suspendTimeout,
    errorMessage,
  ];
}
