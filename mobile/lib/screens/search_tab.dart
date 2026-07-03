import 'package:flutter/material.dart';

import '../api.dart';
import '../favorites.dart';
import '../widgets/listing_card.dart';
import 'listing_detail_screen.dart';

/// Accueil / Explorer — design épuré : salutation, type, ville, budget,
/// cartes immersives avec favoris (F2).
class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  String _type = 'villa';
  String? _city;
  int? _maxPrice;
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  static const cities = ['Dakar', 'Saly', 'Mbour', 'Saint-Louis', 'Touba', 'Ziguinchor'];

  @override
  void initState() {
    super.initState();
    Favorites.load().then((_) => mounted ? setState(() {}) : null);
    _search();
  }

  Future<void> _search() async {
    setState(() => (_loading = true, _error = null));
    try {
      final res = await Api.get('/listings', query: {
        'type': _type,
        if (_city != null) 'city': _city!,
        if (_maxPrice != null) 'maxPrice': '$_maxPrice',
      });
      setState(() => _items = res['items']);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    final name = (Api.currentUser?['name'] as String?)?.split(' ').first;
    final salut = h < 18 ? 'Bonjour' : 'Bonsoir';
    return name == null ? '$salut 👋' : '$salut, $name 👋';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _search,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _greeting,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: scheme.onSurface.withValues(alpha: 0.55),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Où allez-vous ?',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset('assets/icon/icon.png', height: 42),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Bascule logement / voiture
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            for (final (value, label) in [
                              ('villa', '🏠  Logements'),
                              ('voiture', '🚗  Voitures'),
                            ])
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (_type != value) {
                                      _type = value;
                                      _search();
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                    decoration: BoxDecoration(
                                      color: _type == value ? scheme.surface : Colors.transparent,
                                      borderRadius: BorderRadius.circular(13),
                                      boxShadow: _type == value
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.08),
                                                blurRadius: 8,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Text(
                                      label,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight:
                                            _type == value ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Filtres : villes puis budget
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'Partout',
                              selected: _city == null,
                              onTap: () {
                                _city = null;
                                _search();
                              },
                            ),
                            for (final c in cities)
                              _FilterChip(
                                label: c,
                                selected: _city == c,
                                onTap: () {
                                  _city = c;
                                  _search();
                                },
                              ),
                            const SizedBox(width: 6),
                            _FilterChip(
                              label: _maxPrice == null
                                  ? '💰 Budget'
                                  : '≤ ${fcfa(_maxPrice!)}',
                              selected: _maxPrice != null,
                              onTap: () async {
                                final v = await showModalBottomSheet<int?>(
                                  context: context,
                                  showDragHandle: true,
                                  builder: (ctx) => SafeArea(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Budget max par jour',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        for (final (v, label) in [
                                          (null, 'Illimité'),
                                          (25000, '25 000 FCFA'),
                                          (50000, '50 000 FCFA'),
                                          (100000, '100 000 FCFA'),
                                        ])
                                          ListTile(
                                            title: Text(label, textAlign: TextAlign.center),
                                            onTap: () => Navigator.pop(ctx, v ?? -1),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                                if (v != null) {
                                  _maxPrice = v == -1 ? null : v;
                                  _search();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SliverFillRemaining(child: Center(child: Text(_error!)))
              else if (_items.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('Aucune annonce trouvée')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  sliver: SliverList.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (_, i) => ListingCard(
                      listing: _items[i],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ListingDetailScreen(listingId: _items[i]['id']),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? scheme.primary : scheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? scheme.onPrimary : scheme.onSurface,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13.5,
            ),
          ),
        ),
      ),
    );
  }
}
