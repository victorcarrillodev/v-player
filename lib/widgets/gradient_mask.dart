import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GradientMask extends StatelessWidget {
  final Widget child;
  const GradientMask({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: child,
    );
  }
}
