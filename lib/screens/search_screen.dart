import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/artist_utils.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _textQuery = '';
  String? _activeTag; // selected genre tag
  int _tabIndex = 0; // 0 = Genres, 1 = Artists

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _isSearching => _textQuery.isNotEmpty || _activeTag != null;

  List<Track> _filtered(List<Track> tracks) {
    return tracks.where((t) {
      final tagMatch = _activeTag == null ||
          t.genre.trim().toLowerCase() == _activeTag!.toLowerCase();
      final textMatch = _textQuery.isEmpty ||
          t.title.toLowerCase().contains(_textQuery) ||
          splitArtists(t.artist)
              .any((a) => a.toLowerCase().contains(_textQuery)) ||
          t.genre.toLowerCase().contains(_textQuery) ||
          t.language.toLowerCase().contains(_textQuery);
      return tagMatch && textMatch;
    }).toList();
  }

  void _setTag(String genre) {
    setState(() => _activeTag = genre);
  }

  void _clearTag() {
    setState(() => _activeTag = null);
  }

  static const _greys = [
    Color(0xFF0A0A0A),
    Color(0xFF222222),
    Color(0xFF333333),
    Color(0xFF444444),
    Color(0xFF555555),
    Color(0xFF666666),
    Color(0xFF777777),
    Color(0xFF888888),
  ];

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();

    final genres = <String>{
      for (final t in player.tracks)
        if (t.genre.trim().isNotEmpty) t.genre.trim()
    }.toList()
      ..sort();

    final artists = uniqueArtists(player.tracks);

    final filtered = _filtered(player.tracks);

    return CustomScrollView(
      slivers: [
        // ── Header ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.border))),
            child: RichText(
              text: TextSpan(
                text: 'Search',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 26,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.ink),
              ),
            ),
          ),
        ),

        // ── Search bar ────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.ink, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.search_rounded,
                        color: AppTheme.muted, size: 18),
                  ),

                  // Tag chip (if active)
                  if (_activeTag != null) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.ink,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _activeTag!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontFamily: 'JetBrains Mono',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: _clearTag,
                            child: const Icon(Icons.close_rounded,
                                size: 12, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Text input
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      onChanged: (v) =>
                          setState(() => _textQuery = v.toLowerCase().trim()),
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: _activeTag != null
                            ? 'Filter within ${_activeTag!}…'
                            : 'Songs, artists, genres…',
                        hintStyle: GoogleFonts.inter(
                            fontSize: 13, color: AppTheme.muted),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),

                  // Clear text button
                  if (_textQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _ctrl.clear();
                        setState(() => _textQuery = '');
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.close_rounded,
                            color: AppTheme.muted, size: 16),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // ── Results count (when searching) ────────────────────────
        if (_isSearching)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Text(
                '${filtered.length} result${filtered.length != 1 ? 's' : ''}',
                style: const TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.2,
                    color: AppTheme.muted,
                    fontFamily: 'JetBrains Mono'),
              ),
            ),
          ),

        // ── Results list (when searching) ─────────────────────────
        if (_isSearching) ...[
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => Column(children: [
                TrackTile(
                  track: filtered[i],
                  displayNum: i + 1,
                  queueContext: filtered,
                ),
                const Divider(height: 1, color: Color(0x12000000)),
              ]),
              childCount: filtered.length,
            ),
          ),
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_off_rounded,
                        size: 36, color: AppTheme.muted),
                    const SizedBox(height: 12),
                    Text('No results',
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.muted)),
                    const SizedBox(height: 6),
                    Text(
                      _activeTag != null && _textQuery.isNotEmpty
                          ? 'Try removing the genre tag or changing your search'
                          : 'Try a different search term',
                      style:
                          const TextStyle(fontSize: 11, color: AppTheme.muted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],

        // ── Browse tabs (when idle) ───────────────────────────────
        if (!_isSearching) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  _TabBtn(
                    label: 'Genres',
                    active: _tabIndex == 0,
                    onTap: () => setState(() => _tabIndex = 0),
                  ),
                  const SizedBox(width: 8),
                  _TabBtn(
                    label: 'Artists',
                    active: _tabIndex == 1,
                    onTap: () => setState(() => _tabIndex = 1),
                  ),
                ],
              ),
            ),
          ),

          // Genres grid
          if (_tabIndex == 0 && genres.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _GenreChip(
                    label: genres[i],
                    color: _greys[i % _greys.length],
                    onTap: () => _setTag(genres[i]),
                  ),
                  childCount: genres.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 3,
                ),
              ),
            ),

          // Artists list
          if (_tabIndex == 1 && artists.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final artist = artists[i];
                    final artistTracks = tracksForArtist(artist, player.tracks);
                    final coverUrl = artistTracks.isNotEmpty
                        ? artistTracks.first.coverUrl
                        : null;
                    return _ArtistRow(
                      name: artist,
                      trackCount: artistTracks.length,
                      coverUrl: coverUrl,
                      onTap: () => setState(() {
                        _activeTag = null;
                        _textQuery = artist.toLowerCase();
                        _ctrl.text = artist;
                      }),
                    );
                  },
                  childCount: artists.length,
                ),
              ),
            ),
          ],
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }
}

// ── Tab button ────────────────────────────────────────────────────

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabBtn(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppTheme.ink : AppTheme.bg,
          border: Border.all(
              color: active ? AppTheme.ink : AppTheme.border, width: 1.5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 1.5,
            fontFamily: 'JetBrains Mono',
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppTheme.muted,
          ),
        ),
      ),
    );
  }
}

// ── Genre chip ────────────────────────────────────────────────────

class _GenreChip extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _GenreChip(
      {required this.label, required this.color, required this.onTap});

  @override
  State<_GenreChip> createState() => _GenreChipState();
}

class _GenreChipState extends State<_GenreChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _pressed ? widget.color.withOpacity(0.75) : widget.color,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label.toUpperCase(),
          style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1.5,
              color: Colors.white,
              fontFamily: 'JetBrains Mono',
              fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ── Artist row ────────────────────────────────────────────────────

class _ArtistRow extends StatefulWidget {
  final String name;
  final int trackCount;
  final String? coverUrl;
  final VoidCallback onTap;
  const _ArtistRow(
      {required this.name,
      required this.trackCount,
      this.coverUrl,
      required this.onTap});

  @override
  State<_ArtistRow> createState() => _ArtistRowState();
}

class _ArtistRowState extends State<_ArtistRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: _pressed ? AppTheme.bg2 : AppTheme.bg,
          border: const Border(
              bottom: BorderSide(color: AppTheme.border, width: 1)),
        ),
        child: Row(
          children: [
            // Circle avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border, width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: widget.coverUrl != null
                  ? TrackArt(url: widget.coverUrl, size: 44)
                  : Container(
                      color: AppTheme.bg2,
                      child: const Icon(Icons.person_rounded,
                          size: 22, color: AppTheme.muted),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.name,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                      '${widget.trackCount} track${widget.trackCount != 1 ? 's' : ''}',
                      style:
                          const TextStyle(fontSize: 10, color: AppTheme.muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppTheme.muted),
          ],
        ),
      ),
    );
  }
}
