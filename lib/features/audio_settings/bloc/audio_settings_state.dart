import 'package:equatable/equatable.dart';
import '../models/audio_device.dart';


enum AudioSettingsStatus { initial, loading, loaded, error }


class AudioSettingsState extends Equatable {
  final AudioSettingsStatus status;

  
  final List<AudioDevice> outputDevices;
  final AudioDevice? selectedOutputDevice;
  final double outputVolume;
  final double balance;
  final bool overamplification;

  
  final List<AudioDevice> inputDevices;
  final AudioDevice? selectedInputDevice;
  final double inputVolume;

  final String? errorMessage;

  const AudioSettingsState({
    this.status = AudioSettingsStatus.initial,
    this.outputDevices = const [],
    this.selectedOutputDevice,
    this.outputVolume = 75.0,
    this.balance = 50.0,
    this.overamplification = false,
    this.inputDevices = const [],
    this.selectedInputDevice,
    this.inputVolume = 75.0,
    this.errorMessage,
  });

  
  AudioSettingsState copyWith({
    AudioSettingsStatus? status,
    List<AudioDevice>? outputDevices,
    AudioDevice? selectedOutputDevice,
    double? outputVolume,
    double? balance,
    bool? overamplification,
    List<AudioDevice>? inputDevices,
    AudioDevice? selectedInputDevice,
    double? inputVolume,
    String? errorMessage,
  }) {
    return AudioSettingsState(
      status: status ?? this.status,
      outputDevices: outputDevices ?? this.outputDevices,
      selectedOutputDevice: selectedOutputDevice ?? this.selectedOutputDevice,
      outputVolume: outputVolume ?? this.outputVolume,
      balance: balance ?? this.balance,
      overamplification: overamplification ?? this.overamplification,
      inputDevices: inputDevices ?? this.inputDevices,
      selectedInputDevice: selectedInputDevice ?? this.selectedInputDevice,
      inputVolume: inputVolume ?? this.inputVolume,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    outputDevices,
    selectedOutputDevice,
    outputVolume,
    balance,
    overamplification,
    inputDevices,
    selectedInputDevice,
    inputVolume,
    errorMessage,
  ];
}
