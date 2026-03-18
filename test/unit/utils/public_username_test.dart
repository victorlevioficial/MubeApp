import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/utils/public_username.dart';

void main() {
  group('public username helpers', () {
    test('normalizes handles to lowercase ascii without @ prefix', () {
      expect(normalizePublicUsername('@Víctor.Levi'), 'victor.levi');
      expect(normalizePublicUsername(' Mube Oficial '), 'mubeoficial');
    });

    test('validates optional empty usernames', () {
      expect(validatePublicUsername(''), isNull);
      expect(validatePublicUsername(null), isNull);
    });

    test('rejects usernames that are too short', () {
      expect(validatePublicUsername('@ab'), 'Use pelo menos 3 caracteres.');
    });

    test('accepts canonical public usernames', () {
      expect(validatePublicUsername('@mube.oficial'), isNull);
      expect(isValidPublicUsername('mube_oficial'), isTrue);
      expect(publicUsernameHandle('Mube.Oficial'), '@mube.oficial');
    });
  });
}
