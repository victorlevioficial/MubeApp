import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../design_system/components/feedback/app_overlay.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../data/legal_content.dart';
import '../utils/pdf_generator.dart';

enum LegalDocumentType {
  termsOfUse,
  privacyPolicy;

  String get title {
    switch (this) {
      case LegalDocumentType.termsOfUse:
        return 'Termos de Uso';
      case LegalDocumentType.privacyPolicy:
        return 'Política de Privacidade';
    }
  }

  String get content {
    switch (this) {
      case LegalDocumentType.termsOfUse:
        return LegalContent.termsOfUse;
      case LegalDocumentType.privacyPolicy:
        return LegalContent.privacyPolicy;
    }
  }
}

class LegalDetailScreen extends StatelessWidget {
  final LegalDocumentType type;

  const LegalDetailScreen({super.key, required this.type});

  Future<void> _sharePdf() async {
    if (type == LegalDocumentType.termsOfUse) {
      await PdfGenerator.shareTermsOfUse();
    } else {
      await PdfGenerator.sharePrivacyPolicy();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        title: type.title,
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: _sharePdf,
            tooltip: 'Baixar/Compartilhar PDF',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.all16,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.all16,
              border: Border.all(color: AppColors.surfaceHighlight),
            ),
            child: _LegalDocumentMarkdown(type: type, padding: AppSpacing.all16),
          ),
        ),
      ),
    );
  }
}

class LegalDocumentDialog extends StatelessWidget {
  final LegalDocumentType type;

  const LegalDocumentDialog({super.key, required this.type});

  static Future<void> show({
    required BuildContext context,
    required LegalDocumentType type,
  }) {
    return AppOverlay.dialog<void>(
      context: context,
      builder: (context) => LegalDocumentDialog(type: type),
    );
  }

  Future<void> _sharePdf() async {
    if (type == LegalDocumentType.termsOfUse) {
      await PdfGenerator.shareTermsOfUse();
    } else {
      await PdfGenerator.sharePrivacyPolicy();
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;

    return Dialog(
      key: ValueKey('legal_document_dialog_${type.name}'),
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s24,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.all24,
        side: BorderSide(color: AppColors.surfaceHighlight),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 720, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s20,
                AppSpacing.s16,
                AppSpacing.s12,
                AppSpacing.s12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      key: ValueKey('legal_document_title_${type.name}'),
                      type.title,
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.ios_share_rounded),
                    onPressed: _sharePdf,
                    tooltip: 'Baixar/Compartilhar PDF',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Fechar',
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.surfaceHighlight),
            Expanded(
              child: _LegalDocumentMarkdown(
                type: type,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s20,
                  AppSpacing.s16,
                  AppSpacing.s20,
                  AppSpacing.s20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalDocumentMarkdown extends StatelessWidget {
  final LegalDocumentType type;
  final EdgeInsets padding;

  const _LegalDocumentMarkdown({
    required this.type,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Markdown(
      data: type.content,
      selectable: true,
      padding: padding,
      physics: const ClampingScrollPhysics(),
      styleSheet: MarkdownStyleSheet(
        h1: AppTypography.headlineMedium.copyWith(
          color: AppColors.primary,
          fontWeight: AppTypography.buttonPrimary.fontWeight,
        ),
        h2: AppTypography.titleLarge.copyWith(
          color: AppColors.textPrimary,
          fontWeight: AppTypography.buttonPrimary.fontWeight,
        ),
        h3: AppTypography.titleMedium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: AppTypography.buttonPrimary.fontWeight,
        ),
        p: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
          height: 1.45,
        ),
        blockquote: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
        listBullet: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        strong: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: AppTypography.buttonPrimary.fontWeight,
        ),
        horizontalRuleDecoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.surfaceHighlight)),
        ),
        blockquoteDecoration: BoxDecoration(
          color: AppColors.surfaceHighlight.withValues(alpha: 0.4),
          borderRadius: AppRadius.all8,
          border: const Border(
            left: BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        blockquotePadding: const EdgeInsets.all(AppSpacing.s12),
      ),
    );
  }
}
