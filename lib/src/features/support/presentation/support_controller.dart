import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../utils/app_logger.dart';
import '../../auth/data/auth_repository.dart';
import '../../storage/data/storage_repository.dart';
import '../data/support_repository.dart';
import '../domain/ticket_model.dart';

part 'support_controller.g.dart';

@riverpod
class SupportController extends _$SupportController {
  @override
  FutureOr<void> build() {
    // nothing to initialize
  }

  Future<void> submitTicket({
    required String title,
    required String description,
    required String category,
    List<File> attachments = const [],
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(currentUserProfileProvider).value;
      if (user == null) throw Exception('Usuário não autenticado');

      final ticketId = const Uuid().v4();
      final List<String> imageUrls = [];

      if (attachments.isNotEmpty) {
        final storage = ref.read(storageRepositoryProvider);
        try {
          for (final file in attachments) {
            final url = await storage.uploadSupportAttachment(
              ticketId: ticketId,
              file: file,
            );
            imageUrls.add(url);
          }
        } catch (error, stack) {
          try {
            await storage.deleteSupportAttachments(ticketId: ticketId);
          } catch (cleanupError, cleanupStack) {
            AppLogger.warning(
              'Failed to clean up support attachments after upload error',
              cleanupError,
              cleanupStack,
            );
          }
          Error.throwWithStackTrace(error, stack);
        }
      }

      final ticket = Ticket(
        id: ticketId,
        userId: user.uid,
        title: title,
        description: description,
        category: category,
        status: TicketStatus.open,
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(supportRepositoryProvider).createTicket(ticket);
    });
  }
}

@riverpod
Stream<List<Ticket>> userTickets(Ref ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream.value([]);

  return ref.read(supportRepositoryProvider).watchUserTickets(uid);
}
