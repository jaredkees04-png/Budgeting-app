import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Opens the browser's native file picker restricted to CSV files and
/// returns the chosen file's text content, or null if the user dismissed
/// the picker without choosing anything.
Future<String?> pickCsvFile() async {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = '.csv,text/csv';

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
