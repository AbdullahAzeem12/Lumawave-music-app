import '../domain/track.dart';
import 'jamendo_provider.dart';
import 'audius_provider.dart';
import 'itunes_provider.dart';
import 'saavn_provider.dart';
import 'lrclib_provider.dart';

class MusicCatalog {
  final List<Track> allTracks;
  final List<Track> featured;
  final List<Track> bollywood;
  final List<Track> hollywood;
  final List<Track> indie;

  const MusicCatalog({
    required this.allTracks,
    required this.featured,
    required this.bollywood,
    required this.hollywood,
    required this.indie,
  });

  static const empty = MusicCatalog(
    allTracks: [],
    featured: [],
    bollywood: [],
    hollywood: [],
    indie: [],
  );
}

class MusicRepository {
  final JamendoProvider _jamendoProvider;
  final AudiusProvider _audiusProvider;
  final ItunesProvider _itunesProvider;
  final SaavnProvider _saavnProvider;
  final LrclibProvider _lrclibProvider;

  MusicCatalog? _cachedCatalog;

  MusicRepository({
    JamendoProvider? jamendoProvider,
    AudiusProvider? audiusProvider,
    ItunesProvider? itunesProvider,
    SaavnProvider? saavnProvider,
    LrclibProvider? lrclibProvider,
  })  : _jamendoProvider = jamendoProvider ?? JamendoProvider(),
        _audiusProvider = audiusProvider ?? AudiusProvider(),
        _itunesProvider = itunesProvider ?? ItunesProvider(),
        _saavnProvider = saavnProvider ?? SaavnProvider(),
        _lrclibProvider = lrclibProvider ?? LrclibProvider();

  /// Dynamically loads 200+ live songs across Indie, Bollywood, and Hollywood
  /// with full 320kbps playback duration from JioSaavn, Jamendo, Audius, and iTunes.
  Future<MusicCatalog> loadCompleteCatalog({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedCatalog != null && _cachedCatalog!.allTracks.isNotEmpty) {
      return _cachedCatalog!;
    }

    try {
      // Execute parallel live requests simultaneously across JioSaavn, Jamendo, Audius, and iTunes
      final results = await Future.wait([
        // 1. Jamendo Open-Source & Creative Commons top tracks
        _jamendoProvider.fetchTopTracks(limit: 50),
        // 2. Jamendo Indian & World Creative Commons tracks
        _jamendoProvider.searchTracks(query: 'india hindi', limit: 20),
        // 3. Audius Decentralized Open-Source Trending tracks
        _audiusProvider.fetchTrendingTracks(limit: 100),
        // 4. Audius Non-Copyright Indian / Bollywood & World tracks
        _audiusProvider.searchTracks(query: 'bollywood indian hindi', limit: 30),
        // 5. Audius Electronic & Chill curation
        _audiusProvider.searchTracks(query: 'chill synthwave indie lo-fi', limit: 30),
        // 6. JioSaavn Bollywood Hits (Full-length 320kbps high-quality streams)
        _saavnProvider.searchTracks(
          query: 'bollywood hits',
          defaultGenre: 'Bollywood',
          limit: 50,
        ),
        // 7. JioSaavn Punjabi & Desi Beats (Full-length 320kbps high-quality streams)
        _saavnProvider.searchTracks(
          query: 'punjabi hits',
          defaultGenre: 'Bollywood',
          limit: 30,
        ),
        // 8. iTunes Hollywood Billboard Top 100
        _itunesProvider.searchTracks(
          query: 'billboard top 100 hits',
          defaultGenre: 'Hollywood',
          limit: 50,
        ),
        // 9. iTunes Global Pop & Rock
        _itunesProvider.searchTracks(
          query: 'global pop acoustic',
          defaultGenre: 'Hollywood',
          limit: 30,
        ),
      ]);

      final jamendoTop = results[0];
      final jamendoIndian = results[1];
      final audiusTrending = results[2];
      final audiusIndian = results[3];
      final audiusCurated = results[4];
      final bollywoodHits = results[5];
      final punjabiHits = results[6];
      final hollywoodHits = results[7];
      final globalPop = results[8];

      // Combine Indie & Open Source (Audius + Jamendo)
      final indieTracks = <Track>[];
      final indieSeen = <String>{};
      for (final t in [...audiusTrending, ...audiusCurated, ...jamendoTop]) {
        if (!indieSeen.contains(t.id)) {
          indieSeen.add(t.id);
          indieTracks.add(t);
        }
      }

      // Combine Bollywood & Indian tracks (Audius non-copyright + Jamendo CC + iTunes)
      final bollywoodTracks = <Track>[];
      final bollySeen = <String>{};
      for (final t in [...bollywoodHits, ...punjabiHits, ...audiusIndian, ...jamendoIndian]) {
        if (!bollySeen.contains(t.id)) {
          bollySeen.add(t.id);
          bollywoodTracks.add(t);
        }
      }

      // Combine Hollywood & Global Pop tracks
      final hollywoodTracks = <Track>[];
      final hollySeen = <String>{};
      for (final t in [...hollywoodHits, ...globalPop]) {
        if (!hollySeen.contains(t.id)) {
          hollySeen.add(t.id);
          hollywoodTracks.add(t);
        }
      }

      // Merge and deduplicate across entire unified catalog
      final seenIds = <String>{};
      final combined = <Track>[];

      for (final list in [indieTracks, bollywoodTracks, hollywoodTracks]) {
        for (final track in list) {
          if (!seenIds.contains(track.id)) {
            seenIds.add(track.id);
            combined.add(track);
          }
        }
      }

      // Prepare hero featured items (balanced diversity from all active libraries)
      final featured = <Track>[];
      if (bollywoodTracks.isNotEmpty) featured.add(bollywoodTracks.first);
      if (hollywoodTracks.isNotEmpty) featured.add(hollywoodTracks.first);
      if (indieTracks.isNotEmpty) featured.add(indieTracks.first);
      if (bollywoodTracks.length > 1) featured.add(bollywoodTracks[1]);
      if (hollywoodTracks.length > 1) featured.add(hollywoodTracks[1]);
      if (indieTracks.length > 1) featured.add(indieTracks[1]);

      _cachedCatalog = MusicCatalog(
        allTracks: combined,
        featured: featured,
        bollywood: bollywoodTracks,
        hollywood: hollywoodTracks,
        indie: indieTracks,
      );

      return _cachedCatalog!;
    } catch (_) {
      return _cachedCatalog ?? MusicCatalog.empty;
    }
  }

  /// Searches tracks across cached catalogue and live Jamendo, Audius, and iTunes APIs simultaneously
  Future<List<Track>> searchTracks(String query) async {
    if (query.trim().isEmpty) {
      return _cachedCatalog?.allTracks ?? [];
    }

    final lowerQuery = query.toLowerCase();

    // First filter in-memory catalog
    final localMatches = (_cachedCatalog?.allTracks ?? []).where((t) {
      return t.title.toLowerCase().contains(lowerQuery) ||
          t.artist.toLowerCase().contains(lowerQuery) ||
          t.genre.toLowerCase().contains(lowerQuery) ||
          t.album.toLowerCase().contains(lowerQuery);
    }).toList();

    // Augment dynamically with live queries to JioSaavn, Jamendo, Audius, AND iTunes simultaneously
    try {
      final searchResponses = await Future.wait([
        _saavnProvider.searchTracks(query: query, defaultGenre: 'Bollywood', limit: 25),
        _jamendoProvider.searchTracks(query: query, limit: 20),
        _audiusProvider.searchTracks(query: query, limit: 25),
        _itunesProvider.searchTracks(
          query: query,
          defaultGenre: 'Search Result',
          limit: 25,
        ),
      ]);

      final saavnResults = searchResponses[0];
      final jamendoResults = searchResponses[1];
      final audiusResults = searchResponses[2];
      final itunesResults = searchResponses[3];

      final combined = List<Track>.from(localMatches);
      final existingIds = combined.map((t) => t.id).toSet();

      for (final track in [...saavnResults, ...audiusResults, ...itunesResults, ...jamendoResults]) {
        if (!existingIds.contains(track.id)) {
          existingIds.add(track.id);
          combined.add(track);
        }
      }

      return combined;
    } catch (_) {
      return localMatches;
    }
  }

  /// Automatically resolves full-length 320kbps audio for tracks with 30s preview limits
  Future<Track?> resolveFullLengthTrack(Track track) {
    return _saavnProvider.resolveFullAudioForTrack(track);
  }

  /// Fetches synchronized or plain lyrics from open-source LRCLIB library with pacing fallback
  Future<LyricsData> getLyrics(Track track) {
    return _lrclibProvider.fetchLyrics(
      trackTitle: track.title,
      artistName: track.artist,
      durationMs: track.durationMs,
    );
  }
}


