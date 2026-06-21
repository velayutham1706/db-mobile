import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/mini_player.dart';
import 'player_screen.dart';
import '../screens/main_shell.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final auth = context.read<AuthService>();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.border))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.ink),
                    children: [
                      const TextSpan(text: 'Your '),
                      TextSpan(
                          text: 'Playlists',
                          style: GoogleFonts.playfairDisplay(
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.ink.withOpacity(0.85))),
                    ],
                  ),
                ),
                InkBtn(
                  label: '+ New',
                  onTap: () {
                    if (!auth.isSignedIn) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Sign in to create playlists')));
                      return;
                    }
                    _showCreateDialog(context, player, auth);
                  },
                ),
              ],
            ),
          ),
        ),
        if (player.playlists.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: CustomPaint(painter: _MusicNotesPlusPainter()),
                  ),
                  const SizedBox(height: 20),
                  const Text('No playlists yet',
                      style: TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink)),
                  const SizedBox(height: 6),
                  const Text('Create your first playlist',
                      style: TextStyle(fontSize: 11, color: AppTheme.muted)),
                  const SizedBox(height: 18),
                  InkBtn(
                    label: '+ Create Playlist',
                    active: true,
                    onTap: () {
                      if (!auth.isSignedIn) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sign in first')));
                        return;
                      }
                      _showCreateDialog(context, player, auth);
                    },
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final p = player.playlists[i];
                  final tracks = p.trackIds
                      .map((id) => player.tracks.firstWhere((t) => t.id == id,
                          orElse: () => player.tracks.first))
                      .toList();
                  return _PlaylistCard(
                    playlist: p,
                    tracks: tracks,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PlaylistDetailScreen(index: i),
                    )),
                  );
                },
                childCount: player.playlists.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.9,
              ),
            ),
          ),
      ],
    );
  }

  void _showCreateDialog(
      BuildContext context, PlayerService player, AuthService auth) {
    showDialog(
        context: context,
        builder: (_) => _CreatePlaylistDialog(player: player, auth: auth));
  }
}

// ── EMPTY STATE SVG PAINTER ───────────────────────────────────────
class _MusicNotesPlusPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 256;
    final sy = size.height / 256;

    final paint = Paint()
      ..color = AppTheme.ink
      ..strokeWidth = 16 * sx
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
        Offset(200 * sx, 24 * sy), Offset(200 * sx, 72 * sy), paint);
    canvas.drawLine(
        Offset(224 * sx, 48 * sy), Offset(176 * sx, 48 * sy), paint);
    canvas.drawCircle(Offset(180 * sx, 164 * sy), 28 * sx, paint);
    canvas.drawCircle(Offset(52 * sx, 196 * sy), 28 * sx, paint);

    final stemPath = Path()
      ..moveTo(80 * sx, 196 * sy)
      ..lineTo(80 * sx, 56 * sy)
      ..lineTo(136 * sx, 42 * sy);
    canvas.drawPath(stemPath, paint);

    canvas.drawLine(
        Offset(208 * sx, 112 * sy), Offset(208 * sx, 164 * sy), paint);
    canvas.drawLine(
        Offset(160 * sx, 84 * sy), Offset(80 * sx, 104 * sy), paint);
  }

  @override
  bool shouldRepaint(_MusicNotesPlusPainter old) => false;
}

// ── PLAYLIST CARD ─────────────────────────────────────────────────
class _PlaylistCard extends StatelessWidget {
  final PlaylistModel playlist;
  final List<Track> tracks;
  final VoidCallback onTap;
  const _PlaylistCard(
      {required this.playlist, required this.tracks, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.ink, width: 2),
            borderRadius: BorderRadius.circular(10),
            color: AppTheme.bg,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  color: AppTheme.dark,
                  alignment: Alignment.center,
                  child: Text(playlist.emoji,
                      style: const TextStyle(fontSize: 40)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(playlist.name,
                        style: const TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(
                        '${tracks.length} track${tracks.length != 1 ? "s" : ""}',
                        style: const TextStyle(
                            fontSize: 9, color: AppTheme.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

// ── PLAYLIST DETAIL ───────────────────────────────────────────────
class PlaylistDetailScreen extends StatefulWidget {
  final int index;
  const PlaylistDetailScreen({super.key, required this.index});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  void _showAddSongsSheet(
      BuildContext context, PlayerService player, PlaylistModel p, int plIdx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (_) => _AddSongsSheet(
        allTracks: player.tracks,
        existingIds: Set<int>.from(p.trackIds),
        onAdd: (selectedIds) {
          for (final id in selectedIds) {
            player.addTrackToPlaylist(plIdx, id);
          }
          context.read<AuthService>().saveUserData(player);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '${selectedIds.length} song${selectedIds.length != 1 ? "s" : ""} added')),
          );
          setState(() {});
        },
      ),
    );
  }

  void _showEditSheet(BuildContext context, PlayerService player,
      PlaylistModel p, int plIdx, List<Track> tracks) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (_) => _EditPlaylistSheet(
        playlist: p,
        tracks: tracks,
        onSave: (name, emoji, reorderedIds) {
          player.updatePlaylist(plIdx,
              name: name, emoji: emoji, trackIds: reorderedIds);
          context.read<AuthService>().saveUserData(player);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Playlist updated')),
          );
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerService>();
    if (widget.index >= player.playlists.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).pop();
      });
      return const SizedBox();
    }
    final p = player.playlists[widget.index];
    final tracks = p.trackIds
        .map((id) => player.tracks
            .firstWhere((t) => t.id == id, orElse: () => player.tracks.first))
        .toList();

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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    color: AppTheme.dark,
                    alignment: Alignment.center,
                    child: Text(p.emoji, style: const TextStyle(fontSize: 34)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name,
                            style: const TextStyle(
                                fontFamily: 'PlayfairDisplay',
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.ink),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(
                            '${tracks.length} track${tracks.length != 1 ? "s" : ""}',
                            style: const TextStyle(
                                fontSize: 10, color: AppTheme.muted)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (tracks.isNotEmpty) ...[
                              _PlayAllBtn(
                                  onTap: () => player.setQueue(tracks, 0)),
                              const SizedBox(width: 8),
                            ],
                            _AddSongsBtn(
                              onTap: () => _showAddSongsSheet(
                                  context, player, p, widget.index),
                            ),
                            const SizedBox(width: 8),
                            _EditBtn(
                              onTap: () => _showEditSheet(
                                  context, player, p, widget.index, tracks),
                            ),
                            const SizedBox(width: 8),
                            _DeleteBtn(
                              onTap: () => showDialog(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero),
                                  title: const Text('Delete playlist?'),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.of(dialogContext).pop(),
                                        child: const Text('Cancel')),
                                    TextButton(
                                      onPressed: () {
                                        final dialogNav =
                                            Navigator.of(dialogContext);
                                        final screenNav = Navigator.of(context);
                                        final messenger =
                                            ScaffoldMessenger.of(context);
                                        final player =
                                            context.read<PlayerService>();
                                        final auth =
                                            context.read<AuthService>();
                                        player.deletePlaylist(widget.index);
                                        auth.saveUserData(player);
                                        dialogNav.pop();
                                        screenNav.pop();
                                        messenger.showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  '${p.name} - Playlist deleted',
                                                  style: GoogleFonts
                                                      .inter())),
                                        );
                                      },
                                      child: const Text('Delete',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (tracks.isEmpty)
            const SliverFillRemaining(
              child: Center(
                  child: Text('No songs yet. Tap + SONGS to add.',
                      style: TextStyle(color: AppTheme.muted))),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Column(
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
  Widget build(BuildContext context) => GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _pressed ? AppTheme.dark2 : AppTheme.ink,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 11,
                height: 11,
                child: CustomPaint(painter: _PlayTrianglePainter()),
              ),
              const SizedBox(width: 6),
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

// ── ADD SONGS BUTTON ──────────────────────────────────────────────
class _AddSongsBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _AddSongsBtn({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.ink),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: SizedBox(
            width: 16,
            height: 16,
            child: CustomPaint(painter: _AddIconPainter()),
          ),
        ),
      );
}

class _AddIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final paint = Paint()
      ..color = AppTheme.ink
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    // horizontal line
    canvas.drawLine(Offset(5 * s, 12 * s), Offset(19 * s, 12 * s), paint);
    // vertical line
    canvas.drawLine(Offset(12 * s, 5 * s), Offset(12 * s, 19 * s), paint);
  }

  @override
  bool shouldRepaint(_AddIconPainter old) => false;
}

// ── EDIT BUTTON ───────────────────────────────────────────────────
class _EditBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _EditBtn({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.ink),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: SizedBox(
            width: 16,
            height: 16,
            child: CustomPaint(painter: _EditIconPainter()),
          ),
        ),
      );
}

class _EditIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final paint = Paint()
      ..color = AppTheme.ink
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // pencil body diagonal
    final path = Path()
      ..moveTo(14.304 * s, 4.844 * s)
      ..relativeLineTo(2.852 * s, 2.852 * s);
    canvas.drawPath(path, paint);

    // document outline + edit lines
    final path2 = Path()
      ..moveTo(7 * s, 7 * s)
      ..lineTo(4 * s, 7 * s)
      ..cubicTo(4 * s, 7 * s, 3 * s, 7 * s, 3 * s, 8 * s)
      ..lineTo(3 * s, 18 * s)
      ..cubicTo(3 * s, 18 * s, 3 * s, 19 * s, 4 * s, 19 * s)
      ..lineTo(15 * s, 19 * s)
      ..cubicTo(15 * s, 19 * s, 16 * s, 19 * s, 16 * s, 18 * s)
      ..lineTo(16 * s, 13.5 * s);
    canvas.drawPath(path2, paint);

    // pencil tip + shaft
    final path3 = Path()
      ..moveTo(17.409 * s, 4.09 * s)
      ..cubicTo(
          17.409 * s, 4.09 * s, 19.426 * s, 6.107 * s, 19.426 * s, 6.943 * s)
      ..lineTo(12.582 * s, 13.787 * s)
      ..lineTo(8 * s, 14 * s)
      ..lineTo(8.713 * s, 10.435 * s)
      ..lineTo(15.557 * s, 3.591 * s)
      ..cubicTo(
          16.15 * s, 2.998 * s, 16.816 * s, 3.497 * s, 17.409 * s, 4.09 * s)
      ..close();
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(_EditIconPainter old) => false;
}

// ── DELETE BUTTON ─────────────────────────────────────────────────
class _DeleteBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _DeleteBtn({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFCC0000)),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: SizedBox(
            width: 16,
            height: 16,
            child: CustomPaint(painter: _DeleteIconPainter()),
          ),
        ),
      );
}

class _DeleteIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final paint = Paint()
      ..color = const Color(0xFFCC0000)
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // top bar
    canvas.drawLine(Offset(5 * s, 7 * s), Offset(19 * s, 7 * s), paint);
    // left inner line
    canvas.drawLine(Offset(10 * s, 10 * s), Offset(10 * s, 18 * s), paint);
    // right inner line
    canvas.drawLine(Offset(14 * s, 10 * s), Offset(14 * s, 18 * s), paint);

    // lid
    final lid = Path()
      ..moveTo(10 * s, 3 * s)
      ..lineTo(14 * s, 3 * s)
      ..cubicTo(14 * s, 3 * s, 15 * s, 3 * s, 15 * s, 4 * s)
      ..lineTo(15 * s, 7 * s)
      ..lineTo(9 * s, 7 * s)
      ..lineTo(9 * s, 4 * s)
      ..cubicTo(9 * s, 4 * s, 9 * s, 3 * s, 10 * s, 3 * s)
      ..close();
    canvas.drawPath(lid, paint);

    // body
    final body = Path()
      ..moveTo(6 * s, 7 * s)
      ..lineTo(18 * s, 7 * s)
      ..lineTo(17 * s, 20 * s)
      ..cubicTo(17 * s, 20 * s, 17 * s, 21 * s, 16 * s, 21 * s)
      ..lineTo(8 * s, 21 * s)
      ..cubicTo(8 * s, 21 * s, 7 * s, 21 * s, 7 * s, 20 * s)
      ..close();
    canvas.drawPath(body, paint);
  }

  @override
  bool shouldRepaint(_DeleteIconPainter old) => false;
}

// ── ADD SONGS SHEET ───────────────────────────────────────────────
class _AddSongsSheet extends StatefulWidget {
  final List<Track> allTracks;
  final Set<int> existingIds;
  final ValueChanged<List<int>> onAdd;
  const _AddSongsSheet({
    required this.allTracks,
    required this.existingIds,
    required this.onAdd,
  });

  @override
  State<_AddSongsSheet> createState() => _AddSongsSheetState();
}

class _AddSongsSheetState extends State<_AddSongsSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  final Set<int> _selected = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Track> get _filtered {
    final q = _query.toLowerCase().trim();
    if (q.isEmpty) return widget.allTracks;
    return widget.allTracks
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.artist.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final canAdd = _selected.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // ── Header ──
          Container(
            color: AppTheme.dark,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selected.isEmpty
                        ? 'Add Songs'
                        : '${_selected.length} selected',
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
                if (canAdd)
                  GestureDetector(
                    onTap: () {
                      widget.onAdd(_selected.toList());
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ADD',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1.5,
                          color: AppTheme.dark,
                          fontFamily: 'JetBrains Mono',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close,
                        color: Colors.white54, size: 20),
                  ),
              ],
            ),
          ),

          // ── Search bar ──
          Container(
            color: AppTheme.bg2,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search songs or artists…',
                hintStyle: const TextStyle(fontSize: 12, color: AppTheme.muted),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 18, color: AppTheme.muted),
                suffixIcon: _query.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                        child: const Icon(Icons.close,
                            size: 16, color: AppTheme.muted),
                      )
                    : null,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.ink, width: 1.5),
                ),
                filled: true,
                fillColor: AppTheme.bg,
              ),
            ),
          ),

          // ── Track list ──
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('No results',
                        style: TextStyle(color: AppTheme.muted, fontSize: 13)),
                  )
                : ListView.builder(
                    controller: scrollCtrl,
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final t = filtered[i];
                      final alreadyIn = widget.existingIds.contains(t.id);
                      final isSelected = _selected.contains(t.id);

                      return GestureDetector(
                        onTap: alreadyIn
                            ? null
                            : () => setState(() {
                                  if (isSelected) {
                                    _selected.remove(t.id);
                                  } else {
                                    _selected.add(t.id);
                                  }
                                }),
                        child: Opacity(
                          opacity: alreadyIn ? 0.4 : 1.0,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.bg3
                                  : Colors.transparent,
                              border: isSelected
                                  ? const Border(
                                      left: BorderSide(
                                          color: AppTheme.ink, width: 3))
                                  : null,
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                // Checkbox
                                SizedBox(
                                  width: 28,
                                  child: alreadyIn
                                      ? const Icon(Icons.check,
                                          size: 14, color: AppTheme.muted)
                                      : AnimatedSwitcher(
                                          duration:
                                              const Duration(milliseconds: 150),
                                          child: isSelected
                                              ? const Icon(
                                                  Icons.check_box_rounded,
                                                  key: ValueKey(true),
                                                  size: 18,
                                                  color: AppTheme.ink)
                                              : const Icon(
                                                  Icons
                                                      .check_box_outline_blank_rounded,
                                                  key: ValueKey(false),
                                                  size: 18,
                                                  color: AppTheme.muted),
                                        ),
                                ),
                                const SizedBox(width: 8),
                                // Art
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: AppTheme.border, width: 1),
                                  ),
                                  child: TrackArt(url: t.coverUrl, size: 36),
                                ),
                                const SizedBox(width: 10),
                                // Title + artist
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(t.title,
                                          style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.ink),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Text(t.artist,
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: AppTheme.muted),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                                // Duration
                                if (t.duration != null &&
                                    t.duration!.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(t.duration!,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.muted,
                                          fontFamily: 'JetBrains Mono')),
                                ],
                                // Already in badge
                                if (alreadyIn) ...[
                                  const SizedBox(width: 8),
                                  const Text('IN LIST',
                                      style: TextStyle(
                                          fontSize: 7,
                                          letterSpacing: 1,
                                          color: AppTheme.muted,
                                          fontFamily: 'JetBrains Mono')),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          const Divider(height: 1, color: AppTheme.border),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── EDIT PLAYLIST SHEET ───────────────────────────────────────────
class _EditPlaylistSheet extends StatefulWidget {
  final PlaylistModel playlist;
  final List<Track> tracks;
  final void Function(String name, String emoji, List<int> reorderedIds) onSave;

  const _EditPlaylistSheet({
    required this.playlist,
    required this.tracks,
    required this.onSave,
  });

  @override
  State<_EditPlaylistSheet> createState() => _EditPlaylistSheetState();
}

class _EditPlaylistSheetState extends State<_EditPlaylistSheet> {
  late final TextEditingController _nameCtrl;
  late String _emoji;
  late List<Track> _tracks;
  final Set<int> _removedIds = {};

  final _emojis = [
    '🎵',
    '🎸',
    '🎹',
    '🎺',
    '🥁',
    '🎷',
    '🎻',
    '🎤',
    '🎧',
    '💿',
    '📀',
    '🎼',
    '🌟',
    '🔥',
    '💫',
    '🌙',
    '❤️',
    '🌊',
    '🍃',
    '⚡',
    '🎭',
    '🏆',
    '🌈',
    '🎯',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.playlist.name);
    _emoji = widget.playlist.emoji;
    _tracks = List.from(widget.tracks);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // ── Header ──
          Container(
            color: AppTheme.dark,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text('Edit Playlist',
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
                GestureDetector(
                  onTap: () {
                    final name = _nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    final finalTracks = _tracks
                        .where((t) => !_removedIds.contains(t.id))
                        .map((t) => t.id)
                        .toList();
                    widget.onSave(name, _emoji, finalTracks);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('SAVE',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1.5,
                          color: AppTheme.dark,
                          fontFamily: 'JetBrains Mono',
                          fontWeight: FontWeight.w700,
                        )),
                  ),
                ),
              ],
            ),
          ),

          // ── Single scrollable: name/emoji header + reorderable songs ──
          Expanded(
            child: ReorderableListView.builder(
              padding: EdgeInsets.zero,
              header: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Name field ──
                    const LabelText('Playlist Name'),
                    const SizedBox(height: 7),
                    TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        hintText: 'Playlist name...',
                        hintStyle: GoogleFonts.jetBrainsMono(fontSize: 13),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: AppTheme.ink, width: 2)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: AppTheme.ink, width: 2)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Emoji picker ──
                    const LabelText('Choose Icon'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: _emojis
                          .map((e) => GestureDetector(
                                onTap: () => setState(() => _emoji = e),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppTheme.bg2,
                                    border: Border.all(
                                        color: _emoji == e
                                            ? AppTheme.ink
                                            : Colors.transparent,
                                        width: 2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(e,
                                      style: const TextStyle(fontSize: 20)),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 20),

                    // ── Reorder songs ──
                    const LabelText('Reorder Songs'),
                    const SizedBox(height: 4),
                    const Text('Hold and drag to reorder',
                        style: TextStyle(fontSize: 10, color: AppTheme.muted)),
                  ],
                ),
              ),
              itemCount: _tracks.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _tracks.removeAt(oldIndex);
                  _tracks.insert(newIndex, item);
                });
              },
              itemBuilder: (context, i) {
                final t = _tracks[i];
                return Container(
                  key: ValueKey(t.id),
                  decoration: BoxDecoration(
                    color: _removedIds.contains(t.id)
                        ? const Color(0x18CC0000)
                        : null,
                    border: const Border(
                        bottom: BorderSide(color: Color(0x12000000), width: 1)),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.drag_handle_rounded,
                          color: AppTheme.muted, size: 20),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 20,
                        child: Text('${i + 1}',
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.muted,
                                fontFamily: 'JetBrains Mono')),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.border)),
                        child: TrackArt(url: t.coverUrl, size: 36),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.title,
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _removedIds.contains(t.id)
                                        ? AppTheme.muted
                                        : AppTheme.ink),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(t.artist,
                                style: const TextStyle(
                                    fontSize: 10, color: AppTheme.muted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          if (_removedIds.contains(t.id)) {
                            _removedIds.remove(t.id);
                          } else {
                            _removedIds.add(t.id);
                          }
                        }),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _removedIds.contains(t.id)
                                  ? AppTheme.muted
                                  : const Color(0xFFCC0000),
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: _removedIds.contains(t.id)
                              ? const Icon(Icons.undo_rounded,
                                  size: 14, color: AppTheme.muted)
                              : CustomPaint(
                                  size: const Size(12, 12),
                                  painter: _RemoveXPainter(),
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1, color: AppTheme.border),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _PlayTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 256;
    final sy = size.height / 256;

    final path = Path()
      ..moveTo(72 * sx, 39.88 * sy)
      ..lineTo(72 * sx, 216.12 * sy)
      ..cubicTo(
          72 * sx, 220.5 * sy, 74 * sx, 223.5 * sy, 84.15 * sx, 222.81 * sy)
      ..lineTo(228.23 * sx, 134.69 * sy)
      ..cubicTo(
          231.5 * sx, 132 * sy, 231.5 * sx, 124 * sy, 228.23 * sx, 121.31 * sy)
      ..lineTo(84.15 * sx, 33.19 * sy)
      ..cubicTo(74 * sx, 32.5 * sy, 72 * sx, 35.5 * sy, 72 * sx, 39.88 * sy)
      ..close();

    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_PlayTrianglePainter old) => false;
}

class _RemoveXPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final paint = Paint()
      ..color = const Color(0xFFCC0000)
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(6 * s, 6 * s), Offset(18 * s, 18 * s), paint);
    canvas.drawLine(Offset(18 * s, 6 * s), Offset(6 * s, 18 * s), paint);
  }

  @override
  bool shouldRepaint(_RemoveXPainter old) => false;
}

// ── CREATE DIALOG ─────────────────────────────────────────────────
class _CreatePlaylistDialog extends StatefulWidget {
  final PlayerService player;
  final AuthService auth;
  const _CreatePlaylistDialog({required this.player, required this.auth});

  @override
  State<_CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends State<_CreatePlaylistDialog> {
  final _nameCtrl = TextEditingController();
  String _emoji = '🎵';

  final _emojis = [
    '🎵',
    '🎸',
    '🎹',
    '🎺',
    '🥁',
    '🎷',
    '🎻',
    '🎤',
    '🎧',
    '💿',
    '📀',
    '🎼',
    '🌟',
    '🔥',
    '💫',
    '🌙',
    '❤️',
    '🌊',
    '🍃',
    '⚡',
    '🎭',
    '🏆',
    '🌈',
    '🎯',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: AppTheme.dark,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text('New Playlist',
                        style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LabelText('Playlist Name'),
                  const SizedBox(height: 7),
                  TextField(
                    controller: _nameCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'My Playlist...',
                      hintStyle: GoogleFonts.jetBrainsMono(fontSize: 13),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppTheme.ink, width: 2)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppTheme.ink, width: 2)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const LabelText('Choose Icon'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: _emojis
                        .map((e) => GestureDetector(
                              onTap: () => setState(() => _emoji = e),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppTheme.bg2,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: _emoji == e
                                          ? AppTheme.ink
                                          : Colors.transparent,
                                      width: 2),
                                ),
                                alignment: Alignment.center,
                                child: Text(e,
                                    style: const TextStyle(fontSize: 20)),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkBtn(
                      label: 'Cancel',
                      onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: 8),
                  InkBtn(
                    label: 'Create',
                    active: true,
                    onTap: () {
                      final name = _nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      widget.player.addPlaylist(PlaylistModel(
                          name: name, emoji: _emoji, trackIds: []));
                      widget.auth.saveUserData(widget.player);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Playlist "$name" created!')));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
