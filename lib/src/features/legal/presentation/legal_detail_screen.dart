import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/foundations/tokens/app_colors.dart';
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
      appBar: AppBar(
        title: Text(
          type.title,
          style: AppTypography.headlineSmall.copyWith(fontSize: 18),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.primary),
            onPressed: _sharePdf,
            tooltip: 'Baixar/Compartilhar PDF',
          ),
        ],
      ),
      body: Markdown(
        data: type.content,
        styleSheet: MarkdownStyleSheet(
          h1: AppTypography.headlineMedium.copyWith(
            color: AppColors.primary,
          ),
          h2: AppTypography.headlineSmall.copyWith(
            color: AppColors.textPrimary,
          ),
          h3: AppTypography.titleLarge.copyWith(color: AppColors.textPrimary),
          p: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
          listBullet: const TextStyle(color: AppColors.textSecondary),
          strong: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        padding: const EdgeInsets.all(20),
      ),
    );
  }
}
