import 'package:flutter/material.dart';

import '../api.dart';
import '../main.dart';
import '../widgets/payment_icon.dart';

/// Mes revenus / Portefeuille : solde en FCFA, transfert du solde vers
/// Wave / Orange Money / virement bancaire, et historique.
class RevenueScreen extends StatefulWidget {
  const RevenueScreen({super.key});

  @override
  State<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends State<RevenueScreen> {
  Map<String, dynamic>? _balance;
  List<dynamic> _payouts = [];
  List<dynamic> _withdrawals = [];
  Map<String, dynamic>? _me;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final balance = await Api.get('/payments/balance');
      final payouts = await Api.get('/payments/payouts/mine');
      final withdrawals = await Api.get('/payments/withdrawals/mine');
      final me = await Api.get('/users/me');
      if (mounted) {
        setState(() {
          _balance = balance;
          _payouts = payouts;
          _withdrawals = withdrawals;
          _me = me;
        });
      }
    } on ApiException {
      // pull-to-refresh disponible
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openTransfer() async {
    final balance = (_balance?['balanceFcfa'] ?? 0) as num;
    if (balance < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Solde insuffisant pour un transfert (min. 1 000 FCFA).'),
      ));
      return;
    }
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _TransferSheet(balance: balance.toInt(), me: _me ?? {}),
    );
    if (done == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final balance = (_balance?['balanceFcfa'] ?? 0) as num;
    final pending = (_balance?['pendingFcfa'] ?? 0) as num;
    final withdrawn = (_balance?['withdrawnFcfa'] ?? 0) as num;

    return Scaffold(
      appBar: AppBar(title: const Text('Mes revenus')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Carte solde
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [gologuiTeal, Color(0xFF0A6E5E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Solde disponible',
                            style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 6),
                        Text(
                          fcfa(balance),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _MiniStat(label: 'En attente', value: fcfa(pending)),
                            ),
                            Container(width: 1, height: 34, color: Colors.white24),
                            Expanded(
                              child: _MiniStat(label: 'Déjà retiré', value: fcfa(withdrawn)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Bouton transférer le solde
                  FilledButton.icon(
                    onPressed: _openTransfer,
                    icon: const Icon(Icons.send_to_mobile),
                    label: const Text('Transférer le solde'),
                  ),
                  const SizedBox(height: 24),
                  // Historique des retraits
                  if (_withdrawals.isNotEmpty) ...[
                    const Text('Mes transferts',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    for (final w in _withdrawals)
                      Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: gologuiTeal.withValues(alpha: 0.12),
                            child: const Icon(Icons.north_east, color: gologuiTeal),
                          ),
                          title: Text(fcfa(w['amountFcfa']),
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                            '${_methodLabel(w['method'])} · ${w['account']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: _WStatusChip(status: w['status']),
                        ),
                      ),
                    const SizedBox(height: 14),
                  ],
                  // Détail des gains
                  const Text('Détail des gains',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  if (_payouts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Aucun gain pour le moment.\n'
                          'Vos revenus apparaîtront ici après vos premières locations.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.55)),
                        ),
                      ),
                    ),
                  for (final p in _payouts)
                    Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: gologuiTeal.withValues(alpha: 0.12),
                          child: const Icon(Icons.payments_outlined, color: gologuiTeal),
                        ),
                        title: Text(fcfa(p['amountFcfa']),
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          p['booking']?['listing']?['title'] ?? 'Location',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: _PStatusChip(status: p['status']),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    'Commission Gologui : 10 %. Transferts traités sous 24-48 h '
                    'vers Wave, Orange Money ou votre compte bancaire.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

String _methodLabel(String m) => switch (m) {
      'wave' => 'Wave',
      'orange_money' => 'Orange Money',
      'bank' => 'Virement bancaire',
      _ => m,
    };

/// Feuille de transfert : destination + coordonnées + montant.
class _TransferSheet extends StatefulWidget {
  final int balance;
  final Map<String, dynamic> me;
  const _TransferSheet({required this.balance, required this.me});

  @override
  State<_TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends State<_TransferSheet> {
  late String _method;
  late final TextEditingController _accountCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _method = ['wave', 'orange_money', 'bank'].contains(widget.me['payoutMethod'])
        ? widget.me['payoutMethod']
        : 'wave';
    _accountCtrl = TextEditingController(text: widget.me['payoutAccount'] ?? '');
    _nameCtrl =
        TextEditingController(text: widget.me['payoutName'] ?? widget.me['name'] ?? '');
    _amountCtrl = TextEditingController(text: '${widget.balance}');
  }

  bool get _valid {
    final amount = int.tryParse(_amountCtrl.text) ?? 0;
    return _accountCtrl.text.trim().isNotEmpty &&
        _nameCtrl.text.trim().isNotEmpty &&
        amount >= 1000 &&
        amount <= widget.balance;
  }

  Future<void> _submit() async {
    setState(() => _sending = true);
    try {
      await Api.post('/payments/withdrawals', body: {
        'amountFcfa': int.parse(_amountCtrl.text),
        'method': _method,
        'account': _accountCtrl.text.trim(),
        'name': _nameCtrl.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Demande de transfert envoyée ! Traitement sous 24-48 h.'),
      ));
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBank = _method == 'bank';
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Transférer le solde',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Solde disponible : ${fcfa(widget.balance)}',
              style: const TextStyle(color: gologuiTeal, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          // Destinations
          Row(
            children: [
              for (final (v, label) in [
                ('wave', 'Wave'),
                ('orange_money', 'Orange Money'),
                ('bank', 'Banque'),
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _method = v),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _method == v
                              ? gologuiTeal.withValues(alpha: 0.12)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _method == v
                                ? gologuiTeal
                                : Theme.of(context).colorScheme.outlineVariant,
                            width: _method == v ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            PaymentIcon(method: v, size: 32),
                            const SizedBox(height: 4),
                            Text(label,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: isBank ? 'Titulaire du compte' : 'Prénom et nom',
              prefixIcon: const Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _accountCtrl,
            onChanged: (_) => setState(() {}),
            keyboardType: isBank ? TextInputType.text : TextInputType.phone,
            decoration: InputDecoration(
              labelText: isBank ? 'IBAN' : 'Numéro ${_method == 'wave' ? 'Wave' : 'Orange Money'}',
              hintText: isBank ? 'SN08 ...' : '+221 7X XXX XX XX',
              prefixIcon: Icon(isBank ? Icons.account_balance_outlined : Icons.phone_android),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Montant à transférer',
              suffixText: 'FCFA',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: !_valid || _sending ? null : _submit,
            child: Text(_sending ? 'Envoi…' : 'Confirmer le transfert'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _PStatusChip extends StatelessWidget {
  final String status;
  const _PStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      'sent' => ('Versé', const Color(0xFFD9F0E3), gologuiTeal),
      'scheduled' => ('Programmé', const Color(0xFFFFF4CE), const Color(0xFF8A6D00)),
      _ => ('Échoué', const Color(0xFFFBDCDD), const Color(0xFFE31B23)),
    };
    return _Pill(label: label, bg: bg, fg: fg);
  }
}

class _WStatusChip extends StatelessWidget {
  final String status;
  const _WStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      'sent' => ('Envoyé', const Color(0xFFD9F0E3), gologuiTeal),
      'pending' => ('En cours', const Color(0xFFFFF4CE), const Color(0xFF8A6D00)),
      _ => ('Refusé', const Color(0xFFFBDCDD), const Color(0xFFE31B23)),
    };
    return _Pill(label: label, bg: bg, fg: fg);
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Pill({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
