import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared.dart';
import 'package:google_fonts/google_fonts.dart';

class LikedScreen extends StatelessWidget {
  const LikedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerService>();
    final liked = player.tracks.where((t) => t.liked).toList();

    return CustomScrollView(
      slivers: [
        // Hero
        SliverToBoxAdapter(
          child: Container(
            color: AppTheme.dark,
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Liked\nSongs',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                      height: 1.05),
                ),
                const SizedBox(height: 8),
                Text(
                  '${liked.length} track${liked.length != 1 ? "s" : ""} you love',
                  style: const TextStyle(
                      fontSize: 10, color: Colors.white38, letterSpacing: 2),
                ),
              ],
            ),
          ),
        ),

        if (liked.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  // ── Proper heart SVG, large, unfilled ──────────
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 52,
                    color: AppTheme.muted,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No liked songs yet',
                    style: TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Tap ♡ on any track to like it',
                    style: TextStyle(fontSize: 11, color: AppTheme.muted),
                  ),
                ],
              ),
            ),
          )
        else ...[
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => Column(children: [
                TrackTile(track: liked[i], displayNum: i + 1),
                const Divider(height: 1, color: Color(0x12000000)),
              ]),
              childCount: liked.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ],
    );
  }
}