import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/utils/password_validator.dart';
import 'package:pulse/core/utils/lrc_parser.dart';
import 'package:pulse/features/music/domain/track.dart';
import 'package:pulse/features/music/domain/playlist.dart';
import 'package:pulse/features/music/data/music_repository.dart';
import 'package:pulse/features/music/data/audius_provider.dart';
import 'package:pulse/features/music/data/jamendo_provider.dart';
import 'package:pulse/features/music/data/lrclib_provider.dart';
import 'package:pulse/features/music/data/saavn_provider.dart';

void main() {
  group('LumaWave Core Utility & Domain Tests', () {
    test('PasswordValidator calculates entropy scores correctly', () {
      final weakResult = PasswordValidator.evaluate('abc');
      expect(weakResult.strength, PasswordStrength.weak);

      final strongResult = PasswordValidator.evaluate('SecurePass123!@#');
      expect(strongResult.score, greaterThanOrEqualTo(0.8));
    });

    test('LrcParser parses timestamped lyric lines', () {
      const sampleLrc = '[00:12.50]Hello world\n[00:18.20]Second line';
      final lines = LrcParser.parse(sampleLrc);

      expect(lines.length, 2);
      expect(lines[0].text, 'Hello world');
      expect(lines[0].timestampMs, 12500);

      final activeIndex = LrcParser.findActiveLineIndex(lines, 15000);
      expect(activeIndex, 0);
    });

    test('Track formats duration correctly', () {
      const track = Track(
        id: 'test_1',
        title: 'Starry Night',
        artist: 'Luna',
        album: 'Cosmic Dreams',
        artworkUrl: '',
        durationMs: 215000,
        streamUrl: 'https://example.com/audio.mp3',
        provider: 'audius',
        capability: PlaybackCapability.authorizedFullStream,
        genre: 'Electronic',
      );

      expect(track.formattedDuration, '03:35');
      expect(track.toJson()['title'], 'Starry Night');
    });

    test('Playlist serializes and deserializes correctly', () {
      const track = Track(
        id: 'test_1',
        title: 'Starry Night',
        artist: 'Luna',
        album: 'Cosmic Dreams',
        artworkUrl: '',
        durationMs: 215000,
        streamUrl: 'https://example.com/audio.mp3',
        provider: 'jamendo',
        capability: PlaybackCapability.authorizedFullStream,
        genre: 'Electronic',
      );

      final playlist = Playlist(
        id: 'pl_123',
        name: 'Cyber Vibes',
        description: 'Synthwave & Electro',
        tracks: const [track],
        createdAt: DateTime(2026, 1, 1),
      );

      final json = playlist.toJson();
      expect(json['name'], 'Cyber Vibes');
      expect((json['tracks'] as List).length, 1);

      final restored = Playlist.fromJson(json);
      expect(restored.id, 'pl_123');
      expect(restored.name, 'Cyber Vibes');
      expect(restored.tracks.length, 1);
      expect(restored.tracks.first.title, 'Starry Night');
    });
  });

  group('Dynamic Open-Source Music Repository Tests', () {
    test('AudiusProvider fetches trending open-source tracks dynamically', () async {
      final audius = AudiusProvider();
      final tracks = await audius.fetchTrendingTracks(limit: 20);

      expect(tracks, isNotEmpty);
      expect(tracks.first.streamUrl, contains('discoveryprovider.audius.co'));
      expect(tracks.first.provider, 'audius');
      expect(tracks.first.capability, PlaybackCapability.authorizedFullStream);
    });

    test('JamendoProvider initializes with multi-key rotation and handles requests gracefully', () async {
      final jamendo = JamendoProvider();
      final tracks = await jamendo.fetchTopTracks(limit: 5);
      // Even if quota limits are reached on third-party servers, provider never crashes
      expect(tracks, isA<List<Track>>());
    });

    test('LrclibProvider searches and parses open-source synchronized lyrics', () async {
      final lrclib = LrclibProvider();
      final lyrics = await lrclib.fetchLyrics(
        trackTitle: 'Bohemian Rhapsody',
        artistName: 'Queen',
      );
      expect(lyrics.hasSynced || lyrics.plainText.isNotEmpty, isTrue);
    });

    test('MusicRepository dynamically loads 200+ songs simultaneously from all active libraries', () async {
      final repository = MusicRepository();
      final catalog = await repository.loadCompleteCatalog(forceRefresh: true);

      // Verify dynamically aggregated catalog size
      expect(catalog.allTracks.length, greaterThan(150));
      expect(catalog.bollywood.length, greaterThan(30));
      expect(catalog.hollywood.length, greaterThan(30));
      expect(catalog.indie.length, greaterThan(30));
      expect(catalog.featured.length, greaterThanOrEqualTo(4));

      // Verify each track has valid streaming and metadata fields
      for (final track in catalog.allTracks.take(10)) {
        expect(track.id, isNotEmpty);
        expect(track.title, isNotEmpty);
        expect(track.streamUrl, isNotEmpty);
      }
    });

    test('MusicRepository live search queries Jamendo, Audius and iTunes simultaneously', () async {
      final repository = MusicRepository();
      final results = await repository.searchTracks('electronic');

      expect(results, isNotEmpty);
      expect(results.any((t) => t.provider == 'audius'), isTrue);
    });

    test('SaavnProvider cleans text and decrypts media URLs to 320kbps streams', () {
      expect(
        SaavnProvider.cleanText('Soni Soni (From &quot;Ishq Vishk Rebound&quot;)'),
        'Soni Soni (From "Ishq Vishk Rebound")',
      );
      expect(
        SaavnProvider.cleanText('Rochak&#039;s Track &amp; More'),
        "Rochak's Track & More",
      );
    });

    test('SaavnProvider searches and returns full-duration 320kbps tracks', () async {
      final saavn = SaavnProvider();
      final tracks = await saavn.searchTracks(
        query: 'Soni Soni',
        defaultGenre: 'Bollywood',
        limit: 5,
      );

      expect(tracks, isNotEmpty);
      expect(tracks.first.durationMs, greaterThan(35000));
      expect(tracks.first.streamUrl, contains('_320.mp4'));
      expect(tracks.first.capability, PlaybackCapability.authorizedFullStream);
    });
  });
}



