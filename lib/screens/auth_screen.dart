import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/player_service.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  late AnimationController _tabAnim;

  @override
  void initState() {
    super.initState();
    _tabAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _tabAnim.dispose();
    super.dispose();
  }

  void _switchTab(bool login) {
    setState(() => _isLogin = login);
    login ? _tabAnim.reverse() : _tabAnim.forward();
    context.read<AuthService>().clearError();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthService>();
    if (_isLogin) {
      await auth.signInEmail(_emailCtrl.text.trim(), _passCtrl.text);
    } else {
      await auth.registerEmail(
          _emailCtrl.text.trim(), _passCtrl.text, _nameCtrl.text.trim());
    }
  }

  Future<void> _googleSignIn() async {
    await context.read<AuthService>().signInGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Header ──
              Container(
                width: double.infinity,
                color: AppTheme.dark,
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text('DB',
                            style: TextStyle(
                                fontSize: 40,
                                letterSpacing: 4,
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'BebasNeue')),
                        const SizedBox(width: 8),
                        Text('Hi-Fi',
                            style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 3,
                                color: Colors.white38,
                                fontFamily: 'JetBrains Mono')),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Your music. Your taste. Keep smiling DB.',
                        style: TextStyle(
                            fontSize: 10,
                            color: Color.fromARGB(178, 226, 226, 226),
                            letterSpacing: 1)),
                  ],
                ),
              ),

              // ── Tabs ──
              Container(
                decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: AppTheme.ink, width: 2))),
                child: Row(
                  children: [
                    _Tab(
                        label: 'Sign In',
                        active: _isLogin,
                        onTap: () => _switchTab(true)),
                    _Tab(
                        label: 'Register',
                        active: !_isLogin,
                        onTap: () => _switchTab(false)),
                  ],
                ),
              ),

              // ── Form ──
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Error banner
                    if (auth.error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFF0F0),
                          border: Border(
                              left: BorderSide(color: Colors.red, width: 3)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(auth.error!,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.red,
                                fontFamily: 'JetBrains Mono')),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Display name (register only)
                    if (!_isLogin) ...[
                      _Field(
                          label: 'Display Name',
                          ctrl: _nameCtrl,
                          hint: 'Your name'),
                      const SizedBox(height: 14),
                    ],

                    _Field(
                        label: 'Email',
                        ctrl: _emailCtrl,
                        hint: 'you@example.com',
                        keyboard: TextInputType.emailAddress),
                    const SizedBox(height: 14),
                    _Field(
                        label: 'Password',
                        ctrl: _passCtrl,
                        hint: '••••••••',
                        obscure: true,
                        onSubmit: _submit),
                    const SizedBox(height: 20),

                    // Submit button
                    GestureDetector(
                      onTap: auth.syncing ? null : _submit,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.ink,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: auth.syncing
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(
                                _isLogin ? 'Sign In' : 'Create Account',
                                style: const TextStyle(
                                    fontSize: 11,
                                    letterSpacing: 2,
                                    color: Colors.white,
                                    fontFamily: 'JetBrains Mono',
                                    fontWeight: FontWeight.w500),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Divider
                    Row(children: const [
                      Expanded(child: Divider(color: AppTheme.border)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or',
                            style: TextStyle(
                                fontSize: 9,
                                letterSpacing: 2,
                                color: AppTheme.muted,
                                fontFamily: 'JetBrains Mono')),
                      ),
                      Expanded(child: Divider(color: AppTheme.border)),
                    ]),
                    const SizedBox(height: 16),

                    // Google sign-in button
                    GestureDetector(
                      onTap: auth.syncing ? null : _googleSignIn,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.ink, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            _GoogleIcon(),
                            SizedBox(width: 10),
                            Text('Continue with Google',
                                style: TextStyle(
                                    fontSize: 10,
                                    letterSpacing: 1,
                                    color: AppTheme.ink,
                                    fontFamily: 'JetBrains Mono')),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tab widget ──
class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: active ? AppTheme.bg : AppTheme.bg2,
              border: Border(
                right: const BorderSide(color: AppTheme.border),
                bottom: active
                    ? const BorderSide(color: AppTheme.ink, width: 3)
                    : BorderSide.none,
              ),
            ),
            alignment: Alignment.center,
            child: Text(label.toUpperCase(),
                style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 2,
                    color: active ? AppTheme.ink : AppTheme.muted,
                    fontFamily: 'JetBrains Mono',
                    fontWeight:
                        active ? FontWeight.w500 : FontWeight.normal)),
          ),
        ),
      );
}

// ── Text field widget ──
class _Field extends StatelessWidget {
  final String label, hint;
  final TextEditingController ctrl;
  final bool obscure;
  final TextInputType? keyboard;
  final VoidCallback? onSubmit;
  const _Field(
      {required this.label,
      required this.ctrl,
      required this.hint,
      this.obscure = false,
      this.keyboard,
      this.onSubmit});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 8,
                  letterSpacing: 2,
                  color: AppTheme.muted,
                  fontFamily: 'JetBrains Mono')),
          const SizedBox(height: 7),
          TextField(
            controller: ctrl,
            obscureText: obscure,
            keyboardType: keyboard,
            onSubmitted: (_) => onSubmit?.call(),
            style: const TextStyle(
                fontSize: 13,
                color: AppTheme.ink,
                fontFamily: 'JetBrains Mono'),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppTheme.muted),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.border, width: 2)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.ink, width: 2)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.border, width: 2)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
            ),
          ),
        ],
      );
}

// ── Google icon (matches website's multi-color SVG) ──
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GoogleIconPainter()),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final redPaint = Paint()..color = const Color(0xFFEA4335);

    // Blue — top right arc
    final bluePath = Path()
      ..moveTo(w * 0.94, h * 0.51)
      ..lineTo(w * 0.50, h * 0.51)
      ..lineTo(w * 0.50, h * 0.69)
      ..lineTo(w * 0.75, h * 0.69)
      ..conicTo(w * 0.69, h * 0.87, w * 0.61, h * 0.94, 1)
      ..lineTo(w * 0.76, h * 1.05)
      ..conicTo(w * 0.94, h * 0.91, w * 0.94, h * 0.51, 1);
    canvas.drawPath(bluePath, bluePaint);

    // Green — bottom right
    final greenPath = Path()
      ..moveTo(w * 0.50, h * 0.96)
      ..conicTo(w * 0.36, h * 0.96, w * 0.22, h * 0.87, 1)
      ..lineTo(w * 0.10, h * 0.98)
      ..conicTo(w * 0.27, h * 1.08, w * 0.50, h * 1.08, 1)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // Yellow — bottom left
    final yellowPath = Path()
      ..moveTo(w * 0.24, h * 0.59)
      ..conicTo(w * 0.19, h * 0.52, w * 0.19, h * 0.50, 1)
      ..conicTo(w * 0.19, h * 0.48, w * 0.24, h * 0.41, 1)
      ..lineTo(w * 0.09, h * 0.29)
      ..conicTo(w * 0.04, h * 0.38, w * 0.04, h * 0.50, 1)
      ..conicTo(w * 0.04, h * 0.62, w * 0.09, h * 0.71, 1)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // Red — top left
    final redPath = Path()
      ..moveTo(w * 0.50, h * 0.23)
      ..conicTo(w * 0.63, h * 0.23, w * 0.73, h * 0.30, 1)
      ..lineTo(w * 0.85, h * 0.17)
      ..conicTo(w * 0.72, h * 0.05, w * 0.50, h * 0.05, 1)
      ..conicTo(w * 0.27, h * 0.05, w * 0.09, h * 0.16, 1)
      ..lineTo(w * 0.24, h * 0.28)
      ..conicTo(w * 0.35, h * 0.23, w * 0.50, h * 0.23, 1)
      ..close();
    canvas.drawPath(redPath, redPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}