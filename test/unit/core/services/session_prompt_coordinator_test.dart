import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/core/services/session_prompt_coordinator.dart';

void main() {
  group('SessionPromptCoordinator', () {
    test('blocks prompts while pending, evaluating, and visible', () {
      final coordinator = SessionPromptCoordinator(pendingInitially: true);

      expect(coordinator.canEvaluate, isTrue);
      expect(coordinator.blocksOtherPrompts, isTrue);

      coordinator.startEvaluation();

      expect(coordinator.canEvaluate, isFalse);
      expect(coordinator.blocksOtherPrompts, isTrue);

      coordinator.finishEvaluation(keepPending: false);
      coordinator.beginDisplay();

      expect(coordinator.canEvaluate, isFalse);
      expect(coordinator.blocksOtherPrompts, isTrue);

      coordinator.endDisplay();

      expect(coordinator.blocksOtherPrompts, isFalse);
    });
  });

  group('UserScopedSessionPromptCoordinator', () {
    test('queues a new session only when user changes', () {
      final coordinator = UserScopedSessionPromptCoordinator(logLabel: 'Test');

      expect(coordinator.handleAuthUser('user-1'), isTrue);
      expect(coordinator.canPresent, isTrue);

      coordinator.beginDisplay();
      coordinator.endDisplay();

      expect(coordinator.handleAuthUser('user-1'), isFalse);
      expect(coordinator.canPresent, isFalse);

      expect(coordinator.handleAuthUser('user-2'), isTrue);
      expect(coordinator.canPresent, isTrue);
    });
  });
}
