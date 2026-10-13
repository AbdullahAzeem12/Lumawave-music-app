import 'package:equatable/equatable.dart';
import '../../domain/track.dart';
import '../../domain/playlist.dart';
import '../../data/music_repository.dart';

abstract class MusicState extends Equatable {
  const MusicState();
  @override
  List<Object?> get props => [];
}

class MusicLoading extends MusicState {}

class MusicLoaded extends MusicState {
  final MusicCatalog catalog;
  final String activeCategory; // 'All' | 'Bollywood' | 'Hollywood' | 'Indie'
  final List<Track> filteredTracks;
  final List<Track> searchResults;
  final bool isSearching;
  final List<Track> favorites;
  final List<Playlist> playlists;

  const MusicLoaded({
    required this.catalog,
    this.activeCategory = 'All',
    required this.filteredTracks,
    this.searchResults = const [],
    this.isSearching = false,
    this.favorites = const [],
    this.playlists = const [],
  });

  MusicLoaded copyWith({
    MusicCatalog? catalog,
    String? activeCategory,
    List<Track>? filteredTracks,
    List<Track>? searchResults,
    bool? isSearching,
    List<Track>? favorites,
    List<Playlist>? playlists,
  }) {
    return MusicLoaded(
      catalog: catalog ?? this.catalog,
      activeCategory: activeCategory ?? this.activeCategory,
      filteredTracks: filteredTracks ?? this.filteredTracks,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      favorites: favorites ?? this.favorites,
      playlists: playlists ?? this.playlists,
    );
  }

  @override
  List<Object?> get props => [
        catalog,
        activeCategory,
        filteredTracks,
        searchResults,
        isSearching,
        favorites,
        playlists,
      ];
}

class MusicError extends MusicState {
  final String message;
  const MusicError(this.message);
  @override
  List<Object?> get props => [message];
}
