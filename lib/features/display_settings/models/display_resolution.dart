import 'package:equatable/equatable.dart';


class DisplayResolution extends Equatable {
  final int width;
  final int height;
  final String aspectRatio;
  final bool isNative;

  const DisplayResolution({
    required this.width,
    required this.height,
    required this.aspectRatio,
    this.isNative = false,
  });

  @override
  String toString() {
    var label = '${width}x$height';
    if (aspectRatio.isNotEmpty) {
      label += ' ($aspectRatio)';
    }
    if (isNative) {
      label += ' *';
    }
    return label;
  }

  @override
  List<Object?> get props => [width, height, aspectRatio, isNative];
}
