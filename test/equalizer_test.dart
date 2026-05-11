import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:v_player/providers/music_provider.dart';
import 'package:v_player/providers/theme_provider.dart';
import 'package:v_player/screens/equalizer_screen.dart';

void main() {
  testWidgets('EqualizerScreen loads without crashing', (WidgetTester tester) async {
    final themeProvider = ThemeProvider();
    final musicProvider = MusicProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: musicProvider),
        ],
        child: MaterialApp(
          home: const EqualizerScreen(),
        ),
      ),
    );

    // Wait for animations and futures
    await tester.pumpAndSettle();
    
    // Check if the screen loaded (even if it's the loading state)
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
