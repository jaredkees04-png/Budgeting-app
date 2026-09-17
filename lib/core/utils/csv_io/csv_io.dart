// Picks the right file-picker implementation for the current platform at
// compile time, mirroring backup_io's pattern for a different file type
// (a bank statement CSV instead of a JSON backup) — kept separate from
// backup_io rather than generalizing it, so this unrelated feature
// doesn't risk touching that already-shipped, already-tested code path.
export 'csv_io_stub.dart'
    if (dart.library.io) 'csv_io_native.dart'
    if (dart.library.js_interop) 'csv_io_web.dart';
