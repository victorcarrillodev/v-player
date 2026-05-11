import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import 'package:home_widget/home_widget.dart';
import 'providers/music_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HomeWidget.setAppGroupId('com.example.v_player');
  
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.v_player.channel.audio',
    androidNotificationChannelName: 'VPlayer - Reproducción de audio',
    androidNotificationIcon: 'mipmap/ic_launcher',
    androidStopForegroundOnPause: false,
    preloadArtwork: true,
    androidNotificationClickStartsActivity: true,
    androidShowNotificationBadge: true,
  );

  // Declare audio focus intent so Android treats this as a music player
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const VPlayerApp());
}

class VPlayerApp extends StatelessWidget {
  const VPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => MusicProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final colors = themeProvider.currentColors;
          
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: themeProvider.isDarkMode ? Brightness.light : Brightness.dark,
              systemNavigationBarColor: colors.background,
              systemNavigationBarIconBrightness: themeProvider.isDarkMode ? Brightness.light : Brightness.dark,
            ),
            child: MaterialApp(
              title: 'VPlayer',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.getTheme(colors, themeProvider.isDarkMode, themeProvider.animationsEnabled),
              home: const HomeScreen(),
            ),
          );
        },
      ),
    );
  }
}
