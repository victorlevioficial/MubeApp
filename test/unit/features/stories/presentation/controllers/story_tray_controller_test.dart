import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/feed/domain/feed_item.dart';
import 'package:mube/src/features/feed/domain/feed_section.dart';
import 'package:mube/src/features/feed/presentation/feed_state.dart';
import 'package:mube/src/features/stories/presentation/controllers/story_tray_controller.dart';

void main() {
  group('buildStoryTrayDiscoveryFingerprint', () {
    FeedItem item(String uid) =>
        FeedItem(uid: uid, nome: 'User $uid', tipoPerfil: 'profissional');

    test('returns empty fingerprint when feed state is null', () {
      expect(buildStoryTrayDiscoveryFingerprint(null), isEmpty);
    });

    test(
      'ignores extra paginated items outside the tracked discovery window',
      () {
        final baseState = FeedState(
          featuredItems: [item('featured-1'), item('featured-2')],
          sectionItems: {
            FeedSectionType.technicians: [item('tech-1'), item('tech-2')],
            FeedSectionType.bands: [item('band-1'), item('band-2')],
          },
          items: [
            item('main-1'),
            item('main-2'),
            item('main-3'),
            item('main-4'),
            item('main-5'),
            item('main-6'),
            item('main-7'),
            item('main-8'),
          ],
        );

        final fingerprint = buildStoryTrayDiscoveryFingerprint(baseState);
        final fingerprintWithExtraItems = buildStoryTrayDiscoveryFingerprint(
          baseState.copyWithFeed(
            items: [
              ...baseState.items,
              item('main-9'),
              item('main-10'),
              item('main-11'),
            ],
          ),
        );

        expect(fingerprintWithExtraItems, fingerprint);
      },
    );

    test(
      'deduplicates owners collected from featured, sections and main feed',
      () {
        final fingerprint = buildStoryTrayDiscoveryFingerprint(
          FeedState(
            featuredItems: [item('shared-owner')],
            sectionItems: {
              FeedSectionType.technicians: [
                item('shared-owner'),
                item('tech-2'),
              ],
            },
            items: [item('shared-owner'), item('main-2')],
          ),
        );

        expect(fingerprint.split('|'), ['main-2', 'shared-owner', 'tech-2']);
      },
    );
  });
}
