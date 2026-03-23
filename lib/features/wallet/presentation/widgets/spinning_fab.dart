import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cricketbuzz/core/utils/ad_helper.dart';
import 'dart:math' as math;

class SpinningFAB extends StatefulWidget {
  const SpinningFAB({super.key});

  @override
  State<SpinningFAB> createState() => _SpinningFABState();
}

class _SpinningFABState extends State<SpinningFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10), // Slow continuous spin
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AdHelper.showInterstitialAd(() {
          context.push('/spin-wheel');
        });
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          return Transform.rotate(
            angle: _controller.value * 2 * math.pi,
            child: child,
          );
        },
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xFFD32F2F),
                Color(0xFFB71C1C),
              ], // Cricket Ball Red
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB71C1C).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.white, width: 2), // Seam
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Seam lines decoration
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              const Icon(Icons.sports_cricket, color: Colors.white, size: 32),
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.auto_awesome,
                  color: Colors.amberAccent,
                  size: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
