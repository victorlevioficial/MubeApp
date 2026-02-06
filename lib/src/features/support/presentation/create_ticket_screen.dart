import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/buttons/app_button.dart';
import '../../../design_system/components/feedback/app_snackbar.dart';
import '../../../design_system/components/inputs/app_text_field.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import 'support_controller.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'feedback'; // Default

  final Map<String, String> _categories = {
    'bug': 'Reportar um Problema',
    'feedback': 'Sugestão ou Feedback',
    'account': 'Problema na Conta',
    'other': 'Outro Assunto',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(supportControllerProvider.notifier)
          .submitTicket(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _selectedCategory,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(supportControllerProvider, (prev, next) {
      if (next.hasValue && !next.isLoading && !next.hasError) {
        if (context.mounted) {
          AppSnackBar.success(context, 'Ticket enviado com sucesso!');
          context.pop(); // Go back to Support Hub
        }
      } else if (next.hasError) {
        if (context.mounted) {
          AppSnackBar.error(context, 'Erro ao enviar: ${next.error}');
        }
      }
    });

    final isLoading = ref.watch(supportControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Novo Ticket'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Como podemos ajudar?', style: AppTypography.headlineMedium),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Descreva seu problema ou sugestão abaixo.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.s24),

              // Category Selector
              Text('Categoria', style: AppTypography.labelLarge),
              const SizedBox(height: AppSpacing.s8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.all12,
                  border: Border.all(color: AppColors.surfaceHighlight),
                ),
                padding: AppSpacing.h16,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    dropdownColor: AppColors.surface,
                    style: AppTypography.bodyMedium,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.primary,
                    ),
                    items: _categories.entries.map((e) {
                      return DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedCategory = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s16),

              // Title
              AppTextField(
                controller: _titleController,
                label: 'Assunto',
                hint: 'Resumo do problema',
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o assunto' : null,
              ),
              const SizedBox(height: AppSpacing.s16),

              // Description
              AppTextField(
                controller: _descriptionController,
                label: 'Descrição Detalhada',
                hint: 'Conte detalhes do que aconteceu...',
                maxLines: 5,
                validator: (v) => v == null || v.length < 10
                    ? 'Descreva com mais detalhes'
                    : null,
              ),

              const SizedBox(height: AppSpacing.s32),

              AppButton.primary(
                text: 'Enviar Solicitação',
                isLoading: isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
