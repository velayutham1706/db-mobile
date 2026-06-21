import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import '../theme/app_theme.dart';
import 'shared.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/player_screen.dart';
import 'dart:ui';

class MiniPlayerBar extends StatefulWidget {
  const MiniPlayerBar({super.key});

  @override
  State<MiniPlayerBar> createState() => _MiniPlayerBarState();
}

class _MiniPlayerBarState extends State<MiniPlayerBar> {
  final GlobalKey _containerKey = GlobalKey();

  void _openPlayer() {
    final RenderBox? box =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    final screen = MediaQuery.of(context).size;
    final origin = box?.localToGlobal(Offset.zero) ?? Offset(10, screen.height - 76);
    final srcSize = box?.size ?? Size(screen.width - 20, 66);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _PlayerExpansion(
        originOffset: origin,
        originSize: srcSize,
        screenSize: screen,
        onDismiss: () => entry.remove(),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final track = player.hasActiveSession
        ? player.currentTrack
        : player.tracks.firstWhere(
            (t) => t.id == player.recentlyPlayed.first,
            orElse: () => player.currentTrack,
          );
    final progress = player.duration.inMilliseconds > 0
        ? player.position.inMilliseconds / player.duration.inMilliseconds
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: GestureDetector(
        onTap: _openPlayer,
        child: Container(
          key: _containerKey,
          height: 66,
          decoration: BoxDecoration(
            color: AppTheme.dark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.ink, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 2,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white12)),
                          child: TrackArt(url: track.coverUrl, size: 40, dark: true),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(track.title,
                                  style: GoogleFonts.inter(
                                      fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(track.artist,
                                  style: const TextStyle(fontSize: 10, color: Colors.white38),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        _MiniBtn(icon: Icons.skip_previous_rounded, onTap: () => player.prevTrack()),
                        const SizedBox(width: 2),
                        _PlayBtn(playing: player.playing, loading: player.loading, onTap: () => player.togglePlay()),
                        const SizedBox(width: 2),
                        _MiniBtn(icon: Icons.skip_next_rounded, onTap: () => player.nextTrack()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MiniBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(icon, color: Colors.white60, size: 22),
        onPressed: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      );
}

class _PlayBtn extends StatelessWidget {
  final bool playing, loading;
  final VoidCallback onTap;
  const _PlayBtn({required this.playing, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 40, height: 40,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Center(
            child: loading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.dark))
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        key: ValueKey(playing), color: AppTheme.dark, size: 22),
                  ),
          ),
        ),
      );
}

class _PlayerExpansion extends StatefulWidget {
  final Offset originOffset;
  final Size originSize;
  final Size screenSize;
  final VoidCallback onDismiss;

  const _PlayerExpansion({
    required this.originOffset,
    required this.originSize,
    required this.screenSize,
    required this.onDismiss,
  });

  @override
  State<_PlayerExpansion> createState() => _PlayerExpansionState();
}

class _PlayerExpansionState extends State<_PlayerExpansion>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progress;
  // For drag-to-dismiss
  double _dragOffset = 0;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 280),
    );
    _progress = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_dismissing) return;
    _dismissing = true;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  void _handleDragUpdate(DragUpdateDetails d) {
    if (d.delta.dy > 0) {
      setState(() => _dragOffset = (_dragOffset + d.delta.dy).clamp(0, 300));
    }
  }

  void _handleDragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (_dragOffset > 120 || v > 600) {
      _dismiss();
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  void _openOverScreen(Widget screen) {
    late OverlayEntry over;
    over = OverlayEntry(
      builder: (_) => screen,
    );
    Overlay.of(context, rootOverlay: true).insert(over);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        final t = _progress.value;
        final dragFraction = (_dragOffset / widget.screenSize.height).clamp(0.0, 1.0);
        final effectiveT = (t - dragFraction).clamp(0.0, 1.0);

        // Interpolate rect from mini player → full screen
        final srcL = widget.originOffset.dx;
        final srcT = widget.originOffset.dy;
        final srcW = widget.originSize.width;
        final srcH = widget.originSize.height;

        final left   = lerpDouble(srcL, 0.0, effectiveT)!;
        final top    = lerpDouble(srcT, 0.0, effectiveT)!;
        final width  = lerpDouble(srcW, widget.screenSize.width, effectiveT)!;
        final height = lerpDouble(srcH, widget.screenSize.height, effectiveT)!;
        final radius = lerpDouble(16.0, 0.0, effectiveT)!;
        final opacity = lerpDouble(0.0, 1.0, (effectiveT * 2).clamp(0.0, 1.0))!;

        return Stack(
          children: [
            // Scrim
            Positioned.fill(
              child: IgnorePointer(
                ignoring: effectiveT < 0.05,
                child: GestureDetector(
                  onTap: _dismiss,
                  child: Container(color: Colors.black.withOpacity(0.4 * effectiveT)),
                ),
              ),
            ),
            // Expanding panel
            Positioned(
              left: left,
              top: top,
              width: width,
              height: height,
              child: GestureDetector(
                onVerticalDragUpdate: _handleDragUpdate,
                onVerticalDragEnd: _handleDragEnd,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: Opacity(
                    opacity: opacity,
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: PlayerScreen(
        onDismiss: _dismiss,
        onOpenScreen: _openOverScreen,
      ),
    );
  }
}