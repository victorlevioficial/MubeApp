import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../common_widgets/primary_button.dart';
import '../../../../common_widgets/secondary_button.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/foundations/app_typography.dart';
import '../../../auth/domain/app_user.dart';

class MatchSuccessScreen extends StatefulWidget {
  final AppUser currentUser;
  final AppUser matchUser;

  const MatchSuccessScreen({
    super.key,
    required this.currentUser,
    required this.matchUser,
  });

  @override
  State<MatchSuccessScreen> createState() => _MatchSuccessScreenState();
}

class _MatchSuccessScreenState extends State<MatchSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background.withValues(alpha: 0.95),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background Effects (Placeholder for Confetti)
          // You can add a Lottie animation here later
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    children: [
                      Text(
                        "IT'S A",
                        style: AppTypography.headlineMedium.copyWith(
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
                      Text(
                        'MATCH!',
                        style: AppTypography.headlineLarge.copyWith(
                          fontSize: 48,
                          color: AppColors.brandPrimary,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s48),

                // Avatars
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Current User (Left)
                      Positioned(
                        left: 20,
                        child: _buildAvatar(widget.currentUser.foto, -15),
                      ),
                      // Match User (Right)
                      Positioned(
                        right: 20,
                        child: _buildAvatar(widget.matchUser.foto, 15),
                      ),
                      // Icon in center
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brandPrimary.withValues(
                                alpha: 0.5,
                              ),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: AppColors.brandPrimary,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.s16),
                Text(
                  'Você e ${widget.matchUser.nome} se curtiram!',
                  style: AppTypography.bodyLarge.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.s64),

                // Buttons
                PrimaryButton(
                  text: 'Mandar Mensagem',
                  onPressed: () {
                    // Navigate to Chat (to be implemented)
                    context.pop();
                    // context.push('/chat/${widget.matchUser.uid}');
                  },
                ),
                const SizedBox(height: AppSpacing.s16),
                SizedBox(
                  width: double.infinity,
                  child: SecondaryButton(
                    text: 'Continuar Deslizando',
                    onPressed: () => context.pop(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? url, double angle) {
    return Transform.rotate(
      angle: angle * 3.14159 / 180,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          image: url != null
              ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
              : null,
          color: AppColors.surfaceHighlight,
        ),
        child: url == null
            ? const Icon(Icons.person, size: 60, color: Colors.white)
            : null,
      ),
    );
  }
}
