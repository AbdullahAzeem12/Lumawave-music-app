import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/audio_player_service.dart';
import '../../data/music_repository.dart';
import '../../domain/track.dart';
import 'package:pulse/core/utils/lrc_parser.dart';
import 'player_state.dart';

class PlayerCubit extends Cubit<PlayerState> {
  final AudioPlayerService _audioService;
  final MusicRepository _musicRepository;

  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _trackSub;
  StreamSubscription? _queueSub;
  StreamSubscription? _shuffleSub;
  StreamSubscription? _repeatSub;

  PlayerCubit({
    required AudioPlayerService audioService,
    required MusicRepository musicRepository,
  })  : _audioService = audioService,
        _musicRepository = musicRepository,
        super(const PlayerState()) {
    _audioService.onResolveTrack = (track) => _musicRepository.resolveFullLengthTrack(track);
    _bindStreams();
  }

  void _bindStreams() {
    _posSub = _audioService.positionStream.listen((pos) {
      int activeLyric = state.activeLyricIndex;
      if (state.lyrics.hasSynced && state.lyrics.syncedLines.isNotEmpty) {
        activeLyric = LrcParser.findActiveLineIndex(
          state.lyrics.syncedLines,
          pos.inMilliseconds,
        );
      }
      emit(state.copyWith(
        position: pos,
        activeLyricIndex: activeLyric,
      ));
    });

    _durSub = _audioService.durationStream.listen((dur) {
      if (dur != null) {
        emit(state.copyWith(duration: dur));
      }
    });

    _stateSub = _audioService.playerStateStream.listen((ps) {
      emit(state.copyWith(isPlaying: ps.playing));
    });

    _trackSub = _audioService.currentTrackStream.listen((track) {
      emit(state.copyWith(
        currentTrack: track,
        duration: track != null && track.durationMs > 0
            ? Duration(milliseconds: track.durationMs)
            : state.duration,
      ));
      if (track != null) {
        _fetchLyricsForTrack(track);
      }
    });

    _queueSub = _audioService.queueStream.listen((q) {
      emit(state.copyWith(queue: q));
    });

    _shuffleSub = _audioService.shuffleStream.listen((shuf) {
      emit(state.copyWith(isShuffle: shuf));
    });

    _repeatSub = _audioService.repeatModeStream.listen((rep) {
      emit(state.copyWith(repeatMode: rep));
    });
  }

  Future<void> playTrack(Track track, {List<Track>? playlist}) async {
    Track trackToPlay = track;
    if (track.durationMs <= 35000 ||
        track.capability == PlaybackCapability.promotionalPreview ||
        track.provider == 'itunes') {
      try {
        final full = await _musicRepository.resolveFullLengthTrack(track);
        if (full != null) {
          trackToPlay = full;
        }
      } catch (_) {}
    }

    List<Track>? updatedPlaylist;
    if (playlist != null) {
      updatedPlaylist = playlist.map((t) => t.id == track.id ? trackToPlay : t).toList();
    }

    await _audioService.playTrack(trackToPlay, playlist: updatedPlaylist);
  }

  Future<void> togglePlayPause() async {
    await _audioService.togglePlayPause();
  }

  Future<void> seek(Duration pos) async {
    await _audioService.seek(pos);
  }

  Future<void> next() async {
    await _audioService.skipNext();
  }

  Future<void> previous() async {
    await _audioService.skipPrevious();
  }

  void toggleShuffle() {
    _audioService.toggleShuffle();
  }

  void toggleRepeat() {
    _audioService.toggleRepeatMode();
  }

  Future<void> _fetchLyricsForTrack(Track track) async {
    emit(state.copyWith(isLoadingLyrics: true));
    try {
      final lyrics = await _musicRepository.getLyrics(track);
      emit(state.copyWith(
        lyrics: lyrics,
        isLoadingLyrics: false,
        activeLyricIndex: 0,
      ));
    } catch (_) {
      emit(state.copyWith(isLoadingLyrics: false));
    }
  }

  @override
  Future<void> close() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _trackSub?.cancel();
    _queueSub?.cancel();
    _shuffleSub?.cancel();
    _repeatSub?.cancel();
    return super.close();
  }
}
