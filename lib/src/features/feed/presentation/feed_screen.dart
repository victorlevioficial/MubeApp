import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../../../common_widgets/primary_button.dart';
import '../../../common_widgets/responsive_center.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MUBE'),
        centerTitle: true,
        automaticallyImplyLeading:
            false, // Don't show back button on main screen
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authRepositoryProvider).signOut();
            },
          ),
        ],
      ),
      body: ResponsiveCenter(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Feed Vazio',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Em breve você verá os melhores\nprofissionais da música aqui.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                height: 48,
                child: PrimaryButton(
                  text: 'Sair do App',
                  onPressed: () {
                    ref.read(authRepositoryProvider).signOut();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
