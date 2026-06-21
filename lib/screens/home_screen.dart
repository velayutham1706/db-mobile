import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/mini_player.dart';
import '../screens/player_screen.dart';
import '../screens/main_shell.dart';
import '../utils/artist_utils.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();

    if (player.tracksLoading) {
      return const CustomScrollView(
        slivers: [
          SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (player.tracks.isEmpty) {
      return const CustomScrollView(
        slivers: [
          SliverFillRemaining(
            child: Center(
              child: Text('No tracks found.',
                  style: TextStyle(color: AppTheme.muted)),
            ),
          ),
        ],
      );
    }

    // Jump Back In — last 5 played. Uses full library as queue context
    // so next/prev stays in the full library after tapping here.
    final recentTracks = player.recentlyPlayed
        .map((id) => player.tracks.where((t) => t.id == id).firstOrNull)
        .whereType<Track>()
        .take(5)
        .toList();

    // Pre-sorted in PlayerService — never affected by playback rebuilds.
    final recentlyAdded = player.recentlyAdded;

    // Artists — unique, sorted alphabetically.
    final artists = uniqueArtists(player.tracks);

    // Languages — unique, sorted alphabetically, non-empty only.
    final languages = player.tracks
        .map((t) => t.language.trim())
        .where((l) => l.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return CustomScrollView(
      slivers: [
        // ── Header ────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.border))),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.playfairDisplay(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.ink),
                children: [
                  const TextSpan(text: 'For '),
                  TextSpan(
                    text: 'You',
                    style: GoogleFonts.playfairDisplay(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.ink.withOpacity(0.85)),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Jump Back In — queue = full library ───────────────────────────
        if (recentTracks.isNotEmpty) ...[
          const _SectionLabel(title: 'Jump Back In'),
          SliverToBoxAdapter(
            child: _HorizontalTrackScroll(
              tracks: recentTracks,
              // Queue context: full library so next/prev roams freely.
              queueContext: player.tracks,
            ),
          ),
        ],

        // ── Recently Added — queue = recentlyAdded order ─────────────────
        _SectionHeader(title: 'Recently Added', tracks: recentlyAdded),
        SliverToBoxAdapter(
          child: _HorizontalTrackScroll(
            tracks: recentlyAdded.take(10).toList(),
            queueContext: recentlyAdded,
          ),
        ),

        // ── Artists ───────────────────────────────────────────────────────
        if (artists.isNotEmpty) ...[
          const _SectionLabel(title: 'Artists'),
          SliverToBoxAdapter(
            child: _ArtistScroll(artists: artists, allTracks: player.tracks),
          ),
        ],

        // ── Languages — each language is its own queue ────────────────────
        if (languages.isNotEmpty)
          for (final lang in languages) ...[
            _SectionHeader(
              title: lang,
              tracks: player.tracks
                  .where((t) => t.language.trim() == lang)
                  .toList(),
            ),
            SliverToBoxAdapter(
              child: _HorizontalTrackScroll(
                tracks: player.tracks
                    .where((t) => t.language.trim() == lang)
                    .take(10)
                    .toList(),
                queueContext: player.tracks
                    .where((t) => t.language.trim() == lang)
                    .toList(),
              ),
            ),
          ],

        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }
}

// ── Section label — no View All ──────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
        child: Text(title,
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink)),
      ),
    );
  }
}

// ── Section header — with View All ───────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final List<Track> tracks;
  const _SectionHeader({required this.title, required this.tracks});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink)),
            GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => _TrackListScreen(title: title, tracks: tracks),
              )),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.border, width: 1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('VIEW ALL',
                    style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.5,
                        color: AppTheme.muted,
                        fontFamily: 'JetBrains Mono')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Horizontal track cards ────────────────────────────────────────────────────
// [queueContext] is the full ordered list that next/prev will navigate.
// [tracks] is what's visible in this scroll view (may be a .take(10) slice).
// When the user taps a card we pass the full queueContext to setQueue so
// next/prev covers the whole section, not just the visible 10.

class _HorizontalTrackScroll extends StatelessWidget {
  final List<Track> tracks;
  final List<Track> queueContext;
  const _HorizontalTrackScroll(
      {required this.tracks, required this.queueContext});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) => n.depth == 0,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: tracks.length,
          itemBuilder: (context, i) => _TrackCard(
            track: tracks[i],
            queueContext: queueContext,
          ),
        ),
      ),
    );
  }
}

class _TrackCard extends StatelessWidget {
  final Track track;
  final List<Track> queueContext;
  const _TrackCard({required this.track, required this.queueContext});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final idx = queueContext.indexWhere((t) => t.id == track.id);
        if (idx == -1) return;
        context.read<PlayerService>().setQueue(queueContext, idx);
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 120,
              height: 110,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: TrackArt(url: track.coverUrl, size: 120),
              ),
            ),
            const SizedBox(height: 6),
            Text(track.title,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(track.artist,
                style: const TextStyle(fontSize: 9, color: AppTheme.muted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ── Artists horizontal scroll (circular chips) ────────────────────────────────

class _ArtistScroll extends StatelessWidget {
  final List<String> artists;
  final List<Track> allTracks;
  const _ArtistScroll({required this.artists, required this.allTracks});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) => n.depth == 0,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: artists.length,
          itemBuilder: (context, i) {
            final artist = artists[i];
            final artistTracks = tracksForArtist(artist, allTracks);
            final coverUrl =
                artistTracks.isNotEmpty ? artistTracks.first.coverUrl : null;
            return _ArtistChip(
              name: artist,
              coverUrl: coverUrl,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    _TrackListScreen(title: artist, tracks: artistTracks),
              )),
            );
          },
        ),
      ),
    );
  }
}

class _ArtistChip extends StatelessWidget {
  final String name;
  final String? coverUrl;
  final VoidCallback onTap;
  const _ArtistChip(
      {required this.name, required this.coverUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border, width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: coverUrl != null
                  ? TrackArt(url: coverUrl, size: 56)
                  : Container(
                      color: AppTheme.bg2,
                      child: const Icon(Icons.person_rounded,
                          size: 28, color: AppTheme.muted),
                    ),
            ),
            const SizedBox(height: 6),
            Text(name,
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ── Detail screen — View All / Artist / Language ──────────────────────────────
// The [tracks] list IS the queue for this screen. Tapping any row calls
// setQueue with the full list and that track's index, so next/prev stays
// within this filtered view.

class _TrackListScreen extends StatelessWidget {
  final String title;
  final List<Track> tracks;
  const _TrackListScreen({required this.title, required this.tracks});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.ink, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(title,
            style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
                letterSpacing: 0)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: Divider(height: 2, thickness: 2, color: AppTheme.ink),
        ),
      ),
      bottomNavigationBar: const DetailBottomBar(),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: AppTheme.bg2,
            child: const Row(
              children: [
                SizedBox(width: 28),
                SizedBox(width: 8),
                SizedBox(width: 36),
                SizedBox(width: 10),
                Expanded(child: LabelText('Title')),
                SizedBox(width: 8),
                SizedBox(width: 60, child: LabelText('Genre')),
                SizedBox(width: 4),
                SizedBox(width: 28),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tracks.length,
              itemBuilder: (context, i) => Column(
                key: ValueKey(tracks[i].id),
                children: [
                  TrackTile(
                    track: tracks[i],
                    displayNum: i + 1,
                    queueContext: tracks,
                  ),
                  const Divider(height: 1, color: Color(0x12000000)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
