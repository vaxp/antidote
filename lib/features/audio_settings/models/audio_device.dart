import 'package:equatable/equatable.dart';

/// Represents an audio device (input or output)
class AudioDevice extends Equatable {
  final String name;
  final String description;
  final bool isInput;
  final bool isDefault;

  const AudioDevice({
    required this.name,
    required this.description,
    required this.isInput,
    this.isDefault = false,
  });

  @override
  String toString() => description;

  @override
  List<Object?> get props => [name, isInput];
}
