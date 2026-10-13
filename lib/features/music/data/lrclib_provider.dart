import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/utils/lrc_parser.dart';

class LyricsData {
  final bool hasSynced;
  final List<LyricLine> syncedLines;
  final String plainText;

  const LyricsData({
    required this.hasSynced,
    required this.syncedLines,
    required this.plainText,
  });

  static const empty = LyricsData(
    hasSynced: false,
    syncedLines: [],
    plainText: '',
  );
}

class LrclibProvider {
  static const String _baseUrl = 'https://lrclib.net/api';

  /// Fetches synchronized or plain lyrics for a track
  Future<LyricsData> fetchLyrics({
    required String trackTitle,
    required String artistName,
    int? durationMs,
  }) async {
    try {
      // Clean query strings (remove "(feat. ...)", etc.)
      final cleanTitle = trackTitle.split('(').first.split('-').first.trim();
      final cleanArtist = artistName.split(',').first.split('&').first.trim();

      // 1. First attempt exact match
      final uri = Uri.parse(
        '$_baseUrl/get?track_name=${Uri.encodeComponent(cleanTitle)}&artist_name=${Uri.encodeComponent(cleanArtist)}',
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'PulseMusic/1.0 (https://pulse.app)'},
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final lyrics = _parseLyricsResponse(data, durationMs: durationMs);
        if (lyrics.hasSynced) {
          return lyrics;
        }
      }

      // 2. Search endpoint with title + artist
      final searchUri1 = Uri.parse(
        '$_baseUrl/search?q=${Uri.encodeComponent('$cleanTitle $cleanArtist')}',
      );
      final searchRes1 = await http.get(
        searchUri1,
        headers: {'User-Agent': 'PulseMusic/1.0 (https://pulse.app)'},
      ).timeout(const Duration(seconds: 6));

      if (searchRes1.statusCode == 200) {
        final List<dynamic> list = json.decode(searchRes1.body);
        // Prioritize candidate with actual synced lyrics
        for (final item in list) {
          final candidate = _parseLyricsResponse(item, durationMs: durationMs);
          if (candidate.hasSynced && candidate.syncedLines.isNotEmpty) {
            return candidate;
          }
        }
        if (list.isNotEmpty) {
          final plainCandidate = _parseLyricsResponse(list.first, durationMs: durationMs);
          if (plainCandidate.syncedLines.isNotEmpty || plainCandidate.plainText.isNotEmpty) {
            return plainCandidate;
          }
        }
      }

      // 3. Search endpoint with cleanTitle alone (finds alternative artist collaborations)
      final searchUri2 = Uri.parse(
        '$_baseUrl/search?q=${Uri.encodeComponent(cleanTitle)}',
      );
      final searchRes2 = await http.get(
        searchUri2,
        headers: {'User-Agent': 'PulseMusic/1.0 (https://pulse.app)'},
      ).timeout(const Duration(seconds: 6));

      if (searchRes2.statusCode == 200) {
        final List<dynamic> list = json.decode(searchRes2.body);
        for (final item in list) {
          final candidate = _parseLyricsResponse(item, durationMs: durationMs);
          if (candidate.hasSynced && candidate.syncedLines.isNotEmpty) {
            return candidate;
          }
        }
        if (list.isNotEmpty) {
          return _parseLyricsResponse(list.first, durationMs: durationMs);
        }
      }
    } catch (_) {}

    return LyricsData.empty;
  }

  LyricsData _parseLyricsResponse(dynamic data, {int? durationMs}) {
    if (data == null) return LyricsData.empty;
    final syncedStr = data['syncedLyrics'] as String?;
    final plainStr = data['plainLyrics'] as String? ?? '';

    if (syncedStr != null && syncedStr.isNotEmpty) {
      final parsed = LrcParser.parse(syncedStr);
      if (parsed.isNotEmpty) {
        return LyricsData(
          hasSynced: true,
          syncedLines: parsed,
          plainText: plainStr,
        );
      }
    }

    if (plainStr.isNotEmpty) {
      // Intelligently generate synchronized lines across track duration so lines highlight & move smoothly!
      final pacedLines = _generatePacedLines(plainStr, durationMs ?? 180000);
      return LyricsData(
        hasSynced: pacedLines.isNotEmpty,
        syncedLines: pacedLines,
        plainText: plainStr,
      );
    }

    return LyricsData.empty;
  }

  List<LyricLine> _generatePacedLines(String plainText, int durationMs) {
    final rawLines = plainText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.startsWith('[') && !l.endsWith(']'))
        .toList();
    if (rawLines.isEmpty) return [];

    final startMs = durationMs > 25000 ? 8000 : 2000;
    final endMs = durationMs > 30000 ? durationMs - 8000 : durationMs;
    final availableMs = (endMs - startMs).clamp(5000, durationMs);
    final interval = availableMs / rawLines.length;

    final result = <LyricLine>[];
    for (int i = 0; i < rawLines.length; i++) {
      final ts = (startMs + (i * interval)).toInt();
      result.add(LyricLine(timestampMs: ts, text: rawLines[i]));
    }
    return result;
  }
}

