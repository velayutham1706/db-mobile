import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/mini_player.dart';
import '../screens/home_screen.dart';
import '../screens/albums_screen.dart';
import '../screens/search_screen.dart';
import '../screens/playlists_screen.dart';
import '../screens/liked_screen.dart';
import '../screens/player_screen.dart';
import '../services/player_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/update_service.dart';

final activeTabNotifier = ValueNotifier<int>(0);

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  int _tab = 0;
  late PageController _pc;

  // Not const — screens may not have const constructors after refactoring.
  final _screens = [
    const HomeScreen(),
    const AlbumsScreen(),
    const SearchScreen(),
    const PlaylistsScreen(),
    const LikedScreen(),
  ];

  final _labels = ['Home', 'Albums', 'Search', 'Lists', 'Liked'];
  final _icons = [
    Icons.home_outlined,
    Icons.album_outlined,
    Icons.search_rounded,
    Icons.queue_music_outlined,
    Icons.favorite_border_rounded,
  ];
  final _activeIcons = [
    Icons.home_rounded,
    Icons.album_rounded,
    Icons.search_rounded,
    Icons.queue_music_rounded,
    Icons.favorite_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _pc = PageController();
    activeTabNotifier.addListener(_onTabNotifierChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) UpdateService.checkForUpdate(context);
    });
  }

  void _onTabNotifierChanged() {
    final t = activeTabNotifier.value;
    if (_tab != t) {
      setState(() => _tab = t);
      _pc.jumpToPage(t);
    }
  }

  @override
  void dispose() {
    activeTabNotifier.removeListener(_onTabNotifierChanged);
    _pc.dispose();
    super.dispose();
  }

  void _switchTab(int i) {
    if (_tab == i) return;
    setState(() => _tab = i);
    activeTabNotifier.value = i;
    _pc.animateToPage(
      i,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: _buildAppBar(auth),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pc,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (i) => setState(() => _tab = i),
              children: _screens,
            ),
          ),
          Consumer<PlayerService>(
            builder: (context, player, _) {
              if (player.recentlyPlayed.isEmpty) return const SizedBox.shrink();
              return const MiniPlayerBar();
            },
          ),
        ],
      ),
      bottomNavigationBar: _buildNav(),
    );
  }

  AppBar _buildAppBar(AuthService auth) => AppBar(
        backgroundColor: AppTheme.bg,
        elevation: 0,
        titleSpacing: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: Divider(height: 2, thickness: 2, color: AppTheme.ink),
        ),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    backgroundColor: AppTheme.bg,
                    title: const Text(
                      'DB Hi-Fi',
                      style: TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontWeight: FontWeight.w900,
                        color: AppTheme.ink,
                      ),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nothing to view here though.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.muted,
                            fontFamily: 'JetBrains Mono',
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        FutureBuilder<PackageInfo>(
                          future: PackageInfo.fromPlatform(),
                          builder: (context, snap) => Text(
                            snap.hasData
                                ? 'Version ${snap.data!.version} (${snap.data!.buildNumber})'
                                : 'Version —',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.muted,
                              fontFamily: 'JetBrains Mono',
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          UpdateService.checkForUpdate(context, silent: false);
                        },
                        child: const Text(
                          'CHECK FOR UPDATES',
                          style: TextStyle(
                            color: AppTheme.ink,
                            fontFamily: 'JetBrains Mono',
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'OK',
                          style: TextStyle(
                            color: AppTheme.ink,
                            fontFamily: 'JetBrains Mono',
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.ink,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'DB',
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 1,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'BebasNeue',
                    ),
                  ),
                ),
              ),
              const Spacer(),
              if (auth.syncing)
                Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Color(0xFFF5A623))),
              if (auth.isSignedIn)
                GestureDetector(
                  onTap: () => _showUserMenu(context, auth),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: AppTheme.ink,
                    backgroundImage: auth.user?.photoURL != null
                        ? NetworkImage(auth.user!.photoURL!)
                        : null,
                    child: auth.user?.photoURL == null
                        ? Text(
                            (auth.user?.displayName ??
                                    auth.user?.email ??
                                    'U')[0]
                                .toUpperCase(),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white))
                        : null,
                  ),
                )
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
      );

  void _showUserMenu(BuildContext context, AuthService auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: AppTheme.dark,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white24,
                  backgroundImage: auth.user?.photoURL != null
                      ? NetworkImage(auth.user!.photoURL!)
                      : null,
                  child: auth.user?.photoURL == null
                      ? Text((auth.user?.displayName ?? '?')[0],
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16))
                      : null,
                ),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(auth.user?.displayName ?? 'User',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  Text(auth.user?.email ?? '',
                      style:
                          const TextStyle(fontSize: 10, color: Colors.white38)),
                ]),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: const Text('Sign Out',
                style: TextStyle(
                    color: Colors.red,
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12)),
            onTap: () {
              Navigator.pop(context);
              auth.signOut();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNav() => Container(
        decoration: const BoxDecoration(
          color: AppTheme.bg,
          border: Border(top: BorderSide(color: AppTheme.ink, width: 2)),
        ),
        child: Row(
          children: List.generate(
              _labels.length,
              (i) => Expanded(
                    child: _NavItem(
                      icon: _tab == i ? _activeIcons[i] : _icons[i],
                      label: _labels[i],
                      active: _tab == i,
                      onTap: () => _switchTab(i),
                    ),
                  )),
        ),
      );
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = active ? AppTheme.ink : AppTheme.muted;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: active ? AppTheme.ink : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(icon,
                  key: ValueKey('${icon.codePoint}_$active'),
                  size: 24,
                  color: iconColor),
            ),
            const SizedBox(height: 4),
            Text(label.toUpperCase(),
                style: TextStyle(
                    fontSize: 7,
                    letterSpacing: 1,
                    color: iconColor,
                    fontFamily: 'JetBrains Mono',
                    fontWeight: active ? FontWeight.w700 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

class DetailBottomBar extends StatelessWidget {
  const DetailBottomBar({super.key});

  static const _labels = ['Home', 'Albums', 'Search', 'Lists', 'Liked'];
  static const _icons = [
    Icons.home_outlined,
    Icons.album_outlined,
    Icons.search_rounded,
    Icons.queue_music_outlined,
    Icons.favorite_border_rounded,
  ];
  static const _activeIcons = [
    Icons.home_rounded,
    Icons.album_rounded,
    Icons.search_rounded,
    Icons.queue_music_rounded,
    Icons.favorite_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: activeTabNotifier,
      builder: (context, activeTab, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Consumer<PlayerService>(
              builder: (context, player, _) {
                if (player.recentlyPlayed.isEmpty)
                  return const SizedBox.shrink();
                return const MiniPlayerBar();
              },
            ),
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.bg,
                border: Border(top: BorderSide(color: AppTheme.ink, width: 2)),
              ),
              child: Row(
                children: List.generate(
                    _labels.length,
                    (i) => Expanded(
                          child: GestureDetector(
                            onTap: () {
                              activeTabNotifier.value = i;
                              Navigator.of(context).popUntil((r) => r.isFirst);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                border: Border(
                                    top: BorderSide(
                                  color: activeTab == i
                                      ? AppTheme.ink
                                      : Colors.transparent,
                                  width: 2,
                                )),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                      activeTab == i
                                          ? _activeIcons[i]
                                          : _icons[i],
                                      size: 24,
                                      color: activeTab == i
                                          ? AppTheme.ink
                                          : AppTheme.muted),
                                  const SizedBox(height: 4),
                                  Text(_labels[i].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 7,
                                        letterSpacing: 1,
                                        color: activeTab == i
                                            ? AppTheme.ink
                                            : AppTheme.muted,
                                        fontFamily: 'JetBrains Mono',
                                        fontWeight: activeTab == i
                                            ? FontWeight.w700
                                            : FontWeight.normal,
                                      )),
                                ],
                              ),
                            ),
                          ),
                        )),
              ),
            ),
          ],
        );
      },
    );
  }
}
