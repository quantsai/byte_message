import 'dart:io';

void main() async {
  final lcovFile = File('coverage/lcov.info');
  if (!await lcovFile.exists()) {
    print('coverage/lcov.info not found');
    return;
  }

  final lines = await lcovFile.readAsLines();
  String? currentFile;
  int foundLines = 0;
  int hitLines = 0;

  print('Coverage Report:');
  print('----------------');

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3);
      foundLines = 0;
      hitLines = 0;
    } else if (line.startsWith('LF:')) {
      foundLines = int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      hitLines = int.parse(line.substring(3));
    } else if (line == 'end_of_record') {
      if (currentFile != null && currentFile.contains('lib/src/factories')) {
        final percentage = (hitLines / foundLines * 100).toStringAsFixed(2);
        print('$currentFile: $percentage% ($hitLines/$foundLines)');
      }
      currentFile = null;
    }
  }
}
