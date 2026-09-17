import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Triggers a browser download of [contents] as [filename] — the same
/// mechanism any "Save file" link on the web uses: a Blob URL behind a
/// hidden, auto-clicked `<a download>` link.
Future<void> saveBackupFile(String filename, String contents) async {
  final blob = web.Blob(
    <JSAny>[contents.toJS].toJS,
    web.BlobPropertyBag(type: 'application/json'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}

/// Opens the browser's native file picker and returns the chosen file's
/// text content, or null if the user dismissed the picker without
/// choosing anything.
Future<String?> pickBackupFile() async {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = '.json,application/json';

  final completer = Completer<String?>();
  input.onChange.listen((_) async {
    final files = input.files;
    final file = (files != null && files.length > 0) ? files.item(0) : null;
    if (file == null) {
      completer.complete(null);
      return;
    }
    final text = await file.text().toDart;
    completer.complete(text.toDart);
  });
  input.click();
  return completer.future;
}
