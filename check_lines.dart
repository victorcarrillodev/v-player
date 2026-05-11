import 'dart:io';

void main() {
  final files = {
    'lib/screens/home_screen.dart': [487, 763],
    'lib/widgets/mini_player.dart': [99, 110, 175],
    'lib/widgets/song_tile.dart': [102, 112, 135, 345],
    'lib/widgets/vmusic_widgets.dart': [44],
  };

  for (final path in files.keys) {
    final file = File(path);
    if (!file.existsSync()) continue;
    final lines = file.readAsLinesSync();
    for (final line in files[path]!) {
      if (line > 0 && line <= lines.length) {
        print('--- $path:$line ---');
        for (int i = line - 3; i <= line; i++) {
          if (i >= 0 && i < lines.length) {
            print('$i: ${lines[i]}');
          }
        }
      }
    }
  }
}
