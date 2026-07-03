import 'package:flutter/material.dart';

import '../api.dart';
import '../favorites.dart';
import '../main.dart';

/// Carte d'annonce moderne (photo plein cadre, cœur favori, note).
class ListingCard extends StatefulWidget {
  final Map<String, dynamic> listing;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteChanged;
  const ListingCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.onFavoriteChanged,
  });

  @override
  State<ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends State<ListingCard> {
  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final photos = (l['photos'] as List?) ?? [];
    final rating = ((l['avgRating'] ?? 0) as num).toDouble();
    final isFav = Favorites.contains(l['id']);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                if (photos.isNotEmpty)
                  Image.network(
                    photos.first['url'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: scheme.surfaceContainerHighest,
                      child: const Icon(Icons.photo_outlined, size: 42),
                    ),
                  )
                else
                  Container(
                    height: 200,
                    color: scheme.surfaceContainerHighest,
                    child: const Center(child: Icon(Icons.photo_outlined, size: 42)),
                  ),
                // Cœur favori
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () async {
                        await Favorites.toggle(l['id']);
                        if (mounted) setState(() {});
                        widget.onFavoriteChanged?.call();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? const Color(0xFFFF5A5F) : Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
                // Badge type
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l['type'] == 'villa' ? '🏠 Logement' : '🚗 Voiture',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l['title'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      if (rating > 0) ...[
                        const Icon(Icons.star_rounded, size: 18, color: gologuiOrange),
                        Text(
                          ' $rating',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${l['city']}${l['district'] != null ? ' · ${l['district']}' : ''}',
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.55),
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        fcfa(l['pricePerDayFcfa']),
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        '  / jour',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
