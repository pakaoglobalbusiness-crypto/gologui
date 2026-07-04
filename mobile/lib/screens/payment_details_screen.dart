import 'package:flutter/material.dart';

import '../api.dart';
import '../main.dart';

/// Coordonnées de paiement (F14) : où recevoir les virements —
/// remboursements pour les locataires, gains pour les propriétaires.
/// Deux options : Wave (mobile money) ou compte bancaire (IBAN).
class PaymentDetailsScreen extends StatefulWidget {
  const PaymentDetailsScreen({super.key});

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  String _method = 'wave'; // wave | bank
  final _accountCtrl = TextEditingController(); // n° Wave ou IBAN
  final _nameCtrl = TextEditingController(); // nom complet / titulaire
  final _addressCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final me = await Api.get('/users/me');
      setState(() {
        _method = (me['payoutMethod'] == 'bank') ? 'bank' : 'wave';
        _accountCtrl.text = me['payoutAccount'] ?? '';
        _nameCtrl.text = me['payoutName'] ?? me['name'] ?? '';
        _addressCtrl.text = me['payoutAddress'] ?? '';
      });
    } on ApiException {
      // valeurs par défaut
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _valid {
    if (_nameCtrl.text.trim().isEmpty || _accountCtrl.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await Api.patch('/users/me', body: {
        'payoutMethod': _method,
        'payoutAccount': _accountCtrl.text.trim(),
        'payoutName': _nameCtrl.text.trim(),
        'payoutAddress': _method == 'wave' ? _addressCtrl.text.trim() : '',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coordonnées de paiement enregistrées ✓')),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Coordonnées de paiement')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Choisissez comment recevoir vos virements '
                  '(remboursements et gains).',
                  style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 16),
                // Choix de la méthode
                Row(
                  children: [
                    Expanded(
                      child: _MethodCard(
                        emoji: '🌊',
                        label: 'Wave',
                        selected: _method == 'wave',
                        onTap: () => setState(() => _method = 'wave'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MethodCard(
                        emoji: '🏦',
                        label: 'Compte bancaire',
                        selected: _method == 'bank',
                        onTap: () => setState(() => _method = 'bank'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_method == 'wave') ...[
                  TextField(
                    controller: _nameCtrl,
                    onChanged: (_) => setState(() {}),
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Prénom et nom',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _accountCtrl,
                    onChanged: (_) => setState(() {}),
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Numéro Wave',
                      hintText: '+221 7X XXX XX XX',
                      prefixIcon: Icon(Icons.phone_android),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _addressCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Adresse',
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                  ),
                ] else ...[
                  TextField(
                    controller: _nameCtrl,
                    onChanged: (_) => setState(() {}),
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Titulaire du compte',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _accountCtrl,
                    onChanged: (_) => setState(() {}),
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'IBAN',
                      hintText: 'SN08 SN01 0152 ...',
                      prefixIcon: Icon(Icons.account_balance_outlined),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: !_valid || _saving ? null : _save,
                  child: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.lock_outline,
                        size: 16, color: scheme.onSurface.withValues(alpha: 0.5)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Vos coordonnées sont confidentielles et servent '
                        'uniquement à vous envoyer votre argent.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: scheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _MethodCard({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: selected ? scheme.primary.withValues(alpha: 0.12) : scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? scheme.primary : scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
