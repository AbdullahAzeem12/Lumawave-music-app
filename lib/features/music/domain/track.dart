import 'package:equatable/equatable.dart';

enum PlaybackCapability {
  authorizedFullStream, // e.g. Jamendo full-length streaming MP3
  promotionalPreview,   // e.g. iTunes 30-sec official preview audio
  officialExternal,     // e.g. External web link / video
}

class Track extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String artworkUrl;
  final int durationMs;
  final String streamUrl;
  final String provider; // 'jamendo' | 'itunes'
  final PlaybackCapability capability;
  final String genre;
  final String? storeUrl;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.artworkUrl,
    required this.durationMs,
    required this.streamUrl,
    required this.provider,
    required this.capability,
    required this.genre,
    this.storeUrl,
  });

  String get formattedDuration {
    final totalSeconds = durationMs ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'artworkUrl': artworkUrl,
      'durationMs': durationMs,
      'streamUrl': streamUrl,
      'provider': provider,
      'capability': capability.name,
      'genre': genre,
      'storeUrl': storeUrl,
    };
  }

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Unknown Title',
      artist: json['artist'] ?? 'Unknown Artist',
      album: json['album'] ?? '',
      artworkUrl: json['artworkUrl'] ?? '',
      durationMs: json['durationMs'] ?? 0,
      streamUrl: json['streamUrl'] ?? '',
      provider: json['provider'] ?? 'jamendo',
      capability: PlaybackCapability.values.firstWhere(
        (c) => c.name == json['capability'],
        orElse: () => PlaybackCapability.authorizedFullStream,
      ),
      genre: json['genre'] ?? 'Music',
      storeUrl: json['storeUrl'],
    );
  }

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? artworkUrl,
    int? durationMs,
    String? streamUrl,
    String? provider,
    PlaybackCapability? capability,
    String? genre,
    String? storeUrl,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      durationMs: durationMs ?? this.durationMs,
      streamUrl: streamUrl ?? this.streamUrl,
      provider: provider ?? this.provider,
      capability: capability ?? this.capability,
      genre: genre ?? this.genre,
      storeUrl: storeUrl ?? this.storeUrl,
    );
  }

  @override
  List<Object?> get props => [id, streamUrl, provider];
}
