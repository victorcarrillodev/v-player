import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import 'providers/music_provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.v_player.channel.audio',
    androidNotificationChannelName: 'VPlayer - Reproducción de audio',
    androidNotificationOngoing: true,
    androidNotificationIcon: 'mipmap/ic_launcher',
    // Allow the notification to move out of foreground when paused,
    // so Android can reclaim resources; the notification remains visible.
    androidStopForegroundOnPause: true,
    preloadArtwork: true,
    androidNotificationClickStartsActivity: true,
    androidShowNotificationBadge: true,
  );

  // Declare audio focus intent so Android treats this as a music player
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const VPlayerApp());
}

class VPlayerApp extends StatelessWidget {
  const VPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MusicProvider(),
      child: MaterialApp(
        title: 'VPlayer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const HomeScreen(),
      ),
    );
  }
}
