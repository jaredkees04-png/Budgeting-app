import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Hashing for the local app-lock PIN. This is a device lock, not
/// authentication against a server — there is no backend and nothing is
/// ever transmitted — but the PIN is still hashed with a random salt
/// rather than stored in the clear, since the database file itself
/// (readable via the browser's dev tools, or a native build's app
/// documents directory) shouldn't hand over the PIN at a glance.
class AppLockService {
  final Random _random;

  AppLockService({Random? random}) : _random = random ?? Random.secure();

  String generateSalt() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String hashPin(String pin, String salt) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }

  bool verifyPin({
    required String pin,
    required String salt,
    required String expectedHash,
  }) {
    return hashPin(pin, salt) == expectedHash;
  }
}
