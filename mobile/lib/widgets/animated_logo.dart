import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Logo Gologui animé : effectue un petit mouvement (balancement) toutes les
/// 5 secondes, et sert de bouton (ex. réinitialiser la recherche).
class AnimatedLogo extends StatefulWidget {
  final double size;
  final VoidCallback? onTap;
  const AnimatedLogo({super.key, this.size = 42, this.onTap});

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    // Déclenche le balancement toutes les 5 secondes
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _ctrl.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _ctrl.forward(from: 0); // réagit aussi au toucher
        widget.onTap?.call();
      },
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) {
          // Balancement amorti : 2 oscillations qui s'atténuent
          final t = _ctrl.value;
          final angle = 0.3 * math.sin(t * math.pi * 4) * (1 - t);
          return Transform.rotate(angle: angle, child: child);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.size * 0.28),
          child: Image.asset('assets/icon/icon.png', height: widget.size),
        ),
      ),
    );
  }
}
