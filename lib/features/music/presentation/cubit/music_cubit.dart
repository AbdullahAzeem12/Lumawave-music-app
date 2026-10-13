import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/music_repository.dart';
import '../../domain/track.dart';
import '../../../auth/data/auth_repository.dart';
import 'music_state.dart';

class MusicCubit extends Cubit<MusicState> {
  final MusicRepository _musicRepository;
  final AuthRepository _authRepository;

  MusicCubit({
    required MusicRepository musicRepository,
    required AuthRepository authRepository,
  })  : _musicRepository = musicRepository,
        _authRepository = authRepository,
        super(MusicLoading()) {
    loadCatalog();
  }

  Future<void> loadCatalog({bool force = false}) async {
    emit(MusicLoading());
    try {
      final catalog = await _musicRepository.loadCompleteCatalog(forceRefresh: force);
      final favorites = await _authRepository.getFavorites();
      final playlists = await _authRepository.getPlaylists();

      emit(MusicLoaded(
        catalog: catalog,
        activeCategory: 'All',
        filteredTracks: catalog.allTracks,
        favorites: favorites,
        playlists: playlists,
      ));
    } catch (e) {
      emit(MusicError('Failed to load music catalog: ${e.toString()}'));
    }
  }

  void filterCategory(String category) {
    if (state is! MusicLoaded) return;
    final current = state as MusicLoaded;

    List<Track> filtered;
    switch (category) {
      case 'Bollywood':
        filtered = current.catalog.bollywood;
        break;
      case 'Hollywood':
        filtered = current.catalog.hollywood;
        break;
      case 'Indie':
        filtered = current.catalog.indie;
        break;
      case 'All':
      default:
        filtered = current.catalog.allTracks;
        break;
    }

    emit(current.copyWith(
      activeCategory: category,
      filteredTracks: filtered,
    ));
  }

  Future<void> search(String query) async {
    if (state is! MusicLoaded) return;
    final current = state as MusicLoaded;

    if (query.trim().isEmpty) {
      emit(current.copyWith(
        searchResults: [],
        isSearching: false,
      ));
      return;
    }

    emit(current.copyWith(isSearching: true));
    try {
      final results = await _musicRepository.searchTracks(query);
      emit(current.copyWith(
        searchResults: results,
        isSearching: false,
      ));
    } catch (_) {
      emit(current.copyWith(isSearching: false));
    }
  }

  Future<void> toggleFavorite(Track track) async {
    if (state is! MusicLoaded) return;
    final current = state as MusicLoaded;

    await _authRepository.toggleFavorite(track);
    final updatedFavs = await _authRepository.getFavorites();

    emit(current.copyWith(favorites: updatedFavs));
  }

  bool isFavorite(String trackId) {
    if (state is! MusicLoaded) return false;
    final current = state as MusicLoaded;
    return current.favorites.any((t) => t.id == trackId);
  }

  Future<void> createPlaylist(String name, {String description = ''}) async {
    if (state is! MusicLoaded) return;
    final current = state as MusicLoaded;

    await _authRepository.createPlaylist(name, description: description);
    final updatedPlaylists = await _authRepository.getPlaylists();
    emit(current.copyWith(playlists: updatedPlaylists));
  }

  Future<void> deletePlaylist(String playlistId) async {
    if (state is! MusicLoaded) return;
    final current = state as MusicLoaded;

    await _authRepository.deletePlaylist(playlistId);
    final updatedPlaylists = await _authRepository.getPlaylists();
    emit(current.copyWith(playlists: updatedPlaylists));
  }

  Future<bool> addTrackToPlaylist(String playlistId, Track track) async {
    if (state is! MusicLoaded) return false;
    final current = state as MusicLoaded;

    final success = await _authRepository.addTrackToPlaylist(playlistId, track);
    if (success) {
      final updatedPlaylists = await _authRepository.getPlaylists();
      emit(current.copyWith(playlists: updatedPlaylists));
    }
    return success;
  }

  Future<void> removeTrackFromPlaylist(String playlistId, String trackId) async {
    if (state is! MusicLoaded) return;
    final current = state as MusicLoaded;

    await _authRepository.removeTrackFromPlaylist(playlistId, trackId);
    final updatedPlaylists = await _authRepository.getPlaylists();
    emit(current.copyWith(playlists: updatedPlaylists));
  }
}
