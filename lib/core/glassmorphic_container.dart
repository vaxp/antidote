import 'dart:ui';
import 'package:flutter/material.dart';

class GlassmorphicContainer extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final LinearGradient linearGradient;
  final double border;
  final double blur;
  final LinearGradient borderGradient;
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry? alignment;

  const GlassmorphicContainer({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 20,
    required this.linearGradient,
    this.border = 0,
    this.blur = 26,
    required this.borderGradient,
    this.child,
    this.padding,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final hasBorderGradient = borderGradient.colors.isNotEmpty;
    
    return Container(
      width: width,
      height: height,
      alignment: alignment,
      decoration: hasBorderGradient
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: borderGradient,
            )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur * 1.5, sigmaY: blur * 1.5),
          child: Container(
            width: width,
            height: height,
            padding: padding,
            alignment: alignment,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              
              border: border > 0
                  ? Border.all(
                      width: border,
                      color: const Color.fromARGB(0, 0, 0, 0),
                    )
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

