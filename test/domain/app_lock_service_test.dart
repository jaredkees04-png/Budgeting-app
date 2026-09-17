import 'package:flutter_test/flutter_test.dart';

import 'package:budgeting_app/domain/services/app_lock_service.dart';

void main() {
  final service = AppLockService();

  test('the correct password verifies against its own hash and salt', () {
    final salt = service.generateSalt();
    final hash = service.hashPin('1234', salt);

    expect(
      service.verifyPin(pin: '1234', salt: salt, expectedHash: hash),
      isTrue,
    );
  });

  test('the wrong password fails verification', () {
    final salt = service.generateSalt();
    final hash = service.hashPin('1234', salt);

    expect(
      service.verifyPin(pin: '4321', salt: salt, expectedHash: hash),
      isFalse,
    );
  });

  test('the same password hashes differently with a different salt', () {
    final saltA = service.generateSalt();
    final saltB = service.generateSalt();

    expect(saltA, isNot(equals(saltB)));
    expect(
      service.hashPin('hunter2', saltA),
      isNot(equals(service.hashPin('hunter2', saltB))),
    );
  });

  test('the hash never contains the raw password', () {
    final salt = service.generateSalt();
    final hash = service.hashPin('mypassword', salt);

    expect(hash.contains('mypassword'), isFalse);
  });
}
