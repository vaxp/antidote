import 'package:equatable/equatable.dart';
import '../models/input_source.dart';


enum KeyboardSettingsStatus { initial, loading, loaded, error }


class KeyboardSettingsState extends Equatable {
  final KeyboardSettingsStatus status;
  final List<InputSource> currentSources;
  final List<InputSource> availableSources;
  final String inputSourceSwitching; 
  final String alternateCharactersKey;
  final String composeKey;
  final String? errorMessage;

  const KeyboardSettingsState({
    this.status = KeyboardSettingsStatus.initial,
    this.currentSources = const [],
    this.availableSources = const [],
    this.inputSourceSwitching = 'all-windows',
    this.alternateCharactersKey = 'Layout default',
    this.composeKey = 'Layout default',
    this.errorMessage,
  });

  
  KeyboardSettingsState copyWith({
    KeyboardSettingsStatus? status,
    List<InputSource>? currentSources,
    List<InputSource>? availableSources,
    String? inputSourceSwitching,
    String? alternateCharactersKey,
    String? composeKey,
    String? errorMessage,
  }) {
    return KeyboardSettingsState(
      status: status ?? this.status,
      currentSources: currentSources ?? this.currentSources,
      availableSources: availableSources ?? this.availableSources,
      inputSourceSwitching: inputSourceSwitching ?? this.inputSourceSwitching,
      alternateCharactersKey:
          alternateCharactersKey ?? this.alternateCharactersKey,
      composeKey: composeKey ?? this.composeKey,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    currentSources,
    availableSources,
    inputSourceSwitching,
    alternateCharactersKey,
    composeKey,
    errorMessage,
  ];
}
