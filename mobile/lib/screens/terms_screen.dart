import 'package:flutter/material.dart';

import '../api.dart';
import '../main.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// Conditions d'utilisation — présentées juste après la validation OTP.
/// L'utilisateur doit accepter pour accéder à l'application. Le point clé
/// (commission de 10 %) y est mentionné explicitement.
class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _accepting = false;

  Future<void> _accept() async {
    setState(() => _accepting = true);
    try {
      await Api.post('/users/me/accept-terms');
      // Rafraîchit la session locale
      try {
        Api.currentUser = await Api.get('/users/me');
      } on ApiException {
        // non bloquant
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
        setState(() => _accepting = false);
      }
    }
  }

  Future<void> _decline() async {
    await Api.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false, // on ne peut pas contourner l'écran
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Conditions d’utilisation'),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset('assets/icon/icon.png', height: 72),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bienvenue sur Gologui',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Avant de commencer, merci de lire et d’accepter nos '
                    'conditions d’utilisation.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 24),

                  // Encadré commission — mis en évidence
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: gologuiTeal.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: gologuiTeal.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Text('💰', style: TextStyle(fontSize: 26)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                  color: scheme.onSurface, fontSize: 14, height: 1.4),
                              children: const [
                                TextSpan(
                                  text: 'Commission Gologui : 10 %\n',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                                TextSpan(
                                  text:
                                      'Sur chaque location, une commission de 10 % '
                                      'est prélevée sur le montant reversé au '
                                      'propriétaire. Le locataire paie le prix affiché.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _Section(
                    title: '1. Objet',
                    body:
                        'Gologui est une plateforme de mise en relation pour la '
                        'location de logements et de véhicules au Sénégal. Gologui '
                        'facilite la réservation et le paiement sécurisé mais n’est '
                        'pas propriétaire des biens proposés.',
                  ),
                  _Section(
                    title: '2. Commission de 10 %',
                    body:
                        'Pour chaque réservation aboutie, Gologui prélève une '
                        'commission de 10 % sur la somme versée au propriétaire. '
                        'Exemple : pour une location de 100 000 FCFA, le '
                        'propriétaire reçoit 90 000 FCFA et Gologui conserve '
                        '10 000 FCFA au titre du service.',
                  ),
                  _Section(
                    title: '3. Paiements et versements',
                    body:
                        'Les paiements sont sécurisés via nos partenaires (Wave, '
                        'Orange Money, carte bancaire). Les fonds sont reversés au '
                        'propriétaire après le début de la location. Les transferts '
                        'du solde sont traités sous 24 à 48 h.',
                  ),
                  _Section(
                    title: '4. Engagements des utilisateurs',
                    body:
                        'Les annonces doivent être réelles et exactes. Tout échange '
                        'et paiement doit se faire via Gologui : le partage de '
                        'numéros de téléphone pour contourner la plateforme est '
                        'interdit. Une vérification d’identité (KYC) est requise '
                        'pour publier une annonce.',
                  ),
                  _Section(
                    title: '5. Annulations et litiges',
                    body:
                        'Chaque annonce précise sa politique d’annulation. En cas '
                        'de litige, Gologui peut arbitrer et procéder à un '
                        'remboursement partiel ou total selon les éléments fournis.',
                  ),
                  _Section(
                    title: '6. Données personnelles',
                    body:
                        'Vos données sont traitées conformément à la loi sénégalaise '
                        'n° 2008-12 sur la protection des données personnelles. '
                        'Elles servent uniquement au fonctionnement du service.',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'En appuyant sur « J’accepte », vous reconnaissez avoir lu et '
                    'accepté l’ensemble de ces conditions, dont la commission de '
                    '10 % prélevée par Gologui.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _accepting ? null : _decline,
                        child: const Text('Refuser'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _accepting ? null : _accept,
                        child: Text(_accepting ? 'Un instant…' : 'J’accepte'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(height: 1.45)),
        ],
      ),
    );
  }
}
