import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_availability.dart';

void main() {
  group('matchpoint_availability', () {
    test('keeps bands eligible regardless of category mix', () {
      expect(
        isMatchpointAvailableForType(
          AppUserType.band,
          rawCategories: const ['luthier'],
          rawRoles: const [],
        ),
        isTrue,
      );
    });

    test('blocks professional profiles that are only luthier', () {
      expect(
        isMatchpointAvailableForType(
          AppUserType.professional,
          rawCategories: const ['luthier'],
          rawRoles: const [],
        ),
        isFalse,
      );
    });

    test('keeps instrumentalist plus luthier profiles eligible', () {
      expect(
        isMatchpointAvailableForType(
          AppUserType.professional,
          rawCategories: const ['instrumentalist', 'luthier'],
          rawRoles: const [],
        ),
        isTrue,
      );
    });

    test('uses AppUser helper for contractor profiles', () {
      const user = AppUser(
        uid: 'contractor-1',
        email: 'contractor@mube.com',
        tipoPerfil: AppUserType.contractor,
      );

      expect(isMatchpointAvailableForUser(user), isFalse);
    });
  });
}
