import '../services/player_service.dart';

/// Splits a raw artist string like "A, B & C" into ["A", "B", "C"].
List<String> splitArtists(String raw) {
  return raw
      .split(RegExp(r'[,&]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

/// All unique individual artists across all tracks, sorted alphabetically.
List<String> uniqueArtists(List<Track> tracks) {
  final set = <String>{};
  for (final t in tracks) {
    set.addAll(splitArtists(t.artist));
  }
  return set.toList()..sort();
}

/// All tracks where [artist] appears anywhere in the artist field.
List<Track> tracksForArtist(String artist, List<Track> tracks) {
  return tracks
      .where((t) => splitArtists(t.artist)
          .any((a) => a.toLowerCase() == artist.toLowerCase()))
      .toList();
}