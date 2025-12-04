import 'package:equatable/equatable.dart';

/// Represents a keyboard input source (layout)
class InputSource extends Equatable {
  final String id;
  final String name;
  final String type; // 'xkb' for keyboard layouts

  const InputSource({required this.id, required this.name, required this.type});

  @override
  String toString() => name;

  @override
  List<Object?> get props => [id, type];
}
