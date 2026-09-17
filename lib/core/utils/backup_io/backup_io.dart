// Picks the right file-save/file-pick implementation for the current
// platform at compile time, mirroring connection/connection.dart's pattern
// for the database backend.
export 'backup_io_stub.dart'
    if (dart.library.io) 'backup_io_native.dart'
    if (dart.library.js_interop) 'backup_io_web.dart';
