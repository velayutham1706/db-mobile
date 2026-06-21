import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/add_to_playlist_screen.dart';

// ── BASE64 IMAGE CACHE ───────────────────────────────────────────
final _base64Cache = <String, Uint8List>{};

Uint8List? _decodeBase64(String dataUrl) {
  if (_base64Cache.containsKey(dataUrl)) return _base64Cache[dataUrl];
  try {
    final comma = dataUrl.indexOf(',');
    if (comma == -1) return null;
    final bytes = base64Decode(dataUrl.substring(comma + 1));
    _base64Cache[dataUrl] = bytes;
    return bytes;
  } catch (_) {
    return null;
  }
}

// ── TRACK ART ────────────────────────────────────────────────────
class TrackArt extends StatelessWidget {
  final String? url;
  final double size;
  final bool dark;
  const TrackArt({super.key, this.url, this.size = 40, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final bg = dark ? AppTheme.dark2 : AppTheme.bg2;
    final iconColor = dark ? Colors.white24 : AppTheme.muted;

    Widget fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(child: MusicNoteIcon(size: size * 0.45, color: iconColor)),
    );

    if (url == null || url!.isEmpty) return fallback;

    if (url!.startsWith('data:')) {
      final bytes = _decodeBase64(url!);
      if (bytes == null) return fallback;
      return SizedBox(
          width: size,
          height: size,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.memory(bytes,
                fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback),
          ));
    }

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CachedNetworkImage(
          imageUrl: url!,
          fit: BoxFit.cover,
          placeholder: (_, __) => fallback,
          errorWidget: (_, __, ___) => fallback,
        ),
      ),
    );
  }
}

// ── MUSIC NOTE ICON ──────────────────────────────────────────────
class MusicNoteIcon extends StatelessWidget {
  final double size;
  final Color color;
  const MusicNoteIcon({super.key, this.size = 24, this.color = AppTheme.muted});

  @override
  Widget build(BuildContext context) =>
      Icon(Icons.music_note_rounded, size: size, color: color);
}

// ── GENRE CHIP ───────────────────────────────────────────────────
class GenreChip extends StatelessWidget {
  final String label;
  final bool compact;
  const GenreChip({super.key, required this.label, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final display = label.trim().isEmpty ? '—' : label.toUpperCase();
    return Container(
      width: compact ? double.infinity : null,
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 4, vertical: 3)
          : const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        display,
        style: const TextStyle(
            fontSize: 8,
            letterSpacing: 1,
            color: AppTheme.ink,
            fontFamily: 'JetBrains Mono'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── SHARE ICON ───────────────────────────────────────────────────
class ShareIcon extends StatelessWidget {
  final Color color;
  final double size;
  const ShareIcon({super.key, this.color = AppTheme.muted, this.size = 18});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _ShareIconPainter(color)),
      );
}

class _ShareIconPainter extends CustomPainter {
  final Color color;
  _ShareIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..strokeWidth = w * 0.065
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(
        Path()
          ..moveTo(w * 176 / 256, h * 152 / 256)
          ..lineTo(w * 224 / 256, h * 104 / 256)
          ..lineTo(w * 176 / 256, h * 56 / 256),
        paint);
    canvas.drawPath(
        Path()
          ..moveTo(w * 192 / 256, h * 216 / 256)
          ..lineTo(w * 32 / 256, h * 216 / 256)
          ..lineTo(w * 32 / 256, h * 88 / 256),
        paint);
    canvas.drawPath(
        Path()
          ..moveTo(w * 72 / 256, h * 176 / 256)
          ..cubicTo(w * 72 / 256, h * 120 / 256, w * 120 / 256, h * 104 / 256,
              w * 165 / 256, h * 104 / 256)
          ..lineTo(w * 224 / 256, h * 104 / 256),
        paint);
  }

  @override
  bool shouldRepaint(_ShareIconPainter old) => old.color != color;
}

class PlaylistAddIcon extends StatelessWidget {
  final Color color;
  final double size;
  const PlaylistAddIcon(
      {super.key, this.color = AppTheme.muted, this.size = 18});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _PlaylistAddIconPainter(color)),
      );
}

class _PlaylistAddIconPainter extends CustomPainter {
  final Color color;
  _PlaylistAddIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 256;
    final sy = size.height / 256;
    double x(double v) => v * sx;
    double y(double v) => v * sy;

    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.0625
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(x(40), y(64)), Offset(x(216), y(64)), paint);
    canvas.drawLine(Offset(x(40), y(128)), Offset(x(160), y(128)), paint);
    canvas.drawLine(Offset(x(40), y(192)), Offset(x(112), y(192)), paint);

    canvas.drawCircle(Offset(x(176), y(192)), x(24), paint);

    canvas.drawPath(
        Path()
          ..moveTo(x(200), y(192))
          ..lineTo(x(200), y(112))
          ..lineTo(x(240), y(124)),
        paint);
  }

  @override
  bool shouldRepaint(_PlaylistAddIconPainter old) => old.color != color;
}

// ── HEART ICON ───────────────────────────────────────────────────
class HeartIcon extends StatelessWidget {
  final bool liked;
  final double size;
  final bool inPlayer;

  const HeartIcon({
    super.key,
    required this.liked,
    this.size = 18,
    this.inPlayer = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color fillColor;
    final Color strokeColor;

    if (inPlayer) {
      fillColor = liked ? const Color(0xFFE53935) : Colors.transparent;
      strokeColor = liked ? const Color(0xFFE53935) : Colors.white60;
    } else {
      fillColor = liked ? AppTheme.ink : Colors.transparent;
      strokeColor = liked ? AppTheme.ink : AppTheme.border;
    }

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HeartPainter(fillColor: fillColor, strokeColor: strokeColor),
      ),
    );
  }
}

class _HeartPainter extends CustomPainter {
  final Color fillColor;
  final Color strokeColor;

  const _HeartPainter({required this.fillColor, required this.strokeColor});

  Path _buildPath(Size size) {
    final sx = size.width / 256;
    final sy = size.height / 256;
    double x(double v) => v * sx;
    double y(double v) => v * sy;

    return Path()
      ..moveTo(x(128), y(224))
      ..cubicTo(x(168), y(208), x(220), y(176), x(217.36), y(133.36))
      ..cubicTo(x(215), y(100), x(196), y(68), x(178), y(62.64))
      ..cubicTo(x(160), y(55), x(140), y(62), x(128), y(80))
      ..cubicTo(x(116), y(62), x(96), y(55), x(78), y(62.64))
      ..cubicTo(x(60), y(68), x(41), y(100), x(38.64), y(133.36))
      ..cubicTo(x(36), y(176), x(88), y(208), x(128), y(224))
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);

    if (fillColor != Colors.transparent) {
      canvas.drawPath(path, Paint()..color = fillColor);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = strokeColor
        ..strokeWidth = size.width * 0.09
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_HeartPainter old) =>
      old.fillColor != fillColor || old.strokeColor != strokeColor;
}

// ── TRACK TILE ───────────────────────────────────────────────────
// [queueContext]: when provided, tapping uses setQueue so next/prev
// navigates within that list. When null, falls back to playById which
// seeks within whatever queue is already active.
class TrackTile extends StatelessWidget {
  final Track track;
  final int displayNum;
  final VoidCallback? onTap;
  final bool showBorder;

  /// Pass the full ordered list this tile belongs to so that tapping it
  /// sets the correct queue for next/prev. When omitted the fallback
  /// is playById, which seeks within the already-active queue.
  final List<Track>? queueContext;

  const TrackTile({
    super.key,
    required this.track,
    required this.displayNum,
    this.onTap,
    this.showBorder = true,
    this.queueContext,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<PlayerService, (int, bool)>(
      selector: (_, p) => (p.currentTrack.id, p.playing),
      builder: (context, state, _) {
        final isPlaying = state.$1 == track.id;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isPlaying ? AppTheme.bg3 : Colors.transparent,
            border: isPlaying
                ? const Border(left: BorderSide(color: AppTheme.ink, width: 3))
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap ?? _defaultOnTap(context),
              splashColor: Colors.transparent,
              highlightColor: AppTheme.bg3,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: isPlaying
                          ? _PlayingBars(playing: state.$2)
                          : Text('$displayNum',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.muted,
                                  fontFamily: 'JetBrains Mono')),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.border, width: 1)),
                      child: TrackArt(url: track.coverUrl, size: 36),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(track.title,
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.ink),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(track.artist,
                              style: const TextStyle(
                                  fontSize: 10, color: AppTheme.muted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      child: track.genre.trim().isEmpty
                          ? const SizedBox.shrink()
                          : GenreChip(label: track.genre, compact: true),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (ctx) => AddToPlaylistScreen(
                          trackId: track.id,
                          onClose: () => Navigator.of(ctx).pop(),
                        ),
                      )),
                      child: SizedBox(
                        width: 36,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child:
                              PlaylistAddIcon(size: 16, color: AppTheme.muted),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _LikeButton(trackId: track.id),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds the default tap handler.
  VoidCallback _defaultOnTap(BuildContext context) {
    final player = context.read<PlayerService>();
    if (queueContext != null) {
      return () {
        final idx = queueContext!.indexWhere((t) => t.id == track.id);
        if (idx == -1) return;
        player.setQueue(queueContext!, idx);
      };
    }
    return () => player.playById(track.id);
  }
}

// ── LIKE BUTTON ───────────────────────────────────────────────────
class _LikeButton extends StatelessWidget {
  final int trackId;
  const _LikeButton({required this.trackId});

  @override
  Widget build(BuildContext context) {
    return Selector<PlayerService, bool>(
      selector: (_, p) => p.tracks.firstWhere((t) => t.id == trackId).liked,
      builder: (context, liked, _) => GestureDetector(
        onTap: () => context.read<PlayerService>().toggleLike(trackId),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Icon(
            liked ? Icons.favorite : Icons.favorite_border_rounded,
            key: ValueKey(liked),
            size: 18,
            color: liked ? AppTheme.ink : AppTheme.muted,
          ),
        ),
      ),
    );
  }
}

// ── ANIMATED PLAYING BARS ─────────────────────────────────────────
class _PlayingBars extends StatefulWidget {
  final bool playing;
  const _PlayingBars({required this.playing});

  @override
  State<_PlayingBars> createState() => _PlayingBarsState();
}

class _PlayingBarsState extends State<_PlayingBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    if (widget.playing) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PlayingBars old) {
    super.didUpdateWidget(old);
    if (widget.playing && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.playing && _ctrl.isAnimating) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final anim = Tween<double>(begin: 3, end: 10).animate(
              CurvedAnimation(
                  parent: _ctrl,
                  curve: Interval(i * 0.2, 1.0, curve: Curves.easeInOut)),
            );
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Container(
                width: 2,
                height: anim.value,
                decoration: BoxDecoration(
                    color: AppTheme.ink,
                    borderRadius: BorderRadius.circular(1)),
              ),
            );
          }),
        ),
      );
}

// ── LABEL TEXT ───────────────────────────────────────────────────
class LabelText extends StatelessWidget {
  final String text;
  final Color? color;
  const LabelText(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
            fontSize: 8,
            letterSpacing: 3,
            color: color ?? AppTheme.muted,
            fontFamily: 'JetBrains Mono'),
      );
}

// ── INK BUTTON ───────────────────────────────────────────────────
class InkBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool active;
  final Color? borderColor;

  const InkBtn(
      {super.key,
      required this.label,
      required this.onTap,
      this.active = false,
      this.borderColor});

  @override
  Widget build(BuildContext context) {
    final bg = active ? AppTheme.ink : Colors.transparent;
    final fg = active ? AppTheme.bg : AppTheme.ink;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(
              color: borderColor ?? (active ? AppTheme.ink : AppTheme.border)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.5,
                color: fg,
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.w500)),
      ),
    );
  }
}
