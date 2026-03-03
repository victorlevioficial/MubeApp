import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountDeletionInProgressNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void start() => state = true;

  void clear() => state = false;
}

final accountDeletionInProgressProvider =
    NotifierProvider<AccountDeletionInProgressNotifier, bool>(
      AccountDeletionInProgressNotifier.new,
    );
