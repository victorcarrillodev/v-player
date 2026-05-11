import 'dart:io';

void main() {
  final lines = File('analyze_output.txt').readAsLinesSync();
  final invalidConstantLines = lines.where((l) => l.contains('invalid_constant')).toList();

  for (var line in invalidConstantLines) {
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
              // Start from lineNum - 1, and go up to 5 lines back to find 'const '
              bool fixed = false;
              for (int i = lineNum - 1; i >= 0 && i >= lineNum - 6; i--) {
                if (fileLines[i].contains('const ')) {
                  fileLines[i] = fileLines[i].replaceFirst('const ', '');
                  fixed = true;
                  print('Fixed const at $filePath:${i + 1}');
                  break;
                }
              }
              if (fixed) {
                file.writeAsStringSync('${fileLines.join('\n')}\n');
              }
            }
          }
        }
      }
    }
  }
}
