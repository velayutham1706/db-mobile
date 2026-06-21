import 'dart:math';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import '../services/player_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared.dart';
import 'add_to_playlist_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

class PlayerScreen extends StatefulWidget {
  final VoidCallback? onDismiss;
  final void Function(Widget screen)? onOpenScreen;
  const PlayerScreen({super.key, this.onDismiss, this.onOpenScreen});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  late AnimationController _dismissCtrl;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _dismissCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));

    final player = context.read<PlayerService>();
    player.addListener(_onPlayerChange);
  }

  void _onPlayerChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    context.read<PlayerService>().removeListener(_onPlayerChange);
    _dismissCtrl.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (details.delta.dy > 0) {
      setState(() {
        _dragOffset = (_dragOffset + details.delta.dy).clamp(0.0, 300.0);
      });
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_dragOffset > 120 || velocity > 600) {
      _close();
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  void _close() {
    if (widget.onDismiss != null) {
      widget.onDismiss!();
    } else {
      Navigator.of(context).pop();
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final auth = context.read<AuthService>();
    final track = player.hasActiveSession
      ? player.currentTrack
      : (player.recentlyPlayed.isNotEmpty
          ? player.tracks.firstWhere(
              (t) => t.id == player.recentlyPlayed.first,
              orElse: () => player.currentTrack,
            )
          : player.currentTrack);
    final progress = player.duration.inMilliseconds > 0
        ? player.position.inMilliseconds / player.duration.inMilliseconds
        : 0.0;

    final genreLabel = track.genre.trim().isEmpty ? '—' : track.genre;

    final opacity = (1 - (_dragOffset / 300)).clamp(0.0, 1.0);

    return GestureDetector(
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      child: AnimatedBuilder(
        animation: _dismissCtrl,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, _dragOffset),
          child: Opacity(
            opacity: opacity,
            child: child,
          ),
        ),
        child: Scaffold(
          backgroundColor: AppTheme.dark,
          body: SafeArea(
            child: Column(
              children: [
                // ── Drag handle ──
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 4),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // ── Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: Colors.white60, size: 28),
                        onPressed: () => _close(),
                      ),
                      const Spacer(),
                      Text('Now Playing', style: GoogleFonts.inter(color: Color.fromARGB(255, 224, 224, 224))),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // ── Art with radiating lines ──
                Expanded(
                  flex: 4,
                  child: Center(
                    child: _ArtWithPulse(
                      playing: player.playing,
                      coverUrl: track.coverUrl,
                    ),
                  ),
                ),

                // ── Info + like ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(track.title,
                                style: GoogleFonts.inter(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1.2),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text('${track.artist} · $genreLabel',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white38,
                                    letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          player.toggleLike(track.id);
                          if (auth.isSignedIn) auth.saveUserData(player);
                        },
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: Icon(
                            track.liked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            key: ValueKey(track.liked),
                            size: 26,
                            color: track.liked
                                ? const Color(0xFFE53935)
                                : Colors.white60,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Seek bar ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _WaveSeekBar(
                        progress: progress,
                        onSeek: (v) => player.seek(Duration(
                            milliseconds:
                                (v * player.duration.inMilliseconds).round())),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_fmt(player.position),
                              style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.white38,
                                  fontFamily: 'JetBrains Mono')),
                          Text(_fmt(player.duration),
                              style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.white38,
                                  fontFamily: 'JetBrains Mono')),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Playback controls ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ControlBtn(
                        icon: Icons.shuffle_rounded,
                        active: player.shuffle,
                        onTap: () => player.toggleShuffle(),
                      ),
                      _ControlBtn(
                          icon: Icons.skip_previous_rounded,
                          size: 30,
                          onTap: () => player.prevTrack()),
                      _BigPlayBtn(
                          playing: player.playing,
                          loading: player.loading,
                          onTap: () => player.togglePlay()),
                      _ControlBtn(
                          icon: Icons.skip_next_rounded,
                          size: 30,
                          onTap: () => player.nextTrack()),
                      _ControlBtn(
                        icon: player.repeat == RepeatMode.one
                            ? Icons.repeat_one_rounded
                            : Icons.repeat_rounded,
                        active: player.repeat != RepeatMode.off,
                        onTap: () => player.toggleRepeat(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Volume ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Row(
                    children: [
                      const Icon(Icons.volume_down_rounded,
                          color: Colors.white24, size: 18),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 5),
                            trackHeight: 1,
                            overlayShape: SliderComponentShape.noOverlay,
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.white12,
                            thumbColor: Colors.white,
                          ),
                          child: Slider(
                              value: player.volume,
                              onChanged: (v) => player.setVolume(v)),
                        ),
                      ),
                      const Icon(Icons.volume_up_rounded,
                          color: Colors.white24, size: 18),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Action buttons ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          label: '+ Playlist',
                          onTap: () {
                            if (!auth.isSignedIn) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Sign in to create playlists')));
                              return;
                            }
                            if (widget.onOpenScreen != null) {
                              late OverlayEntry entry;
                              entry = OverlayEntry(
                                builder: (_) => Material(
                                  color: Colors.transparent,
                                  child: AddToPlaylistScreen(
                                    trackId: track.id,
                                    onClose: () => entry.remove(),
                                    overlayContext: context,
                                    onDismissPlayer: widget.onDismiss,
                                  ),
                                ),
                              );
                              Overlay.of(context, rootOverlay: true).insert(entry);
                            } else {
                              Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
                                builder: (_) => AddToPlaylistScreen(trackId: track.id),
                              ));
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionBtn(
                          label: 'Share',
                          icon: const ShareIcon(
                              color: Colors.white60, size: 14),
                          onTap: () {
                            final text = '${track.title} by ${track.artist}\n${track.url ?? ''}';
                            Share.share(text);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── ART WITH RADIATING LINES ──────────────────────────────────────
class _ArtWithPulse extends StatefulWidget {
  final bool playing;
  final String? coverUrl;

  const _ArtWithPulse({
    required this.playing,
    this.coverUrl,
  });

  @override
  State<_ArtWithPulse> createState() => _ArtWithPulseState();
}

class _ArtWithPulseState extends State<_ArtWithPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late final DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.playing) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(_ArtWithPulse old) {
    super.didUpdateWidget(old);
    if (widget.playing && !_ctrl.isAnimating) {
      _ctrl.repeat();
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
  Widget build(BuildContext context) {
    final art = Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: TrackArt(url: widget.coverUrl, size: 180, dark: true),
    );

    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.playing)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) {
                  // Use real elapsed seconds — never snaps on controller wrap
                  final elapsed = DateTime.now()
                          .difference(_startTime)
                          .inMilliseconds /
                      1000.0;
                  return CustomPaint(
                    isComplex: true,
                    willChange: true,
                    painter: _RadiatingLinesPainter(elapsed),
                  );
                },
              ),
            ),
          art,
        ],
      ),
    );
  }
}

// ── RADIATING LINES PAINTER ───────────────────────────────────────
class _RadiatingLinesPainter extends CustomPainter {
  final double elapsed; // real seconds, always increasing — no wrap snap
  static const int _numLines = 24;

  // Pre-computed per-line speeds (cycles/sec) and phases using
  // prime-number arithmetic so no two lines ever sync up
  static final List<double> _speeds = List.generate(
    _numLines,
    (i) => 0.4 + (i * 7 + 13) % 17 / 17.0 * 1.2,
  );
  static final List<double> _phases = List.generate(
    _numLines,
    (i) => (i * 11 + 5) % 23 / 23.0 * 2 * pi,
  );

  _RadiatingLinesPainter(this.elapsed);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const baseRadius = 95.0;
    const minLen = 4.0;
    const maxLen = 22.0;

    for (int i = 0; i < _numLines; i++) {
      final angle = (i / _numLines) * 2 * pi;
      final cosA = cos(angle);
      final sinA = sin(angle);

      // Skip corner dead-zones of the square art
      if (cosA.abs() > 0.62 && sinA.abs() > 0.62) continue;

      // Each line independently oscillates via its own sin wave
      final sine = sin(elapsed * 2 * pi * _speeds[i] + _phases[i]);
      final lineLen = minLen + (sine + 1) / 2 * (maxLen - minLen);

      // Opacity pulses independently, out of phase with length
      final opacitySine =
          sin(elapsed * 2 * pi * _speeds[i] + _phases[i] + pi / 3);
      final opacity = 0.2 + (opacitySine + 1) / 2 * 0.55;

      final paint = Paint()
        ..color = Colors.white.withOpacity(opacity)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      final x1 = cx + cosA * baseRadius;
      final y1 = cy + sinA * baseRadius;
      final x2 = cx + cosA * (baseRadius + lineLen);
      final y2 = cy + sinA * (baseRadius + lineLen);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(_RadiatingLinesPainter old) => old.elapsed != elapsed;
}

// ── WAVE SEEK BAR ─────────────────────────────────────────────────
class _WaveSeekBar extends StatelessWidget {
  final double progress;
  final ValueChanged<double> onSeek;
  const _WaveSeekBar({required this.progress, required this.onSeek});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (d) {
        final box = context.findRenderObject() as RenderBox;
        onSeek((d.localPosition.dx / box.size.width).clamp(0.0, 1.0));
      },
      child: SizedBox(
        height: 32,
        width: double.infinity,
        child: CustomPaint(
          painter: _WavePainter(progress),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final List<double> _heights;

  _WavePainter(this.progress) : _heights = _buildHeights();

  static List<double> _buildHeights() {
    final rng = Random(42);
    return List.generate(50, (_) => 0.2 + rng.nextDouble() * 0.8);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final count = _heights.length;
    const totalGapFraction = 0.4;
    final barW = (size.width * (1 - totalGapFraction)) / count;
    final gap = (size.width * totalGapFraction) / count;

    final passed = Paint()..color = Colors.white.withOpacity(0.85);
    final upcoming = Paint()..color = Colors.white.withOpacity(0.18);
    final radius = Radius.circular(barW / 2);

    for (var i = 0; i < count; i++) {
      final x = i * (barW + gap);
      final h = (_heights[i] * size.height).clamp(2.0, size.height);
      final y = (size.height - h) / 2;
      final isPassed = (i / count) < progress;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, barW.clamp(1.0, 20.0), h), radius),
        isPassed ? passed : upcoming,
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.progress != progress;
}

// ── BUTTONS ───────────────────────────────────────────────────────
class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final double size;
  const _ControlBtn(
      {required this.icon,
      required this.onTap,
      this.active = false,
      this.size = 24});

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(icon,
            color: active ? Colors.white : Colors.white38, size: size),
        onPressed: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      );
}

class _BigPlayBtn extends StatelessWidget {
  final bool playing, loading;
  final VoidCallback onTap;
  const _BigPlayBtn(
      {required this.playing,
      required this.loading,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
              color: Colors.white, shape: BoxShape.circle),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: AppTheme.dark))
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        key: ValueKey(playing),
                        color: AppTheme.dark,
                        size: 30),
                  ),
          ),
        ),
      );
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Widget? icon;
  const _ActionBtn({required this.label, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white12),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 6)],
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.5,
                      color: Colors.white60,
                      fontFamily: 'JetBrains Mono')),
            ],
          ),
        ),
      );
}