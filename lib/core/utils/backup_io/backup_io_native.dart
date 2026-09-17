import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Writes the backup to the app's documents directory. There's no share
/// sheet here (that would need a new dependency this app doesn't
/// otherwise use) — this app ships as a web PWA, so the web
/// implementation is what actually gets exercised; this native path
/// exists mainly so a future native build still compiles and has a
/// reasonable fallback rather than a platform gap.
Future<void> saveBackupFile(String filename, String contents) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, filename));
  await file.writeAsString(contents);
}

Future<String?> pickBackupFile() {
  throw UnsupportedError(
    'Importing a backup file isn\'t available in this build yet — use the '
    'web version of the app to restore a backup.',
  );
}
