import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LaserAnimation extends StatelessWidget {
  final double size;
  
  const LaserAnimation({Key? key, this.size = 260.0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Container(
            width: size,
            height: 2,
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withOpacity(0.8),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: const Color(0xFF00E5FF).withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
          )
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .moveY(begin: 0, end: size, duration: 2.seconds, curve: Curves.easeInOutSine),
        ],
      ),
    );
  }
}
