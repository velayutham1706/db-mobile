import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Track model ──────────────────────────────────────────────────────────────

class Track {
  final int id;
  String title;
  String artist;
  String genre;
  String language;
  String? album;
  String? url;
  String? coverUrl;
  bool liked;
  String? duration;
  int? seconds;
  DateTime? addedAt;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.genre,
    required this.language,
    this.album,
    this.url,
    this.coverUrl,
    this.liked = false,
    this.duration,
    this.seconds,
    this.addedAt,
  });

  factory Track.fromFirestore(Map<String, dynamic> data) {
    final rawSeconds = (data['seconds'] as num?)?.toInt();
    final rawDuration = data['duration'] as String?;

    String? fmtDuration;
    if (rawDuration != null && rawDuration.trim().isNotEmpty) {
      fmtDuration = rawDuration.trim();
    } else if (rawSeconds != null && rawSeconds > 0) {
      final m = rawSeconds ~/ 60;
      final s = rawSeconds % 60;
      fmtDuration = '$m:${s.toString().padLeft(2, '0')}';
    }

    return Track(
      id: (data['id'] as num?)?.toInt() ?? 0,
      title: data['title'] ?? 'Unknown',
      artist: data['artist'] ?? 'Unknown',
      genre: data['genre'] ?? '',
      language: data['language'] ?? '',
      album: data['album'],
      url: data['url'],
      coverUrl: data['coverUrl'],
      duration: fmtDuration,
      seconds: rawSeconds,
      addedAt: (data['addedAt'] as Timestamp?)?.toDate(),
    );
  }

  Track copyWith({
    bool? liked,
    String? coverUrl,
    String? duration,
    int? seconds,
  }) =>
      Track(
        id: id,
        title: title,
        artist: artist,
        genre: genre,
        language: language,
        album: album,
        url: url,
        coverUrl: coverUrl ?? this.coverUrl,
        liked: liked ?? this.liked,
        duration: duration ?? this.duration,
        seconds: seconds ?? this.seconds,
        addedAt: addedAt,
      );
}

// ── Playlist model ───────────────────────────────────────────────────────────

class PlaylistModel {
  String name;
  String emoji;
  List<int> trackIds;

  PlaylistModel({
    required this.name,
    required this.emoji,
    required this.trackIds,
  });

  factory PlaylistModel.fromMap(Map<String, dynamic> map) => PlaylistModel(
        name: map['name'] ?? 'Playlist',
        emoji: map['emoji'] ?? '🎵',
        trackIds: List<int>.from(map['trackIds'] ?? []),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'emoji': emoji,
        'trackIds': trackIds,
      };
}

// ── PlayerService ────────────────────────────────────────────────────────────

enum RepeatMode { off, all, one }

class PlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Full track library loaded from Firestore — never reordered.
  List<Track> _tracks = [];

  // Pre-sorted once at load; never touched by playback events.
  List<Track> _recentlyAdded = [];

  // The active queue: whatever list the user tapped into (a language section,
  // an artist list, recently added, the full library, etc.).
  // next/prev navigate within this list only.
  List<Track> _queue = [];
  int _curIdx = 0; // index into _queue

  List<PlaylistModel> _playlists = [];
  List<int> _recentlyPlayed = [];
  Set<int> _likedIds = {};

  bool _shuffle = false;
  RepeatMode _repeat = RepeatMode.off;
  bool _loading = false;
  bool _tracksLoading = false;
  double _volume = 0.75;
  bool _hasActiveSession = false;

  Duration _position = Duration.zero;
  int _lastPositionSeconds = -1;
  Duration _duration = Duration.zero;
  bool _playing = false;
  bool _settingQueue = false;

  // ── Getters ────────────────────────────────────────────────────────────────

  List<Track> get tracks => _tracks;
  List<Track> get recentlyAdded => _recentlyAdded;
  List<PlaylistModel> get playlists => _playlists;
  List<int> get recentlyPlayed => _recentlyPlayed;
  int get curIdx => _curIdx;
  bool get shuffle => _shuffle;
  RepeatMode get repeat => _repeat;
  bool get loading => _loading;
  bool get tracksLoading => _tracksLoading;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get playing => _playing;
  double get volume => _volume;
  bool get hasActiveSession => _hasActiveSession;

  Track get currentTrack => _queue.isNotEmpty
      ? _queue[_curIdx.clamp(0, _queue.length - 1)]
      : Track(id: -1, title: '—', artist: '—', genre: '', language: '');

  PlayerService() {
    _player.setVolume(_volume);
    _initAudioListeners();
    loadTracks();
    _loadRecentlyPlayed();
    _loadLiked();
  }

  // ── Recently played persistence ───────────────────────────────────────────

  Future<void> _loadRecentlyPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('recently_played') ?? [];
    _recentlyPlayed = ids.map((e) => int.parse(e)).toList();
    notifyListeners();
  }

  Future<void> _saveRecentlyPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'recently_played',
      _recentlyPlayed.map((e) => e.toString()).toList(),
    );
  }

  // ── Audio event listeners ─────────────────────────────────────────────────

  void _initAudioListeners() {
    _player.playerStateStream.listen((state) {
      final newPlaying = state.playing;
      final newLoading = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;

      if (newPlaying != _playing || newLoading != _loading) {
        _playing = newPlaying;
        _loading = newLoading;
        notifyListeners();
      }

      if (state.processingState == ProcessingState.completed) {
        _onCompleted();
      }
    });

    _player.positionStream.listen((pos) {
      _position = pos;
      final secs = pos.inSeconds;
      if (secs != _lastPositionSeconds) {
        _lastPositionSeconds = secs;
        notifyListeners();
      }
    });

    _player.durationStream.listen((dur) {
      if (dur != null && _queue.isNotEmpty) {
        _duration = dur;
        // Update duration on the track in both _queue and _tracks so
        // the track list views always show the correct time.
        final qIdx = _curIdx.clamp(0, _queue.length - 1);
        final trackId = _queue[qIdx].id;
        final tIdx = _tracks.indexWhere((t) => t.id == trackId);
        final updated = _queue[qIdx].copyWith(
          duration: _fmt(dur.inSeconds),
          seconds: dur.inSeconds,
        );
        _queue[qIdx] = updated;
        if (tIdx != -1) _tracks[tIdx] = updated;
        notifyListeners();
      }
    });

    _player.currentIndexStream.listen((idx) {
      if (_settingQueue) return; 
      if (idx != null && idx != _curIdx) {
        _curIdx = idx;
        _duration = Duration.zero;
        _position = Duration.zero;

        if (_queue.isNotEmpty) {
          final t = _queue[_curIdx.clamp(0, _queue.length - 1)];
          _recentlyPlayed.remove(t.id);
          _recentlyPlayed.insert(0, t.id);
          if (_recentlyPlayed.length > 20) {
            _recentlyPlayed = _recentlyPlayed.take(20).toList();
          }
          _saveRecentlyPlayed();
        }

        notifyListeners();
      }
    });
  }

  // ── Load tracks from Firestore ────────────────────────────────────────────

  Future<void> loadTracks() async {
    _tracksLoading = true;
    notifyListeners();
    try {
      final q = await _db
          .collection('tracks')
          .orderBy('order', descending: false)
          .get();
      _tracks = q.docs.map((d) => Track.fromFirestore(d.data())).toList();
      _applyLiked(); 

      // Default queue = full library in Firestore order.
      _queue = List.of(_tracks);

      final audioSource = ConcatenatingAudioSource(
        children: _queue
            .map((t) => AudioSource.uri(
                  Uri.parse(t.url ?? ''),
                  tag: MediaItem(
                    id: t.id.toString(),
                    title: t.title,
                    artist: t.artist,
                  ),
                ))
            .toList(),
      );
      await _player.setAudioSource(audioSource, preload: false);

      // Sort once — frozen forever, never re-sorted on playback events.
      _recentlyAdded = [..._tracks]..sort((a, b) {
          if (a.addedAt == null && b.addedAt == null) return b.id.compareTo(a.id);
          if (a.addedAt == null) return 1;
          if (b.addedAt == null) return -1;
          final cmp = b.addedAt!.compareTo(a.addedAt!);
          return cmp != 0 ? cmp : b.id.compareTo(a.id);
        });
    } catch (e) {
      debugPrint('PlayerService: failed to load tracks — $e');
      _tracks = [];
      _queue = [];
    } finally {
      _tracksLoading = false;
      notifyListeners();
    }

    _prefetchMissingDurations();
  }

  // ── Queue management ──────────────────────────────────────────────────────
  Future<void> setQueue(List<Track> tracks, int startIndex) async {
    if (tracks.isEmpty) return;
    _hasActiveSession = true;
    _settingQueue = true;
    _queue = List.of(tracks);
    _curIdx = startIndex.clamp(0, _queue.length - 1);

    final t = _queue[_curIdx];
    _recentlyPlayed.remove(t.id);
    _recentlyPlayed.insert(0, t.id);
    if (_recentlyPlayed.length > 20) {
      _recentlyPlayed = _recentlyPlayed.take(20).toList();
    }
    _saveRecentlyPlayed();

    final audioSource = ConcatenatingAudioSource(
      children: _queue
          .map((t) => AudioSource.uri(
                Uri.parse(t.url ?? ''),
                tag: MediaItem(
                  id: t.id.toString(),
                  title: t.title,
                  artist: t.artist,
                ),
              ))
          .toList(),
    );

    _loading = true;
    notifyListeners();

    try {
      await _player.setAudioSource(audioSource, preload: false);
      await _player.seek(Duration.zero, index: _curIdx);
      _settingQueue = false; 
      await _player.play();
    } catch (_) {
      _settingQueue = false;
      _loading = false;
      notifyListeners();
    }
  }

  // ── Playback ──────────────────────────────────────────────────────────────

  /// Play a track by ID within the current queue context.
  /// Used by home screen cards where the full library is the active queue.
  Future<void> playById(int id) async {
    // If the track is already in the current queue, seek to it there
    // so next/prev stays in context.
    final qIdx = _queue.indexWhere((t) => t.id == id);
    if (qIdx != -1) {
      await _playQueueIndex(qIdx);
      return;
    }
    // Fallback: reset queue to full library and play there.
    final libIdx = _tracks.indexWhere((t) => t.id == id);
    if (libIdx == -1) return;
    await setQueue(_tracks, libIdx);
  }

  Future<void> _playQueueIndex(int idx) async {
    if (_queue.isEmpty) return;
    _hasActiveSession = true;
    _curIdx = idx.clamp(0, _queue.length - 1);
    final t = _queue[_curIdx];
    if (t.url == null) return;
    _loading = true;
    notifyListeners();

    try {
      await _player.seek(Duration.zero, index: _curIdx);
      await _player.play();
    } catch (_) {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> togglePlay() async {
    // If no active session yet, start from the last recently played track.
    if (!_hasActiveSession && _recentlyPlayed.isNotEmpty) {
      final idx = _queue.indexWhere((t) => t.id == _recentlyPlayed.first);
      if (idx != -1) {
        await setQueue(_queue, idx);
        return;
      }
    }
    if (_queue.isEmpty) return;
    if (_player.playing) {
      await _player.pause();
    } else {
      if (_player.processingState == ProcessingState.idle) {
        await _playQueueIndex(_curIdx);
      } else {
        await _player.play();
      }
    }
  }

  Future<void> nextTrack() async => await _player.seekToNext();
  Future<void> prevTrack() async {
    if (_position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    await _player.seekToPrevious();
  }

  Future<void> _loadLiked() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('liked_tracks') ?? [];
    _likedIds = ids.map((e) => int.parse(e)).toSet();
    // Apply to tracks if already loaded, otherwise loadTracks() will apply them
    _applyLiked();
    notifyListeners();
  }

  Future<void> _saveLiked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'liked_tracks',
      _likedIds.map((e) => e.toString()).toList(),
    );
  }

  void _applyLiked() {
    for (var i = 0; i < _tracks.length; i++) {
      _tracks[i] = _tracks[i].copyWith(liked: _likedIds.contains(_tracks[i].id));
    }
  }

  List<int> _getOrder() {
    if (_queue.isEmpty) return [0];
    if (!_shuffle) return List.generate(_queue.length, (i) => i);
    final a = List.generate(_queue.length, (i) => i);
    final rng = Random();
    for (var i = a.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final tmp = a[i];
      a[i] = a[j];
      a[j] = tmp;
    }
    return a;
  }

  List<int> getUpNext() {
    final order = _getOrder();
    final i = order.indexOf(_curIdx);
    return order.skip(i + 1).take(4).toList();
  }

  void _onCompleted() {
    if (_repeat == RepeatMode.one) {
      _player.seek(Duration.zero);
      _player.play();
    } else {
      nextTrack();
    }
  }

  // ── Controls ──────────────────────────────────────────────────────────────

  void toggleShuffle() {
    _shuffle = !_shuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    _repeat = RepeatMode.values[(_repeat.index + 1) % 3];
    notifyListeners();
  }

  void toggleLike(int id) {
    final i = _tracks.indexWhere((t) => t.id == id);
    if (i == -1) return;
    final nowLiked = !_tracks[i].liked;
    _tracks[i] = _tracks[i].copyWith(liked: nowLiked);
    if (nowLiked) {
      _likedIds.add(id);
    } else {
      _likedIds.remove(id);
    }
    final qi = _queue.indexWhere((t) => t.id == id);
    if (qi != -1) _queue[qi] = _tracks[i];
    _saveLiked();
    notifyListeners();
  }

  Future<void> seek(Duration pos) async => await _player.seek(pos);

  Future<void> setVolume(double v) async {
    _volume = v;
    await _player.setVolume(v);
    notifyListeners();
  }

  // ── Playlists ─────────────────────────────────────────────────────────────

  void setPlaylists(List<PlaylistModel> p) {
    _playlists = p;
    notifyListeners();
  }

  void addPlaylist(PlaylistModel p) {
    _playlists.add(p);
    notifyListeners();
  }

  void deletePlaylist(int idx) {
    _playlists.removeAt(idx);
    notifyListeners();
  }

  void addTrackToPlaylist(int plIdx, int trackId) {
    if (!_playlists[plIdx].trackIds.contains(trackId)) {
      _playlists[plIdx].trackIds.add(trackId);
      notifyListeners();
    }
  }

  void updatePlaylist(int idx, {String? name, String? emoji, List<int>? trackIds}) {
    final p = _playlists[idx];
    _playlists[idx] = PlaylistModel(
      name: name ?? p.name,
      emoji: emoji ?? p.emoji,
      trackIds: trackIds ?? p.trackIds,
    );
    notifyListeners();
  }

  void syncLiked(List<int> likedIds) {
    _likedIds = likedIds.toSet();
    _applyLiked();
    _saveLiked();
    notifyListeners();
  }

  // ── Duration prefetch ─────────────────────────────────────────────────────

  Future<void> _prefetchMissingDurations() async {
    final missing = _tracks
        .where((t) =>
            t.url != null &&
            t.url!.isNotEmpty &&
            (t.duration == null || t.duration!.trim().isEmpty))
        .toList();

    if (missing.isEmpty) return;

    final snapshot = await _db.collection('tracks').get();
    final docsByTrackId = {
      for (final doc in snapshot.docs)
        (doc.data()['id'] as num?)?.toInt(): doc.reference
    };

    for (final track in missing) {
      if (_playing) break;

      final idx = _tracks.indexWhere((t) => t.id == track.id);
      if (idx == -1) continue;
      if (_tracks[idx].duration != null &&
          _tracks[idx].duration!.trim().isNotEmpty) continue;

      try {
        final dur = await _player.setAudioSource(
          AudioSource.uri(
            Uri.parse(track.url!),
            tag: MediaItem(
              id: track.id.toString(),
              title: track.title,
              artist: track.artist,
            ),
          ),
        );
        if (dur != null && dur.inSeconds > 0) {
          final formatted = _fmt(dur.inSeconds);
          _tracks[idx] = _tracks[idx].copyWith(
            duration: formatted,
            seconds: dur.inSeconds,
          );
          notifyListeners();

          final ref = docsByTrackId[track.id];
          if (ref != null) {
            await ref.update({'duration': formatted, 'seconds': dur.inSeconds});
            debugPrint('Saved: ${track.title} → $formatted');
          }
        }
      } catch (e) {
        debugPrint('Probe failed for ${track.title}: $e');
      }
    }

    await _player.stop();
  }

  String _fmt(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}