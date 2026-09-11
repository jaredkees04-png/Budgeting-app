import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Relative to the served `index.html` (works under a GitHub Pages
/// subpath too, as long as `--base-href` is set correctly at build time).
/// The two files come from `web/sqlite3.wasm` and `web/drift_worker.dart.js`
/// — see tool/build_web_worker.sh for how the latter is generated.
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: 'budgeting_app',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.dart.js'),
    );
    return result.resolvedExecutor;
  });
}
