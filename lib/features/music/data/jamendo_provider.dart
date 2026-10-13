import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/track.dart';

class JamendoProvider {
  final List<String> _clientIds;
  static const String _baseUrl = 'https://api.jamendo.com/v3.0/tracks/';

  JamendoProvider({String? clientId})
      : _clientIds = [
          if (clientId != null && clientId.isNotEmpty) clientId,
          'b6747d04',
          '56d30c95',
          '709fa152',
        ];

  /// Fetches legal Creative Commons / open tracks from Jamendo
  Future<List<Track>> fetchTopTracks({int limit = 50, String? tag}) async {
    final tagParam = (tag != null && tag.isNotEmpty) ? '&tags=${Uri.encodeComponent(tag)}' : '';

    for (final id in _clientIds) {
      try {
        final uri = Uri.parse(
          '$_baseUrl?client_id=$id&format=json&limit=$limit&order=popularity_total&include=musicinfo$tagParam',
        );

        final response = await http.get(uri).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final results = data['results'] as List<dynamic>? ?? [];
          if (results.isNotEmpty) {
            return results
                .map((item) => _parseJamendoTrack(item))
                .where((t) => t.streamUrl.isNotEmpty)
                .toList();
          }
        }
      } catch (_) {}
    }

    return [];
  }

  /// Searches tracks by name or tag on Jamendo
  Future<List<Track>> searchTracks({required String query, int limit = 30}) async {
    final encoded = Uri.encodeComponent(query);

    for (final id in _clientIds) {
      try {
        final uri = Uri.parse(
          '$_baseUrl?client_id=$id&format=json&limit=$limit&namesearch=$encoded&include=musicinfo',
        );

        final response = await http.get(uri).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final results = data['results'] as List<dynamic>? ?? [];
          if (results.isNotEmpty) {
            return results
                .map((item) => _parseJamendoTrack(item))
                .where((t) => t.streamUrl.isNotEmpty)
                .toList();
          }
        }
      } catch (_) {}
    }

    return [];
  }

  Track _parseJamendoTrack(dynamic item) {
    final audioUrl = item['audio'] as String? ?? '';
    final durationSec = (item['duration'] as num?)?.toInt() ?? 180;
    final artwork = (item['image'] as String?)?.isNotEmpty == true
        ? item['image'] as String
        : ((item['album_image'] as String?) ?? '');

    return Track(
      id: 'jamendo_${item['id']}',
      title: item['name'] ?? 'Untitled Track',
      artist: item['artist_name'] ?? 'Independent Artist',
      album: item['album_name'] ?? 'Jamendo Release',
      artworkUrl: artwork,
      durationMs: durationSec * 1000,
      streamUrl: audioUrl,
      provider: 'jamendo',
      capability: PlaybackCapability.authorizedFullStream,
      genre: (item['musicinfo']?['tags']?['genres'] as List<dynamic>?)?.firstOrNull?.toString() ?? 'Creative Commons',
      storeUrl: item['shareurl'],
    );
  }
}

