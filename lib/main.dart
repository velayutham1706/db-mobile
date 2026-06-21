import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/player_service.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'screens/main_shell.dart';
import 'screens/auth_gate.dart';
import 'package:just_audio_background/just_audio_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.yourapp.dbhifi.channel.audio',
    androidNotificationChannelName: 'DB',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
    androidNotificationIcon: 'mipmap/ic_launcher',
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayerService()),
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const DBHiFiApp(),
    ),
  );
}

class DBHiFiApp extends StatelessWidget {
  const DBHiFiApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'DB Hi-Fi',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: AuthGate(child: const MainShell()),
      );
}
