import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/player_service.dart';
import '../theme/app_theme.dart';
import '../screens/auth_screen.dart';

class AuthGate extends StatefulWidget {
  final Widget child;
  const AuthGate({super.key, required this.child});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _loadedUid;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (auth.initialising) {
      return const Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.ink,
            ),
          ),
        ),
      );
    }

    if (!auth.isSignedIn) {
      _loadedUid = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final nav = Navigator.of(context);
        nav.popUntil((route) => route.isFirst);
      });
      return const AuthScreen();
    }

    // Signed in — load user data exactly once per uid
    final uid = auth.user!.uid;
    if (_loadedUid != uid) {
      _loadedUid = uid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<AuthService>().loadUserData(context.read<PlayerService>());
      });
    }

    return widget.child;
  }
}