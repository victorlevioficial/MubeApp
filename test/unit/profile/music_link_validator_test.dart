import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/profile/domain/music_link_validator.dart';

void main() {
  group('MusicLinkValidator', () {
    test('accepts valid links for each supported platform', () {
      expect(
        MusicLinkValidator.validate(
          MusicLinkValidator.spotifyKey,
          'https://open.spotify.com/artist/test',
        ),
        isNull,
      );
      expect(
        MusicLinkValidator.validate(
          MusicLinkValidator.deezerKey,
          'https://www.deezer.com/artist/test',
        ),
        isNull,
      );
      expect(
        MusicLinkValidator.validate(
          MusicLinkValidator.youtubeMusicKey,
          'https://music.youtube.com/channel/test',
        ),
        isNull,
      );
      expect(
        MusicLinkValidator.validate(
          MusicLinkValidator.appleMusicKey,
          'https://music.apple.com/br/artist/test',
        ),
        isNull,
      );
    });

    test('rejects invalid hosts and schemes', () {
      expect(
        MusicLinkValidator.validate(
          MusicLinkValidator.spotifyKey,
          'https://google.com/artist/test',
        ),
        isNotNull,
      );
      expect(
        MusicLinkValidator.validate(
          MusicLinkValidator.deezerKey,
          'ftp://www.deezer.com/artist/test',
        ),
        isNotNull,
      );
    });

    test('accepts empty values because links are optional', () {
      expect(
        MusicLinkValidator.validate(MusicLinkValidator.spotifyKey, ''),
        isNull,
      );
      expect(
        MusicLinkValidator.validate(MusicLinkValidator.spotifyKey, '   '),
        isNull,
      );
    });

    test(
      'sanitize trims values, removes empty entries and ignores unknown keys',
      () {
        final sanitized = MusicLinkValidator.sanitize({
          MusicLinkValidator.spotifyKey:
              '  https://open.spotify.com/artist/test ',
          MusicLinkValidator.deezerKey: '   ',
          'unknown': 'https://example.com',
        });

        expect(sanitized, {
          MusicLinkValidator.spotifyKey: 'https://open.spotify.com/artist/test',
        });
      },
    );

    test('validLinks keeps only sanitized valid entries', () {
      final valid = MusicLinkValidator.validLinks({
        MusicLinkValidator.spotifyKey: 'https://open.spotify.com/artist/test',
        MusicLinkValidator.deezerKey: 'https://google.com/test',
      });

      expect(valid, {
        MusicLinkValidator.spotifyKey: 'https://open.spotify.com/artist/test',
      });
    });
  });
}
