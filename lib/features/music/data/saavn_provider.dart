import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dart_des/dart_des.dart';
import '../domain/track.dart';

class SaavnProvider {
  static const String _searchUrl = 'https://www.jiosaavn.com/api.php?__call=search.getResults&_format=json&_marker=0';
  static const String _desKey = '38346591';

  /// Decrypts JioSaavn encrypted_media_url using DES-ECB into full 320kbps streaming audio
  static String decryptMediaUrl(String encryptedUrl) {
    try {
      final des = DES(
        key: _desKey.codeUnits,
        mode: DESMode.ECB,
        paddingType: DESPaddingType.PKCS5,
      );
      final encryptedBytes = base64.decode(encryptedUrl.trim());
      final decryptedBytes = des.decrypt(encryptedBytes);
      var url = utf8.decode(decryptedBytes).replaceAll('\x00', '').trim();
      // Upgrade bitrate to crystal-clear 320kbps MP4/AAC
      url = url.replaceAll('_96.', '_320.').replaceAll('_160.', '_320.');
      return url;
    } catch (_) {
      return '';
    }
  }

  /// Cleans raw HTML entities and escaped chars from titles
  static String cleanText(String? raw) {
    if (raw == null) return '';
    return raw
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  /// Searches songs on JioSaavn and returns full-duration 320kbps tracks
  Future<List<Track>> searchTracks({
    required String query,
    required String defaultGenre,
    int limit = 50,
  }) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final uri = Uri.parse('$_searchUrl&n=$limit&p=1&q=$encodedQuery');

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>? ?? [];

        return results.map((item) {
          final encUrl = item['encrypted_media_url'] as String? ?? '';
          final streamUrl = encUrl.isNotEmpty ? decryptMediaUrl(encUrl) : '';
          final durationSec = int.tryParse(item['duration']?.toString() ?? '180') ?? 180;

          // Upgrade image to 500x500 high-res
          var artwork = item['image'] as String? ?? '';
          artwork = artwork.replaceAll('150x150', '500x500').replaceAll('50x50', '500x500');

          final rawTitle = item['song'] ?? item['title'] ?? 'Unknown Song';
          final rawArtist = item['primary_artists'] ?? item['singers'] ?? item['artist'] ?? 'Featured Artist';
          final rawAlbum = item['album'] ?? 'Bollywood Album';

          return Track(
            id: 'saavn_${item['id']}',
            title: cleanText(rawTitle),
            artist: cleanText(rawArtist),
            album: cleanText(rawAlbum),
            artworkUrl: artwork,
            durationMs: durationSec * 1000,
            streamUrl: streamUrl,
            provider: 'jiosaavn',
            capability: PlaybackCapability.authorizedFullStream,
            genre: defaultGenre,
            storeUrl: item['perma_url'],
          );
        }).where((t) => t.streamUrl.isNotEmpty && t.durationMs > 30000).toList();
      }
    } catch (_) {}

    return [];
  }

  /// Resolves full 320kbps full-length stream for an existing track (e.g., converting a 30s iTunes snippet to full song)
  Future<Track?> resolveFullAudioForTrack(Track original) async {
    try {
      final cleanTitle = original.title.split('(').first.split('-').first.trim();
      final cleanArtist = original.artist.split(',').first.split('&').first.trim();

      // 1. Try search with cleanTitle + cleanArtist
      var query = Uri.encodeComponent('$cleanTitle $cleanArtist');
      var uri = Uri.parse('$_searchUrl&n=5&p=1&q=$query');
      var response = await http.get(uri).timeout(const Duration(seconds: 8));

      var results = <dynamic>[];
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        results = data['results'] as List<dynamic>? ?? [];
      }

      // 2. Fallback to cleanTitle if no results
      if (results.isEmpty && cleanTitle.isNotEmpty) {
        query = Uri.encodeComponent(cleanTitle);
        uri = Uri.parse('$_searchUrl&n=5&p=1&q=$query');
        response = await http.get(uri).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          results = data['results'] as List<dynamic>? ?? [];
        }
      }

      for (final item in results) {
        final encUrl = item['encrypted_media_url'] as String? ?? '';
        if (encUrl.isEmpty) continue;
        final streamUrl = decryptMediaUrl(encUrl);
        if (streamUrl.isEmpty) continue;

        final durationSec = int.tryParse(item['duration']?.toString() ?? '0') ?? 0;
        if (durationSec > 35) {
          // Upgrade artwork if available
          var artwork = item['image'] as String? ?? original.artworkUrl;
          artwork = artwork.replaceAll('150x150', '500x500');

          return original.copyWith(
            streamUrl: streamUrl,
            durationMs: durationSec * 1000,
            capability: PlaybackCapability.authorizedFullStream,
            artworkUrl: artwork.isNotEmpty ? artwork : original.artworkUrl,
          );
        }
      }
    } catch (_) {}

    return null;
  }
}
