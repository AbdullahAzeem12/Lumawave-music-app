import 'package:equatable/equatable.dart';
import 'track.dart';

class Playlist extends Equatable {
  final String id;
  final String name;
  final String description;
  final List<Track> tracks;
  final DateTime createdAt;

  const Playlist({
    required this.id,
    required this.name,
    this.description = '',
    this.tracks = const [],
    required this.createdAt,
  });

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    List<Track>? tracks,
    DateTime? createdAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      tracks: tracks ?? this.tracks,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'tracks': tracks.map((t) => t.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled Playlist',
      description: json['description'] as String? ?? '',
      tracks: (json['tracks'] as List<dynamic>? ?? [])
          .map((t) => Track.fromJson(t as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, name, tracks, createdAt];
}
