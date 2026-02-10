import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common_widgets/formatters/title_case_formatter.dart';
import '../../../design_system/components/buttons/app_button.dart';
import '../../../design_system/components/feedback/app_snackbar.dart';
import '../../../design_system/components/inputs/app_text_field.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_type.dart';
import 'flows/onboarding_band_flow.dart';
import 'flows/onboarding_contractor_flow.dart';
import 'flows/onboarding_professional_flow.dart';
import 'flows/onboarding_studio_flow.dart';
import 'onboarding_controller.dart';
import 'onboarding_form_provider.dart';

class OnboardingFormScreen extends ConsumerStatefulWidget {
  const OnboardingFormScreen({super.key});

  @override
  ConsumerState<OnboardingFormScreen> createState() =>
      _OnboardingFormScreenState();
}

class _OnboardingFormScreenState extends ConsumerState<OnboardingFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers para campos comuns
  final _nomeController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();

  // Controllers Específicos (Profissional)
  final _idadeController = TextEditingController();
  final _generoController = TextEditingController(); // M/F/Outro
  final _instrumentoController = TextEditingController();
  final _generosMusicaisController =
      TextEditingController(); // Lista separada por virgula

  // Controllers Específicos (Estudio)
  final _servicosController = TextEditingController();

  // Foto (Simulada por URL ou deixar vazia se não tiver picker ainda)
  String? _fotoUrl;

  @override
  void dispose() {
    _nomeController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    _idadeController.dispose();
    _generoController.dispose();
    _instrumentoController.dispose();
    _generosMusicaisController.dispose();
    _servicosController.dispose();
    super.dispose();
  }

  void _submit(AppUser currentUser) {
    if (_formKey.currentState!.validate()) {
      final tipo = currentUser.tipoPerfil;
      /*
      // Foto é opcional agora para não travar o cadastro
      if (tipo != 'contratante' && (_fotoUrl == null || _fotoUrl!.isEmpty)) {
        AppSnackBar.show(
          context,
          'Foto de perfil é obrigatória.',
          isError: true,
        );
        return;
      }
      */

      // Montar Location Map
      final locationMap = {
        'cidade': _cidadeController.text.trim(),
        'estado': _estadoController.text.trim(),
        'manual': true,
      };

      // Montar Maps Específicos
      Map<String, dynamic>? dadosProfissional;
      Map<String, dynamic>? dadosBanda;
      Map<String, dynamic>? dadosEstudio;
      Map<String, dynamic>? dadosContratante;

      if (tipo == AppUserType.professional) {
        final idade = int.tryParse(_idadeController.text) ?? 0;
        if (idade < 18) {
          if (idade < 18) {
            AppSnackBar.show(
              context,
              'É necessário ser maior de 18 anos para se cadastrar como profissional.',
              isError: true,
            );
            return;
          }
          return;
        }

        dadosProfissional = {
          'idade': idade,
          'genero': _generoController.text.trim(),
          'instrumento': _instrumentoController.text.trim(),
          'generosMusicais': _generosMusicaisController.text
              .split(',')
              .map((e) => e.trim())
              .toList(),
          'isPublic': true,
        };
      } else if (tipo == AppUserType.studio) {
        dadosEstudio = {
          'servicosOferecidos': _servicosController.text
              .split(',')
              .map((e) => e.trim())
              .toList(),
          'isPublic': true,
        };
      } else if (tipo == AppUserType.contractor) {
        dadosContratante = {'isPublic': false};
      }

      ref
          .read(onboardingControllerProvider.notifier)
          .submitProfileForm(
            currentUser: currentUser,
            nome: _nomeController.text.trim(),
            location: locationMap,
            foto: _fotoUrl,
            dadosProfissional: dadosProfissional,
            dadosBanda: dadosBanda,
            dadosEstudio: dadosEstudio,
            dadosContratante: dadosContratante,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final userAsync = ref.watch(currentUserProfileProvider);

    // Listen to persistence changes
    ref.listen(onboardingFormProvider, (_, next) {
      if (_nomeController.text.isEmpty && next.nome != null) {
        _nomeController.text = next.nome!;
      }
      if (_cidadeController.text.isEmpty && next.cidade != null) {
        _cidadeController.text = next.cidade!;
      }
      if (_estadoController.text.isEmpty && next.estado != null) {
        _estadoController.text = next.estado!;
      }

      // Profissional fields map
      if (_generoController.text.isEmpty && next.genero != null) {
        _generoController.text = next.genero!;
      }
      if (_instrumentoController.text.isEmpty &&
          next.selectedInstruments.isNotEmpty) {
        _instrumentoController.text = next.selectedInstruments.first;
      }
      if (_generosMusicaisController.text.isEmpty &&
          next.selectedGenres.isNotEmpty) {
        _generosMusicaisController.text = next.selectedGenres.join(', ');
      }

      // Studio
      if (_servicosController.text.isEmpty &&
          next.selectedServices.isNotEmpty) {
        _servicosController.text = next.selectedServices.join(', ');
      }
    });

    return userAsync.when(
      skipLoadingOnReload: true,
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Erro: $err'))),
      data: (user) {
        if (user == null) return const SizedBox();
        if (user.tipoPerfil == null) {
          return const Scaffold(body: Center(child: Text('Tipo indefinido')));
        }

        // Delegate to Contractor Flow if applicable
        if (user.tipoPerfil == AppUserType.contractor) {
          return OnboardingContractorFlow(user: user);
        }

        // Delegate to Professional Flow if applicable
        if (user.tipoPerfil == AppUserType.professional) {
          return OnboardingProfessionalFlow(user: user);
        }

        // Delegate to Studio Flow if applicable
        if (user.tipoPerfil == AppUserType.studio) {
          return OnboardingStudioFlow(user: user);
        }

        // Delegate to Band Flow if applicable
        if (user.tipoPerfil == AppUserType.band) {
          return OnboardingBandFlow(user: user);
        }

        // Generic Flow for other types
        return Scaffold(
          appBar: AppAppBar(
            title: 'Completar Perfil',
            onBackPressed: () {
              ref
                  .read(onboardingControllerProvider.notifier)
                  .resetToTypeSelection(currentUser: user);
            },
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Cadastro: ${user.tipoPerfil!.label.toUpperCase()}',
                    style: AppTypography.titleLarge.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s24),

                  // Campos Comuns (Nome e Localização)
                  AppTextField(
                    fieldKey: const Key('onboarding_name_input'),
                    controller: _nomeController,
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [TitleCaseTextInputFormatter()],
                    label: user.tipoPerfil == AppUserType.band
                        ? 'Nome da Banda'
                        : (user.tipoPerfil == AppUserType.studio
                              ? 'Nome do Estúdio'
                              : 'Seu Nome'),
                    validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: AppSpacing.s16),

                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          fieldKey: const Key('onboarding_city_input'),
                          controller: _cidadeController,
                          label: 'Cidade',
                          validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s16),
                      Expanded(
                        child: AppTextField(
                          fieldKey: const Key('onboarding_state_input'),
                          controller: _estadoController,
                          label: 'Estado (UF)',
                          validator: (v) => v!.length != 2 ? 'Ex: SP' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s16),

                  // Campos Específicos
                  if (user.tipoPerfil == AppUserType.professional)
                    _buildProfissionalFields(),

                  if (user.tipoPerfil == AppUserType.studio)
                    _buildEstudioFields(),

                  // Contratante não tem campos extras além de nome/loc (mas já é handled acima)
                  const SizedBox(height: AppSpacing.s24),

                  // Foto Upload Fake
                  if (user.tipoPerfil != AppUserType.contractor)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Foto de Perfil',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        GestureDetector(
                          key: const Key('onboarding_photo_upload'),
                          onTap: () {
                            setState(() {
                              _fotoUrl = 'https://placeholder.com/user.jpg';
                            });
                            AppSnackBar.success(
                              context,
                              'Foto "enviada" com sucesso!',
                            );
                          },
                          child: Container(
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                              color: _fotoUrl != null
                                  ? Theme.of(context).colorScheme.surface
                                  : Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                              borderRadius: AppRadius.all12,
                              image: _fotoUrl != null
                                  ? const DecorationImage(
                                      image: CachedNetworkImageProvider(
                                        'https://via.placeholder.com/150',
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _fotoUrl == null
                                ? Icon(
                                    Icons.camera_alt,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  )
                                : null,
                          ),
                        ),
                        if (_fotoUrl == null)
                          Text(
                            'Toque para enviar (Opcional)',
                            style: AppTypography.bodySmall.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                      ],
                    ),

                  const SizedBox(height: AppSpacing.s48),
                  AppButton.primary(
                    key: const Key('onboarding_submit_button'),
                    text: 'Concluir Cadastro',
                    isLoading: state.isLoading,
                    onPressed: () => _submit(user),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfissionalFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextField(
                fieldKey: const Key('onboarding_age_input'),
                controller: _idadeController,
                label: 'Idade',
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
            ),
            const SizedBox(width: AppSpacing.s16),
            Expanded(
              child: AppTextField(
                fieldKey: const Key('onboarding_gender_input'),
                controller: _generoController,
                label: 'Gênero',
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s16),
        AppTextField(
          fieldKey: const Key('onboarding_instrument_input'),
          controller: _instrumentoController,
          label: 'Instrumento / Função',
          hint: 'Ex: Guitarrista, Baterista',
          validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
        ),
        const SizedBox(height: AppSpacing.s16),
        AppTextField(
          fieldKey: const Key('onboarding_genres_input'),
          controller: _generosMusicaisController,
          label: 'Gêneros Musicais',
          hint: 'Ex: Rock, Jazz, Blues',
          validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
        ),
      ],
    );
  }

  Widget _buildEstudioFields() {
    return Column(
      children: [
        AppTextField(
          fieldKey: const Key('onboarding_services_input'),
          controller: _servicosController,
          label: 'Serviços Oferecidos',
          hint: 'Ex: Gravação, Mixagem, Ensaio',
          validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
        ),
      ],
    );
  }
}
