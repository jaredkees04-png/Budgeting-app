// Compiled to web/drift_worker.dart.js and served as a static asset — see
// tool/build_web_worker.sh. This is drift's off-main-thread database worker
// for the web build; it has nothing to do with the app's own logic.
import 'package:drift/wasm.dart';

void main() {
  WasmDatabase.workerMainForOpen();
}
