import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/track.dart';

class AudiusProvider {
  static const String _appName = 'PulseMusic';
  static const String _baseUrl = 'https://discoveryprovider.audius.co/v1';

  /// Fetches top trending open-source tracks from decentralized Audius network
  Future<List<Track>> fetchTrendingTracks({int limit = 100}) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/tracks/trending?app_name=$_appName&limit=$limit',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['data'] as List<dynamic>? ?? [];

        return results
            .map((item) => _parseAudiusTrack(item))
            .where((t) => t.streamUrl.isNotEmpty)
            .toList();
      }
    } catch (_) {}

    return [];
  }

  /// Searches open-source tracks by query on Audius
  Future<List<Track>> searchTracks({required String query, int limit = 30}) async {
    try {
      final encoded = Uri.encodeComponent(query);
      final uri = Uri.parse('$_baseUrl/tracks/search?query=$encoded&app_name=$_appName&limit=$limit');

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['data'] as List<dynamic>? ?? [];

        return results
            .map((item) => _parseAudiusTrack(item))
            .where((t) => t.streamUrl.isNotEmpty)
            .toList();
      }
    } catch (_) {}

    return [];
  }

  Track _parseAudiusTrack(dynamic item) {
    final trackId = item['id']?.toString() ?? '';
    final title = item['title']?.toString() ?? 'Untitled Track';
    final user = item['user'] as Map<String, dynamic>?;
    final artist = user?['name']?.toString() ?? user?['handle']?.toString() ?? 'Independent Artist';
    final durationSec = (item['duration'] as num?)?.toInt() ?? 180;

    final artworkMap = item['artwork'] as Map<String, dynamic>?;
    final artworkUrl = artworkMap?['480x480']?.toString() ??
        artworkMap?['1000x1000']?.toString() ??
        artworkMap?['150x150']?.toString() ??
        '';

    final streamUrl = '$_baseUrl/tracks/$trackId/stream?app_name=$_appName';
    final genre = item['genre']?.toString() ?? 'Indie';

    return Track(
      id: 'audius_$trackId',
      title: title,
      artist: artist,
      album: (item['mood'] != null && item['mood'].toString().isNotEmpty)
          ? '${item['mood']} Vibes'
          : 'Audius Release',
      artworkUrl: artworkUrl,
      durationMs: durationSec * 1000,
      streamUrl: streamUrl,
      provider: 'audius',
      capability: PlaybackCapability.authorizedFullStream,
      genre: genre,
      storeUrl: 'https://audius.co/tracks/$trackId',
    );
  }
}
