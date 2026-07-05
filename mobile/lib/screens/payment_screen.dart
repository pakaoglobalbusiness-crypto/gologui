import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
import '../main.dart';
import '../widgets/payment_icon.dart';

/// Paiement in-app (F5) : Wave, Orange Money, Free Money, carte.
/// En dev, l'agrégateur est simulé et confirme automatiquement après ~2 s ;
/// l'écran interroge le statut jusqu'à confirmation (comme un vrai webhook).
class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  const PaymentScreen({super.key, required this.booking});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _method = 'wave';
  String _state = 'idle'; // idle | paying | done | error
  String? _error;
  Timer? _pollTimer;

  static const methods = [
    ('wave', 'Wave', '🌊'),
    ('orange_money', 'Orange Money', '🟠'),
    ('free_money', 'Free Money', '🔴'),
    ('carte', 'Carte bancaire', '💳'),
  ];

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _pay() async {
    setState(() => (_state = 'paying', _error = null));
    try {
      final res = await Api.post('/payments/initiate', body: {
        'bookingId': widget.booking['id'],
        'method': _method,
      });
      final paymentId = res['paymentId'];
      // Agrégateur réel (PayDunya…) : on ouvre sa page de paiement sécurisée ;
      // le polling ci-dessous détecte la confirmation envoyée par le webhook.
      final paymentUrl = res['paymentUrl'] as String?;
      if (paymentUrl != null && !paymentUrl.contains('pay.mock.gologui.sn')) {
        await launchUrl(Uri.parse(paymentUrl), mode: LaunchMode.externalApplication);
      }
      _pollTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
        try {
          final s = await Api.get('/payments/$paymentId/status');
          if (s['status'] == 'confirmed') {
            t.cancel();
            if (mounted) setState(() => _state = 'done');
          } else if (s['status'] == 'failed') {
            t.cancel();
            if (mounted) {
              setState(() => (_state = 'error', _error = 'Paiement refusé'));
            }
          }
        } catch (_) {}
      });
    } on ApiException catch (e) {
      setState(() => (_state = 'error', _error = e.message));
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final total = b['totalPriceFcfa'] as num;

    return Scaffold(
      appBar: AppBar(title: const Text('Paiement')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _state == 'done'
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: gologuiTeal, size: 90),
                    const SizedBox(height: 16),
                    const Text(
                      'Paiement confirmé !',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Votre réservation est confirmée. L’adresse exacte et la '
                      'messagerie avec le propriétaire sont maintenant débloquées.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () =>
                          Navigator.of(context).popUntil((r) => r.isFirst),
                      child: const Text('Voir mes réservations'),
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total à payer',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                          ),
                          Text(
                            fcfa(total),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: gologuiTeal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fonds sécurisés par Gologui, versés au propriétaire '
                            'après le début de la location.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Moyen de paiement',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  for (final (value, label, _) in methods)
                    Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: _method == value
                              ? gologuiTeal
                              : Theme.of(context).colorScheme.outlineVariant,
                          width: _method == value ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        onTap: _state == 'paying'
                            ? null
                            : () => setState(() => _method = value),
                        leading: PaymentIcon(method: value),
                        title: Text(label,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: Icon(
                          _method == value
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: _method == value ? gologuiTeal : null,
                        ),
                      ),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _state == 'paying' ? null : _pay,
                    child: Text(
                      _state == 'paying'
                          ? 'Validation en cours sur votre téléphone…'
                          : 'Payer ${fcfa(total)}',
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
