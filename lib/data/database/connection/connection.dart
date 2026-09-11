// Picks the right drift backend for the current platform at compile time:
// native SQLite via dart:ffi on iOS/Android/desktop, or a WebAssembly
// SQLite build backed by OPFS/IndexedDB in the browser. Neither branch is
// reachable from the other platform's compiled output.
export 'connection_stub.dart'
    if (dart.library.io) 'connection_native.dart'
    if (dart.library.js_interop) 'connection_web.dart';
