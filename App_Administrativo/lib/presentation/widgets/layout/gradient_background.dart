import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final double heightFactor;

  const GradientBackground({
    super.key,
    this.heightFactor = 0.8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * heightFactor,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.7, -0.6),
          radius: 1.5,
          colors: [
            Color(0xFFD1FFDA),
            Color(0xFFB7FFEB),
            Color(0xFFCBFFFB),
          ],
        ),
      ),
    );
  }
}