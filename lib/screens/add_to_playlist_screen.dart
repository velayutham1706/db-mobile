import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared.dart';
import 'package:google_fonts/google_fonts.dart';

class AddToPlaylistScreen extends StatelessWidget {
  final int trackId;
  final VoidCallback? onClose;
  final BuildContext? overlayContext;
  final VoidCallback? onDismissPlayer;
  const AddToPlaylistScreen({
    super.key,
    required this.trackId,
    this.onClose,
    this.overlayContext,
    this.onDismissPlayer,
  });

  void _openCreateDialog(BuildContext context, PlayerService player, AuthService auth) {
    onClose?.call();
    onDismissPlayer?.call();
    showDialog(
      context: overlayContext ?? context,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: player),
          ChangeNotifierProvider.value(value: auth),
        ],
        child: _CreatePlaylistDialogLocal(player: player, auth: auth, trackId: trackId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final auth = context.read<AuthService>();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(8, 48, 16, 16),
            decoration: const BoxDecoration(
              color: AppTheme.bg,
              border: Border(bottom: BorderSide(color: AppTheme.ink, width: 2)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.ink),
                  onPressed: () => onClose?.call(),
                ),
                Expanded(
                  child: Text('Add to Playlist',
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.ink)),
                ),
                InkBtn(
                  label: '+ NEW',
                  active: true,
                  onTap: () => _openCreateDialog(context, player, auth),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),

          // ── List ───────────────────────────────────────────────
          Expanded(
            child: player.playlists.isEmpty
                ? _EmptyState(onCreate: () => _openCreateDialog(context, player, auth))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: player.playlists.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final p = player.playlists[i];
                      final already = p.trackIds.contains(trackId);
                      return _PlaylistRow(
                        emoji: p.emoji,
                        name: p.name,
                        count: p.trackIds.length,
                        added: already,
                        onTap: already
                            ? null
                            : () {
                                player.addTrackToPlaylist(i, trackId);
                                auth.saveUserData(player);
                                onClose?.call();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Added to ${p.name}')),
                                );
                              },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.border, width: 1.5),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.queue_music_rounded, size: 30, color: AppTheme.muted),
          ),
          const SizedBox(height: 16),
          Text('No playlists yet',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.ink)),
          const SizedBox(height: 6),
          const Text('Create one to start saving tracks',
              style: TextStyle(fontSize: 12, color: AppTheme.muted)),
          const SizedBox(height: 20),
          InkBtn(label: '+ CREATE PLAYLIST', active: true, onTap: onCreate),
        ],
      ),
    );
  }
}

// ── Playlist row ─────────────────────────────────────────────────
class _PlaylistRow extends StatelessWidget {
  final String emoji;
  final String name;
  final int count;
  final bool added;
  final VoidCallback? onTap;
  const _PlaylistRow({
    required this.emoji,
    required this.name,
    required this.count,
    required this.added,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.border),
            borderRadius: BorderRadius.circular(10),
            color: added ? AppTheme.bg2 : AppTheme.bg,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.bg2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('$count ${count == 1 ? 'track' : 'tracks'}',
                        style: const TextStyle(fontSize: 10, color: AppTheme.muted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              added
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.border),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('ADDED',
                          style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 1,
                              color: AppTheme.muted,
                              fontFamily: 'JetBrains Mono')),
                    )
                  : Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppTheme.ink,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Create playlist dialog ──────────────────────────────────────
class _CreatePlaylistDialogLocal extends StatefulWidget {
  final PlayerService player;
  final AuthService auth;
  final int trackId;
  const _CreatePlaylistDialogLocal(
      {required this.player, required this.auth, required this.trackId});

  @override
  State<_CreatePlaylistDialogLocal> createState() => _CPDLState();
}

class _CPDLState extends State<_CreatePlaylistDialogLocal> {
  final _ctrl = TextEditingController();
  String _emoji = '🎵';
  final _emojis = ['🎵', '🎸', '🎹', '🎺', '🥁', '🎷', '🎻', '🎤', '🎧', '💿', '📀', '🎼', '🌟', '🔥', '💫', '🌙'];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: AppTheme.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New Playlist',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 19, fontWeight: FontWeight.w800, color: AppTheme.ink)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.bg2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    alignment: Alignment.center,
                    child: Text(_emoji, style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      autofocus: true,
                      style: GoogleFonts.inter(fontSize: 14, color: AppTheme.ink),
                      decoration: InputDecoration(
                        hintText: 'Playlist name…',
                        hintStyle: const TextStyle(color: AppTheme.muted, fontSize: 13),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.ink, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const LabelText('Pick an icon'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _emojis.map((e) {
                  final selected = _emoji == e;
                  return GestureDetector(
                    onTap: () => setState(() => _emoji = e),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.ink : AppTheme.bg2,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: selected ? AppTheme.ink : AppTheme.border, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(e, style: const TextStyle(fontSize: 17)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkBtn(label: 'CANCEL', onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: 8),
                  InkBtn(
                    label: 'CREATE',
                    active: true,
                    onTap: () {
                      final name = _ctrl.text.trim();
                      if (name.isEmpty) return;
                      widget.player.addPlaylist(
                          PlaylistModel(name: name, emoji: _emoji, trackIds: [widget.trackId]));
                      widget.auth.saveUserData(widget.player);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Added to $name',
                                style: GoogleFonts.inter())),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}