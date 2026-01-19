import 'dart:io';

void main() {
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
    print('Error: coverage/lcov.info not found.');
    exit(1);
  }

  final lines = file.readAsLinesSync();
  int totalFound = 0;
  int totalHit = 0;

  int fileFound = 0;
  int fileHit = 0;
  String? currentFile;

  print('Coverage Report:');
  print('------------------------------------------------------------');
  print('${"File".padRight(50)} | ${"Coverage".padLeft(8)}');
  print('------------------------------------------------------------');

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3);
      fileFound = 0;
      fileHit = 0;
    } else if (line.startsWith('LF:')) {
      fileFound = int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      fileHit = int.parse(line.substring(3));
    } else if (line == 'end_of_record') {
      if (currentFile != null) {
        totalFound += fileFound;
        totalHit += fileHit;
        
        final percentage = fileFound > 0 ? (fileHit / fileFound * 100) : 0.0;
        final fileName = currentFile.replaceFirst(RegExp(r'.*lib/'), '');
        print('${fileName.padRight(50)} | ${percentage.toStringAsFixed(1).padLeft(7)}%');
      }
    }
  }

  print('------------------------------------------------------------');
  final totalPercentage = totalFound > 0 ? (totalHit / totalFound * 100) : 0.0;
  print('${"Total".padRight(50)} | ${totalPercentage.toStringAsFixed(1).padLeft(7)}%');
}
