import 'package:equatable/equatable.dart';
import '../../domain/track.dart';
import '../../services/audio_player_service.dart';
import '../../data/lrclib_provider.dart';

class PlayerState extends Equatable {
  final Track? currentTrack;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final List<Track> queue;
  final bool isShuffle;
  final PlaybackRepeatMode repeatMode;
  final LyricsData lyrics;
  final int activeLyricIndex;
  final bool isLoadingLyrics;

  const PlayerState({
    this.currentTrack,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.queue = const [],
    this.isShuffle = false,
    this.repeatMode = PlaybackRepeatMode.off,
    this.lyrics = LyricsData.empty,
    this.activeLyricIndex = 0,
    this.isLoadingLyrics = false,
  });

  double get progress {
    if (duration.inMilliseconds == 0) return 0.0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  String get positionFormatted {
    final m = position.inMinutes;
    final s = position.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get durationFormatted {
    final m = duration.inMinutes;
    final s = duration.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  PlayerState copyWith({
    Track? currentTrack,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    List<Track>? queue,
    bool? isShuffle,
    PlaybackRepeatMode? repeatMode,
    LyricsData? lyrics,
    int? activeLyricIndex,
    bool? isLoadingLyrics,
  }) {
    return PlayerState(
      currentTrack: currentTrack ?? this.currentTrack,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      queue: queue ?? this.queue,
      isShuffle: isShuffle ?? this.isShuffle,
      repeatMode: repeatMode ?? this.repeatMode,
      lyrics: lyrics ?? this.lyrics,
      activeLyricIndex: activeLyricIndex ?? this.activeLyricIndex,
      isLoadingLyrics: isLoadingLyrics ?? this.isLoadingLyrics,
    );
  }

  @override
  List<Object?> get props => [
        currentTrack,
        isPlaying,
        position,
        duration,
        queue,
        isShuffle,
        repeatMode,
        lyrics,
        activeLyricIndex,
        isLoadingLyrics,
      ];
}
