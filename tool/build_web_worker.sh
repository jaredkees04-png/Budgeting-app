#!/usr/bin/env bash
# Regenerates web/drift_worker.dart.js from tool/drift_worker.dart.
# Run this after upgrading the drift package, or if the worker file is
# ever missing/stale. The compiled output is committed to the repo so a
# plain `flutter build web` doesn't need a separate compile step.
set -euo pipefail
cd "$(dirname "$0")/.."
dart compile js -o web/drift_worker.dart.js tool/drift_worker.dart
