import 'api.dart';

/// État global des favoris (wishlist) : ids chargés une fois,
/// bascule optimiste synchronisée avec l'API.
class Favorites {
  static final Set<String> ids = {};
  static bool _loaded = false;

  static Future<void> load({bool force = false}) async {
    if (_loaded && !force) return;
    try {
      final res = await Api.get('/listings/favorites/ids');
      ids
        ..clear()
        ..addAll((res as List).cast<String>());
      _loaded = true;
    } on ApiException {
      // non bloquant : les cœurs apparaîtront vides
    }
  }

  static bool contains(String listingId) => ids.contains(listingId);

  static Future<bool> toggle(String listingId) async {
    final wasFavorite = ids.contains(listingId);
    // Optimiste : on met à jour l'UI immédiatement
    if (wasFavorite) {
      ids.remove(listingId);
    } else {
      ids.add(listingId);
    }
    try {
      if (wasFavorite) {
        await Api.delete('/listings/$listingId/favorite');
      } else {
        await Api.post('/listings/$listingId/favorite');
      }
    } on ApiException {
      // rollback en cas d'échec
      if (wasFavorite) {
        ids.add(listingId);
      } else {
        ids.remove(listingId);
      }
    }
    return ids.contains(listingId);
  }

  static void reset() {
    ids.clear();
    _loaded = false;
  }
}
