Future<void> saveBackupFile(String filename, String contents) {
  throw UnsupportedError('Backup export is not supported on this platform.');
}

Future<String?> pickBackupFile() {
  throw UnsupportedError('Backup import is not supported on this platform.');
}
