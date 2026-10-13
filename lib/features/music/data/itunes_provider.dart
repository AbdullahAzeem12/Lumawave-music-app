import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/track.dart';

class ItunesProvider {
  static const String _searchUrl = 'https://itunes.apple.com/search';

  /// Searches songs by query (e.g., 'bollywood hits', 'billboard top hits')
  Future<List<Track>> searchTracks({
    required String query,
    required String defaultGenre,
    int limit = 50,
  }) async {
    try {
      final encodedTerm = Uri.encodeComponent(query);
      final uri = Uri.parse('$_searchUrl?term=$encodedTerm&entity=song&limit=$limit');

      final response = await http.get(uri).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>? ?? [];

        return results.map((item) {
          final previewAudio = item['previewUrl'] as String? ?? '';
          final durationMs = (item['trackTimeMillis'] as num?)?.toInt() ?? 180000;
          // Upgrade 100x100 artwork to crisp 600x600 high-res
          final rawArt = item['artworkUrl100'] as String? ?? '';
          final highResArt = rawArt.replaceAll('100x100bb', '600x600bb');

          return Track(
            id: 'itunes_${item['trackId']}',
            title: item['trackName'] ?? 'Unknown Song',
            artist: item['artistName'] ?? 'Featured Artist',
            album: item['collectionName'] ?? 'Album',
            artworkUrl: highResArt,
            durationMs: durationMs,
            streamUrl: previewAudio,
            provider: 'itunes',
            capability: PlaybackCapability.promotionalPreview,
            genre: item['primaryGenreName'] ?? defaultGenre,
            storeUrl: item['trackViewUrl'],
          );
        }).where((t) => t.streamUrl.isNotEmpty).toList();
      }
    } catch (_) {}

    return [];
  }
}
