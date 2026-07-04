import 'package:flutter/material.dart';

/// Badge bleu « compte vérifié » (affiché si kycStatus == 'verified').
/// À placer juste après le nom de l'utilisateur.
class VerifiedBadge extends StatelessWidget {
  final String? kycStatus;
  final double size;
  const VerifiedBadge({super.key, required this.kycStatus, this.size = 18});

  @override
  Widget build(BuildContext context) {
    if (kycStatus != 'verified') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Tooltip(
        message: 'Compte vérifié',
        child: Icon(Icons.verified, color: const Color(0xFF1D9BF0), size: size),
      ),
    );
  }
}
