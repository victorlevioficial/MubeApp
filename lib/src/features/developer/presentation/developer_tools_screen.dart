import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mube/src/design_system/components/feedback/app_snackbar.dart';
import 'package:mube/src/design_system/components/navigation/app_app_bar.dart';
import 'package:mube/src/design_system/foundations/tokens/app_colors.dart';
import 'package:mube/src/design_system/foundations/tokens/app_typography.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';

class DeveloperToolsScreen extends ConsumerStatefulWidget {
  const DeveloperToolsScreen({super.key});

  @override
  ConsumerState<DeveloperToolsScreen> createState() =>
      _DeveloperToolsScreenState();
}

class _DeveloperToolsScreenState extends ConsumerState<DeveloperToolsScreen> {
  bool _isLoading = false;

  Future<void> _sendTestNotification() async {
    final currentUser = ref.read(currentUserProfileProvider).value;
    if (currentUser == null) {
      AppSnackBar.error(context, 'Usuário não autenticado');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Find a real seeded user to simulate as sender
      final usersQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isNotEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (usersQuery.docs.isEmpty) {
        if (mounted) {
          AppSnackBar.error(
            context,
            'Nenhum usuário encontrado. Execute o seeder primeiro.',
          );
        }
        return;
      }

      final senderDoc = usersQuery.docs.first;
      final senderId = senderDoc.id;
      final senderData = senderDoc.data();

      final profissionalData =
          senderData['profissional'] as Map<String, dynamic>?;
      final senderName =
          senderData['nome'] as String? ??
          profissionalData?['nomeArtistico'] as String? ??
          'Usuário Teste';

      final senderPhoto = senderData['foto'] as String?;

      // 2. Create a real conversation ID (sorted UIDs for consistency)
      final uids = [currentUser.uid, senderId]..sort();
      final realConversationId = '${uids[0]}_${uids[1]}';

      // 3. Create/update the conversation with real data
      final batch = FirebaseFirestore.instance.batch();

      final conversationRef = FirebaseFirestore.instance
          .collection('conversations')
          .doc(realConversationId);

      batch.set(conversationRef, {
        'participants': [currentUser.uid, senderId],
        'participantsMap': {currentUser.uid: true, senderId: true},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessageText': 'Teste de Push do Menu Debug 🐛',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': senderId,
        'readUntil': {
          currentUser.uid: Timestamp(0, 0),
          senderId: Timestamp.now(),
        },
      }, SetOptions(merge: true));

      // 4. Update previews for CURRENT user (recipient)
      final myPreviewRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('conversationPreviews')
          .doc(realConversationId);

      batch.set(myPreviewRef, {
        'id': realConversationId,
        'otherUserId': senderId,
        'otherUserName': senderName,
        'otherUserPhoto': senderPhoto,
        'lastMessageText': 'Teste de Push do Menu Debug 🐛',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': senderId,
        'unreadCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 5. Update previews for SENDER user
      final senderPreviewRef = FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .collection('conversationPreviews')
          .doc(realConversationId);

      batch.set(senderPreviewRef, {
        'id': realConversationId,
        'otherUserId': currentUser.uid,
        'otherUserName': currentUser.nome ?? 'Usuário',
        'otherUserPhoto': currentUser.foto,
        'lastMessageText': 'Teste de Push do Menu Debug 🐛',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': senderId,
        'unreadCount': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 6. Add the message (triggers Cloud Function for push notification)
      final messageRef = conversationRef.collection('messages').doc();
      batch.set(messageRef, {
        'senderId': senderId,
        'recipientId': currentUser.uid,
        'sender_name': senderName,
        'sender_photo_url': senderPhoto,
        'text': 'Teste de Push do Menu Debug 🐛',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'type': 'text',
      });

      await batch.commit();

      if (mounted) {
        AppSnackBar.success(context, 'Notificação de teste enviada! 🚀');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Erro: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(body: Center(child: Text('Acesso negado')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(
        title: Text('Ferramentas Dev 🛠️'),
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildToolCard(
            title: 'Testar Notificação Real',
            description:
                'Simula recebimento de mensagem de outro usuário com criação de chat real.',
            icon: Icons.notifications_active,
            onTap: _sendTestNotification,
            isLoading: _isLoading,
          ),
          // Outras ferramentas podem ser adicionadas aqui
        ],
      ),
    );
  }

  Widget _buildToolCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Card(
      color: AppColors.surface,
      child: ListTile(
        leading: Icon(icon, color: AppColors.brandPrimary),
        title: Text(
          title,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          description,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textTertiary,
              ),
        onTap: isLoading ? null : onTap,
      ),
    );
  }
}
