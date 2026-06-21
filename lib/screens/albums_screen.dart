import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/mini_player.dart';
import '../screens/player_screen.dart';
import '../screens/main_shell.dart';

class AlbumsScreen extends StatefulWidget {
  const AlbumsScreen({super.key});

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> {
  String _query = '';
  bool _ascending = true;
  bool _isGrid = true;

  Map<String, List<Track>> _groupAlbums(List<Track> tracks) {
    final map = <String, List<Track>>{};
    for (final t in tracks) {
      final key = t.album ?? 'Unknown Album';
      map.putIfAbsent(key, () => []).add(t);
    }
    return map;
  }

  Map<String, List<Track>> _filtered(List<Track> allTracks) {
    final grouped = _groupAlbums(allTracks);
    final q = _query.trim().toLowerCase();

    Map<String, List<Track>> result;
    if (q.isEmpty) {
      result = grouped;
    } else {
      result = {};
      for (final entry in grouped.entries) {
        final albumMatches = entry.key.toLowerCase().contains(q);
        final matchingTracks = entry.value
            .where((t) => t.title.toLowerCase().contains(q))
            .toList();
        if (albumMatches) {
          result[entry.key] = entry.value;
        } else if (matchingTracks.isNotEmpty) {
          result[entry.key] = matchingTracks;
        }
      }
    }

    final sorted = result.keys.toList()
      ..sort((a, b) => _ascending ? a.compareTo(b) : b.compareTo(a));
    return {for (final k in sorted) k: result[k]!};
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final albums = _filtered(player.tracks);

    return CustomScrollView(
      slivers: [
        // ── Header ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.border))),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.playfairDisplay(
                    fontSize: 26,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.ink),
                children: [
                  const TextSpan(text: 'Al'),
                  TextSpan(
                      text: 'bums',
                      style: GoogleFonts.playfairDisplay(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.ink.withOpacity(0.85))),
                ],
              ),
            ),
          ),
        ),

        // ── Search + Controls ──────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _SearchBar(
              onChanged: (v) => setState(() => _query = v),
              ascending: _ascending,
              onSortToggle: () => setState(() => _ascending = !_ascending),
              isGrid: _isGrid,
              onViewToggle: () => setState(() => _isGrid = !_isGrid),
            ),
          ),
        ),

        // ── Results count ──────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
            child: Text(
              '${albums.length} album${albums.length != 1 ? 's' : ''}',
              style: const TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.2,
                  color: AppTheme.muted,
                  fontFamily: 'JetBrains Mono'),
            ),
          ),
        ),

        // ── Grid View ─────────────────────────────────────────────
        if (_isGrid)
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final name = albums.keys.elementAt(i);
                  final tracks = albums[name]!;
                  final coverUrl = tracks
                      .firstWhere((t) => t.coverUrl != null,
                          orElse: () => tracks.first)
                      .coverUrl;
                  return _AlbumCard(
                    name: name,
                    artist: tracks.first.artist,
                    trackCount: tracks.length,
                    coverUrl: coverUrl,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            AlbumDetailScreen(name: name, tracks: tracks),
                      ),
                    ),
                  );
                },
                childCount: albums.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.82,
              ),
            ),
          ),

        // ── List View ─────────────────────────────────────────────
        if (!_isGrid)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final name = albums.keys.elementAt(i);
                  final tracks = albums[name]!;
                  final coverUrl = tracks
                      .firstWhere((t) => t.coverUrl != null,
                          orElse: () => tracks.first)
                      .coverUrl;
                  return _AlbumListTile(
                    name: name,
                    artist: tracks.first.artist,
                    trackCount: tracks.length,
                    coverUrl: coverUrl,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            AlbumDetailScreen(name: name, tracks: tracks),
                      ),
                    ),
                  );
                },
                childCount: albums.length,
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }
}

// ── Search bar with expandable input ─────────────────────────────

class _SearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final bool ascending;
  final VoidCallback onSortToggle;
  final bool isGrid;
  final VoidCallback onViewToggle;

  const _SearchBar({
    required this.onChanged,
    required this.ascending,
    required this.onSortToggle,
    required this.isGrid,
    required this.onViewToggle,
  });

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late final AnimationController _anim;
  late final Animation<double> _widthFactor;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _widthFactor = CurvedAnimation(parent: _anim, curve: Curves.easeInOut);
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _anim.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_expanded) {
      _focusNode.unfocus();
      _controller.clear();
      widget.onChanged('');
      _anim.reverse().then((_) => setState(() => _expanded = false));
    } else {
      setState(() => _expanded = true);
      _anim.forward().then((_) => _focusNode.requestFocus());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),

        // Animated expanding text field (expands to the LEFT)
        SizeTransition(
          sizeFactor: _widthFactor,
          axis: Axis.horizontal,
          axisAlignment: 1, // anchor to the right edge
          child: Row(
            children: [
              Container(
                width: 180,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.bg2,
                  border: Border.all(color: AppTheme.border, width: 1),
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        onChanged: widget.onChanged,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Albums or songs…',
                          hintStyle: GoogleFonts.inter(
                              fontSize: 12, color: AppTheme.muted),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_controller.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _controller.clear();
                          widget.onChanged('');
                        },
                        child: const Icon(Icons.close_rounded,
                            size: 13, color: AppTheme.muted),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),

        // ── Search button ──────────────────────────────────────────
        _ToolbarBtn(
          tooltip: 'Search',
          onTap: _toggle,
          active: _expanded,
          child:
              const Icon(Icons.search_rounded, size: 16, color: AppTheme.ink),
        ),
        const SizedBox(width: 8),

        // ── Sort button ────────────────────────────────────────────
        _ToolbarBtn(
          tooltip: widget.ascending ? 'A → Z' : 'Z → A',
          onTap: widget.onSortToggle,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 15,
                height: 15,
                child: CustomPaint(
                  painter: _FilterIconPainter(color: AppTheme.ink),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Icon(
                  widget.ascending
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 8,
                  color: AppTheme.ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // ── Grid / List toggle ─────────────────────────────────────
        _ToolbarBtn(
          tooltip: widget.isGrid ? 'List view' : 'Grid view',
          onTap: widget.onViewToggle,
          child: Icon(
            widget.isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
            size: 16,
            color: AppTheme.ink,
          ),
        ),
      ],
    );
  }
}

// ── Toolbar icon button ───────────────────────────────────────────

class _ToolbarBtn extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final String tooltip;
  final bool active;
  const _ToolbarBtn({
    required this.child,
    required this.onTap,
    required this.tooltip,
    this.active = false,
  });

  @override
  State<_ToolbarBtn> createState() => _ToolbarBtnState();
}

class _ToolbarBtnState extends State<_ToolbarBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: widget.active || _pressed ? AppTheme.bg2 : AppTheme.bg,
            border: Border.all(
              color: widget.active ? AppTheme.ink : AppTheme.border,
              width: widget.active ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}

// ── Filter SVG painter ────────────────────────────────────────────

class _FilterIconPainter extends CustomPainter {
  final Color color;
  const _FilterIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 256;
    final hs = size.height / 256;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(34.1 * s, 61.38 * hs);
    path.cubicTo(30 * s, 55 * hs, 34 * s, 48 * hs, 40 * s, 48 * hs);
    path.lineTo(216 * s, 48 * hs);
    path.cubicTo(222 * s, 48 * hs, 226 * s, 55 * hs, 221.92 * s, 61.38 * hs);
    path.lineTo(152 * s, 136 * hs);
    path.lineTo(152 * s, 194.65 * hs);
    path.cubicTo(
        152 * s, 199 * hs, 149.5 * s, 203 * hs, 148.44 * s, 200.65 * hs);
    path.lineTo(116.44 * s, 221.98 * hs);
    path.cubicTo(112 * s, 224.5 * hs, 104 * s, 222 * hs, 104 * s, 216 * hs);
    path.lineTo(104 * s, 136 * hs);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_FilterIconPainter old) => old.color != color;
}

// ── Album list tile (list view) ───────────────────────────────────

class _AlbumListTile extends StatefulWidget {
  final String name, artist;
  final int trackCount;
  final String? coverUrl;
  final VoidCallback onTap;
  const _AlbumListTile(
      {required this.name,
      required this.artist,
      required this.trackCount,
      this.coverUrl,
      required this.onTap});

  @override
  State<_AlbumListTile> createState() => _AlbumListTileState();
}

class _AlbumListTileState extends State<_AlbumListTile> {
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
        margin: const EdgeInsets.only(bottom: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _pressed ? AppTheme.bg2 : AppTheme.bg,
          border: const Border(
              bottom: BorderSide(color: AppTheme.border, width: 1)),
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.border, width: 1),
              ),
              clipBehavior: Clip.antiAlias,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: TrackArt(url: widget.coverUrl, size: 48, dark: true),
              ),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.name,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(
                      '${widget.artist} · ${widget.trackCount} track${widget.trackCount != 1 ? 's' : ''}',
                      style:
                          const TextStyle(fontSize: 10, color: AppTheme.muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
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

// ── ALBUM CARD (grid) ─────────────────────────────────────────────

class _AlbumCard extends StatefulWidget {
  final String name, artist;
  final int trackCount;
  final String? coverUrl;
  final VoidCallback onTap;
  const _AlbumCard(
      {required this.name,
      required this.artist,
      required this.trackCount,
      this.coverUrl,
      required this.onTap});

  @override
  State<_AlbumCard> createState() => _AlbumCardState();
}

class _AlbumCardState extends State<_AlbumCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: _pressed
              ? (Matrix4.identity()..translate(0.0, -2.0))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: AppTheme.bg,
            border: Border.all(color: AppTheme.ink, width: 2),
            borderRadius: BorderRadius.circular(10),
            boxShadow: _pressed
                ? [
                    const BoxShadow(
                        color: AppTheme.ink,
                        offset: Offset(4, 4),
                        blurRadius: 0)
                  ]
                : [],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: TrackArt(
                    url: widget.coverUrl,
                    size: double.infinity as double,
                    dark: true,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.name,
                        style: const TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(
                        '${widget.artist} · ${widget.trackCount} track${widget.trackCount != 1 ? 's' : ''}',
                        style:
                            const TextStyle(fontSize: 9, color: AppTheme.muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

// ── ALBUM DETAIL ──────────────────────────────────────────────────

class AlbumDetailScreen extends StatelessWidget {
  final String name;
  final List<Track> tracks;
  const AlbumDetailScreen(
      {super.key, required this.name, required this.tracks});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final coverUrl = tracks
        .firstWhere((t) => t.coverUrl != null, orElse: () => tracks.first)
        .coverUrl;

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
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: Divider(height: 2, thickness: 2, color: AppTheme.ink),
        ),
      ),
      bottomNavigationBar: const DetailBottomBar(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              decoration: const BoxDecoration(
                color: AppTheme.bg2,
                border:
                    Border(bottom: BorderSide(color: AppTheme.ink, width: 2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.ink, width: 2)),
                    child: TrackArt(url: coverUrl, size: 100, dark: true),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const LabelText('Album'),
                        const SizedBox(height: 6),
                        Text(name,
                            style: const TextStyle(
                                fontFamily: 'PlayfairDisplay',
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.ink)),
                        const SizedBox(height: 4),
                        Text(
                            '${tracks.first.artist} · ${tracks.length} track${tracks.length != 1 ? 's' : ''}',
                            style: const TextStyle(
                                fontSize: 10, color: AppTheme.muted)),
                        const SizedBox(height: 12),
                        _PlayAllBtn(onTap: () => player.setQueue(tracks, 0)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => Column(children: [
                TrackTile(
                  track: tracks[i],
                  displayNum: i + 1,
                  queueContext: tracks,
                ),
                const Divider(height: 1, color: Color(0x12000000)),
              ]),
              childCount: tracks.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

// ── PLAY ALL BUTTON ───────────────────────────────────────────────

class _PlayAllBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _PlayAllBtn({required this.onTap});

  @override
  State<_PlayAllBtn> createState() => _PlayAllBtnState();
}

class _PlayAllBtnState extends State<_PlayAllBtn> {
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _pressed ? AppTheme.dark2 : AppTheme.ink,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 13,
              height: 13,
              child: CustomPaint(painter: _PlayIconPainter()),
            ),
            const SizedBox(width: 7),
            const Text(
              'PLAY ALL',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.5,
                color: Colors.white,
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 256;
    final hs = size.height / 256;
    final path = Path();
    path.moveTo(72 * s, 39.88 * hs);
    path.lineTo(72 * s, 216.12 * hs);
    path.cubicTo(
        72 * s, 220.5 * hs, 74 * s, 223.5 * hs, 84.15 * s, 222.81 * hs);
    path.lineTo(228.23 * s, 134.69 * hs);
    path.cubicTo(
        231.5 * s, 132 * hs, 231.5 * s, 124 * hs, 228.23 * s, 121.31 * hs);
    path.lineTo(84.15 * s, 33.19 * hs);
    path.cubicTo(74 * s, 32.5 * hs, 72 * s, 35.5 * hs, 72 * s, 39.88 * hs);
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_PlayIconPainter old) => false;
}
