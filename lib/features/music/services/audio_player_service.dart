import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../domain/track.dart';

enum PlaybackRepeatMode {
  off,
  all,
  one,
}

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  final List<Track> _queue = [];
  int _currentIndex = -1;
  bool _isShuffle = false;
  PlaybackRepeatMode _repeatMode = PlaybackRepeatMode.off;

  final _queueController = StreamController<List<Track>>.broadcast();
  final _currentTrackController = StreamController<Track?>.broadcast();
  final _repeatModeController = StreamController<PlaybackRepeatMode>.broadcast();
  final _shuffleController = StreamController<bool>.broadcast();

  /// Optional resolver callback to convert 30s promotional clips into full 320kbps streams
  Future<Track?> Function(Track track)? onResolveTrack;

  AudioPlayer get player => _player;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<List<Track>> get queueStream => _queueController.stream;
  Stream<Track?> get currentTrackStream => _currentTrackController.stream;
  Stream<PlaybackRepeatMode> get repeatModeStream => _repeatModeController.stream;
  Stream<bool> get shuffleStream => _shuffleController.stream;

  Track? get currentTrack =>
      (_currentIndex >= 0 && _currentIndex < _queue.length) ? _queue[_currentIndex] : null;

  List<Track> get queue => List.unmodifiable(_queue);
  bool get isShuffle => _isShuffle;
  PlaybackRepeatMode get repeatMode => _repeatMode;
  bool get isPlaying => _player.playing;

  AudioPlayerService() {
    _initListener();
  }

  void _initListener() {
    // Automatically transition to next track when playback finishes
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (_repeatMode == PlaybackRepeatMode.one) {
          _player.seek(Duration.zero);
          _player.play();
        } else {
          skipNext();
        }
      }
    });
  }

  /// Plays a specific track with optional playlist queue
  Future<void> playTrack(Track track, {List<Track>? playlist}) async {
    if (playlist != null && playlist.isNotEmpty) {
      _queue.clear();
      _queue.addAll(playlist);
      _currentIndex = _queue.indexWhere((t) => t.id == track.id);
      if (_currentIndex == -1) {
        _queue.insert(0, track);
        _currentIndex = 0;
      }
    } else {
      if (!_queue.any((t) => t.id == track.id)) {
        _queue.add(track);
      }
      _currentIndex = _queue.indexWhere((t) => t.id == track.id);
    }

    _queueController.add(List.unmodifiable(_queue));
    await _playCurrentTrack();
  }

  /// Plays current track in queue, upgrading 30s promotional previews to full 320kbps streams if resolver is set
  Future<void> _playCurrentTrack() async {
    if (_currentIndex < 0 || _currentIndex >= _queue.length) return;
    var track = _queue[_currentIndex];

    if ((track.durationMs <= 35000 ||
            track.capability == PlaybackCapability.promotionalPreview ||
            track.provider == 'itunes') &&
        onResolveTrack != null) {
      try {
        final resolved = await onResolveTrack!(track);
        if (resolved != null) {
          track = resolved;
          _queue[_currentIndex] = resolved;
          _queueController.add(List.unmodifiable(_queue));
        }
      } catch (_) {}
    }

    _currentTrackController.add(track);
    await _loadAndPlay(track.streamUrl);
  }

  Future<void> _loadAndPlay(String streamUrl) async {
    try {
      await _player.stop();
      await _player.setUrl(streamUrl);
      await _player.play();
    } catch (_) {}
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      if (currentTrack != null) {
        await _player.play();
      }
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> skipNext() async {
    if (_queue.isEmpty) return;

    if (_currentIndex + 1 < _queue.length) {
      _currentIndex++;
      await _playCurrentTrack();
    } else if (_repeatMode == PlaybackRepeatMode.all) {
      _currentIndex = 0;
      await _playCurrentTrack();
    }
  }

  Future<void> skipPrevious() async {
    if (_queue.isEmpty) return;

    // If played more than 3 seconds, seek to start of current track
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }

    if (_currentIndex - 1 >= 0) {
      _currentIndex--;
      await _playCurrentTrack();
    } else {
      await _player.seek(Duration.zero);
    }
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    _shuffleController.add(_isShuffle);
    if (_isShuffle && _queue.isNotEmpty && currentTrack != null) {
      final current = currentTrack!;
      _queue.shuffle();
      _queue.remove(current);
      _queue.insert(0, current);
      _currentIndex = 0;
      _queueController.add(List.unmodifiable(_queue));
    }
  }

  void toggleRepeatMode() {
    switch (_repeatMode) {
      case PlaybackRepeatMode.off:
        _repeatMode = PlaybackRepeatMode.all;
        break;
      case PlaybackRepeatMode.all:
        _repeatMode = PlaybackRepeatMode.one;
        break;
      case PlaybackRepeatMode.one:
        _repeatMode = PlaybackRepeatMode.off;
        break;
    }
    _repeatModeController.add(_repeatMode);
  }

  void dispose() {
    _player.dispose();
    _queueController.close();
    _currentTrackController.close();
    _repeatModeController.close();
    _shuffleController.close();
  }
}
