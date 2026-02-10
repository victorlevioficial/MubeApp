import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../design_system/components/buttons/app_button.dart';
import '../../../design_system/components/feedback/app_snackbar.dart';
import '../../../design_system/components/inputs/app_dropdown_field.dart';
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

  final List<File> _attachments = [];
  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    if (_attachments.length >= 3) {
      if (mounted) {
        AppSnackBar.error(context, 'Máximo de 3 anexos permitidos');
      }
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        // imageQuality is handled by storage repository, but we can do a light prescaling if needed
        // leaving empty to use original for now, or use max methods
      );

      if (image != null) {
        setState(() {
          _attachments.add(File(image.path));
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Erro ao selecionar imagem');
      }
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

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
            attachments: _attachments,
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
              AppDropdownField<String>(
                label: 'Categoria',
                value: _selectedCategory,
                items: _categories.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedCategory = value);
                },
                validator: (value) => value == null || value.isEmpty
                    ? 'Selecione uma categoria'
                    : null,
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

              const SizedBox(height: AppSpacing.s24),

              // Attachments
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Anexos (Opcional)', style: AppTypography.labelLarge),
                  Text(
                    '${_attachments.length}/3',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s8),

              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _attachments.length + 1,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.s8),
                  itemBuilder: (context, index) {
                    if (index == _attachments.length) {
                      // Add Button
                      return GestureDetector(
                        onTap: _attachments.length < 3 ? _pickImage : null,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: AppRadius.all12,
                            border: Border.all(
                              color: AppColors.surfaceHighlight,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Icon(
                            Icons.add_photo_alternate_outlined,
                            color: _attachments.length < 3
                                ? AppColors.primary
                                : AppColors.textDisabled,
                          ),
                        ),
                      );
                    }

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: AppRadius.all12,
                            image: DecorationImage(
                              image: FileImage(_attachments[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: -8,
                          right: -8,
                          child: GestureDetector(
                            onTap: () => _removeAttachment(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
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
