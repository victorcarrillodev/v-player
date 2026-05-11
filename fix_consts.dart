import 'dart:io';

void main() {
  final lines = File('analyze_output.txt').readAsLinesSync();
  final invalidConstantLines = lines.where((l) => l.contains('invalid_constant')).toList();

  for (var line in invalidConstantLines) {
    // Format is like: error • Invalid constant value • lib/widgets/song_tile.dart:102:28 • invalid_constant
    final parts = line.split(' • ');
    if (parts.length >= 3) {
      final fileLoc = parts[2].trim();
      final locParts = fileLoc.split(':');
      if (locParts.length >= 2) {
        final filePath = locParts[0];
        final lineNum = int.tryParse(locParts[1]);
        if (filePath.isNotEmpty && lineNum != null) {
          final file = File(filePath);
          if (file.existsSync()) {
            final fileLines = file.readAsLinesSync();
            if (lineNum > 0 && lineNum <= fileLines.length) {
              final idx = lineNum - 1;
              fileLines[idx] = fileLines[idx].replaceAll('const ', '');
              file.writeAsStringSync('${fileLines.join('\n')}\n');
              print('Fixed $filePath:$lineNum');
            }
          }
        }
      }
    }
  }
}
