import 'package:flutter/material.dart';

/// Badge de moyen de paiement aux couleurs de la marque.
/// (Représentations stylisées — remplaçables par les logos officiels.)
class PaymentIcon extends StatelessWidget {
  final String method; // wave | orange_money | free_money | carte
  final double size;
  const PaymentIcon({super.key, required this.method, this.size = 40});

  @override
  Widget build(BuildContext context) {
    switch (method) {
      case 'wave':
        return _Badge(
          size: size,
          color: const Color(0xFF1DC4F3), // bleu Wave
          child: Icon(Icons.waves_rounded, color: Colors.white, size: size * 0.55),
        );
      case 'orange_money':
        return _Badge(
          size: size,
          color: const Color(0xFFFF7900), // orange Orange Money
          radius: size * 0.22,
          child: Text(
            'OM',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.34,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      case 'free_money':
        return _Badge(
          size: size,
          color: const Color(0xFFE4002B), // rouge Free
          radius: size * 0.22,
          child: Text(
            'F',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      case 'bank':
        return _Badge(
          size: size,
          color: const Color(0xFF0B4F47),
          radius: size * 0.22,
          child: Icon(Icons.account_balance_rounded,
              color: Colors.white, size: size * 0.55),
        );
      case 'carte':
      default:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1F71), Color(0xFF2A3FA0)], // bleu carte
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(size * 0.22),
          ),
          child: Icon(Icons.credit_card_rounded,
              color: Colors.white, size: size * 0.55),
        );
    }
  }
}

class _Badge extends StatelessWidget {
  final double size;
  final Color color;
  final Widget child;
  final double? radius;
  const _Badge({
    required this.size,
    required this.color,
    required this.child,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius ?? size / 2),
      ),
      child: child,
    );
  }
}
