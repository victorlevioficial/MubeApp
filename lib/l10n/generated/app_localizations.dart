import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// Nome do aplicativo
  ///
  /// In pt, this message translates to:
  /// **'Mube'**
  String get appName;

  /// No description provided for @common_ok.
  ///
  /// In pt, this message translates to:
  /// **'OK'**
  String get common_ok;

  /// No description provided for @common_cancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get common_cancel;

  /// No description provided for @common_save.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get common_save;

  /// No description provided for @common_delete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get common_delete;

  /// No description provided for @common_edit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get common_edit;

  /// No description provided for @common_loading.
  ///
  /// In pt, this message translates to:
  /// **'Carregando...'**
  String get common_loading;

  /// No description provided for @common_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro'**
  String get common_error;

  /// No description provided for @common_success.
  ///
  /// In pt, this message translates to:
  /// **'Sucesso'**
  String get common_success;

  /// No description provided for @common_retry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get common_retry;

  /// No description provided for @common_close.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get common_close;

  /// No description provided for @common_back.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get common_back;

  /// No description provided for @common_next.
  ///
  /// In pt, this message translates to:
  /// **'Próximo'**
  String get common_next;

  /// No description provided for @common_done.
  ///
  /// In pt, this message translates to:
  /// **'Concluir'**
  String get common_done;

  /// No description provided for @common_yes.
  ///
  /// In pt, this message translates to:
  /// **'Sim'**
  String get common_yes;

  /// No description provided for @common_no.
  ///
  /// In pt, this message translates to:
  /// **'Não'**
  String get common_no;

  /// No description provided for @auth_login_title.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get auth_login_title;

  /// No description provided for @auth_login_email_hint.
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get auth_login_email_hint;

  /// No description provided for @auth_login_password_hint.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get auth_login_password_hint;

  /// No description provided for @auth_login_button.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get auth_login_button;

  /// No description provided for @auth_login_forgot_password.
  ///
  /// In pt, this message translates to:
  /// **'Esqueceu a senha?'**
  String get auth_login_forgot_password;

  /// No description provided for @auth_login_no_account.
  ///
  /// In pt, this message translates to:
  /// **'Não tem uma conta?'**
  String get auth_login_no_account;

  /// No description provided for @auth_login_create_account.
  ///
  /// In pt, this message translates to:
  /// **'Criar conta'**
  String get auth_login_create_account;

  /// No description provided for @auth_login_error_invalid_credentials.
  ///
  /// In pt, this message translates to:
  /// **'E-mail ou senha incorretos'**
  String get auth_login_error_invalid_credentials;

  /// No description provided for @auth_login_error_user_not_found.
  ///
  /// In pt, this message translates to:
  /// **'Usuário não encontrado'**
  String get auth_login_error_user_not_found;

  /// No description provided for @auth_login_error_wrong_password.
  ///
  /// In pt, this message translates to:
  /// **'Senha incorreta'**
  String get auth_login_error_wrong_password;

  /// No description provided for @auth_register_title.
  ///
  /// In pt, this message translates to:
  /// **'Criar Conta'**
  String get auth_register_title;

  /// No description provided for @auth_register_email_hint.
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get auth_register_email_hint;

  /// No description provided for @auth_register_password_hint.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get auth_register_password_hint;

  /// No description provided for @auth_register_confirm_password_hint.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar senha'**
  String get auth_register_confirm_password_hint;

  /// No description provided for @auth_register_button.
  ///
  /// In pt, this message translates to:
  /// **'Criar conta'**
  String get auth_register_button;

  /// No description provided for @auth_register_has_account.
  ///
  /// In pt, this message translates to:
  /// **'Já tem uma conta?'**
  String get auth_register_has_account;

  /// No description provided for @auth_register_login.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get auth_register_login;

  /// No description provided for @auth_register_error_passwords_dont_match.
  ///
  /// In pt, this message translates to:
  /// **'As senhas não coincidem'**
  String get auth_register_error_passwords_dont_match;

  /// No description provided for @auth_register_error_email_in_use.
  ///
  /// In pt, this message translates to:
  /// **'Este e-mail já está em uso'**
  String get auth_register_error_email_in_use;

  /// No description provided for @auth_register_error_weak_password.
  ///
  /// In pt, this message translates to:
  /// **'Senha muito fraca'**
  String get auth_register_error_weak_password;

  /// No description provided for @home_title.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get home_title;

  /// No description provided for @home_search_hint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar...'**
  String get home_search_hint;

  /// No description provided for @home_feed_empty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum perfil encontrado'**
  String get home_feed_empty;

  /// No description provided for @home_feed_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar feed'**
  String get home_feed_error;

  /// No description provided for @search_title.
  ///
  /// In pt, this message translates to:
  /// **'Busca'**
  String get search_title;

  /// No description provided for @search_filter_title.
  ///
  /// In pt, this message translates to:
  /// **'Filtros'**
  String get search_filter_title;

  /// No description provided for @search_filter_category.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get search_filter_category;

  /// No description provided for @search_filter_distance.
  ///
  /// In pt, this message translates to:
  /// **'Distância'**
  String get search_filter_distance;

  /// No description provided for @search_filter_genre.
  ///
  /// In pt, this message translates to:
  /// **'Gênero musical'**
  String get search_filter_genre;

  /// No description provided for @search_filter_instrument.
  ///
  /// In pt, this message translates to:
  /// **'Instrumento'**
  String get search_filter_instrument;

  /// No description provided for @search_results_empty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum resultado encontrado'**
  String get search_results_empty;

  /// No description provided for @matchpoint_title.
  ///
  /// In pt, this message translates to:
  /// **'MatchPoint'**
  String get matchpoint_title;

  /// No description provided for @matchpoint_tab_explore.
  ///
  /// In pt, this message translates to:
  /// **'Explorar'**
  String get matchpoint_tab_explore;

  /// No description provided for @matchpoint_tab_matches.
  ///
  /// In pt, this message translates to:
  /// **'Matches'**
  String get matchpoint_tab_matches;

  /// No description provided for @matchpoint_no_more_cards.
  ///
  /// In pt, this message translates to:
  /// **'Não há mais perfis para mostrar'**
  String get matchpoint_no_more_cards;

  /// No description provided for @matchpoint_match_title.
  ///
  /// In pt, this message translates to:
  /// **'É um Match!'**
  String get matchpoint_match_title;

  /// No description provided for @matchpoint_match_message.
  ///
  /// In pt, this message translates to:
  /// **'Vocês curtiram um ao outro'**
  String get matchpoint_match_message;

  /// No description provided for @matchpoint_match_chat_button.
  ///
  /// In pt, this message translates to:
  /// **'Iniciar conversa'**
  String get matchpoint_match_chat_button;

  /// No description provided for @matchpoint_daily_limit_reached.
  ///
  /// In pt, this message translates to:
  /// **'Limite diário atingido'**
  String get matchpoint_daily_limit_reached;

  /// No description provided for @chat_title.
  ///
  /// In pt, this message translates to:
  /// **'Conversas'**
  String get chat_title;

  /// No description provided for @chat_empty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma conversa ainda'**
  String get chat_empty;

  /// No description provided for @chat_message_hint.
  ///
  /// In pt, this message translates to:
  /// **'Digite uma mensagem...'**
  String get chat_message_hint;

  /// No description provided for @chat_typing.
  ///
  /// In pt, this message translates to:
  /// **'Digitando...'**
  String get chat_typing;

  /// No description provided for @profile_title.
  ///
  /// In pt, this message translates to:
  /// **'Perfil'**
  String get profile_title;

  /// No description provided for @profile_edit_title.
  ///
  /// In pt, this message translates to:
  /// **'Editar Perfil'**
  String get profile_edit_title;

  /// No description provided for @profile_name_hint.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get profile_name_hint;

  /// No description provided for @profile_bio_hint.
  ///
  /// In pt, this message translates to:
  /// **'Bio'**
  String get profile_bio_hint;

  /// No description provided for @profile_location_hint.
  ///
  /// In pt, this message translates to:
  /// **'Localização'**
  String get profile_location_hint;

  /// No description provided for @profile_save_button.
  ///
  /// In pt, this message translates to:
  /// **'Salvar alterações'**
  String get profile_save_button;

  /// No description provided for @profile_gallery_title.
  ///
  /// In pt, this message translates to:
  /// **'Galeria'**
  String get profile_gallery_title;

  /// No description provided for @profile_gallery_add_photo.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar foto'**
  String get profile_gallery_add_photo;

  /// No description provided for @profile_gallery_add_video.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar vídeo'**
  String get profile_gallery_add_video;

  /// No description provided for @settings_title.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get settings_title;

  /// No description provided for @settings_account.
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get settings_account;

  /// No description provided for @settings_addresses.
  ///
  /// In pt, this message translates to:
  /// **'Meus Endereços'**
  String get settings_addresses;

  /// No description provided for @settings_edit_data.
  ///
  /// In pt, this message translates to:
  /// **'Editar Dados'**
  String get settings_edit_data;

  /// No description provided for @settings_favorites.
  ///
  /// In pt, this message translates to:
  /// **'Meus Favoritos'**
  String get settings_favorites;

  /// No description provided for @settings_band_management.
  ///
  /// In pt, this message translates to:
  /// **'Gerenciar Banda'**
  String get settings_band_management;

  /// No description provided for @settings_my_bands.
  ///
  /// In pt, this message translates to:
  /// **'Minhas Bandas'**
  String get settings_my_bands;

  /// No description provided for @settings_privacy.
  ///
  /// In pt, this message translates to:
  /// **'Privacidade'**
  String get settings_privacy;

  /// No description provided for @settings_notifications.
  ///
  /// In pt, this message translates to:
  /// **'Notificações'**
  String get settings_notifications;

  /// No description provided for @settings_help.
  ///
  /// In pt, this message translates to:
  /// **'Ajuda e Suporte'**
  String get settings_help;

  /// No description provided for @settings_rate_app.
  ///
  /// In pt, this message translates to:
  /// **'Avaliar o app'**
  String get settings_rate_app;

  /// No description provided for @settings_rate_app_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Deixar uma avaliação nas lojas'**
  String get settings_rate_app_subtitle;

  /// No description provided for @settings_rate_app_unavailable.
  ///
  /// In pt, this message translates to:
  /// **'A avaliação não está disponível agora.'**
  String get settings_rate_app_unavailable;

  /// No description provided for @settings_rate_app_store_open_error.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir a loja.'**
  String get settings_rate_app_store_open_error;

  /// No description provided for @settings_about.
  ///
  /// In pt, this message translates to:
  /// **'Sobre'**
  String get settings_about;

  /// No description provided for @settings_logout.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get settings_logout;

  /// No description provided for @settings_delete_account.
  ///
  /// In pt, this message translates to:
  /// **'Excluir conta'**
  String get settings_delete_account;

  /// No description provided for @settings_other.
  ///
  /// In pt, this message translates to:
  /// **'Outros'**
  String get settings_other;

  /// No description provided for @settings_my_gigs.
  ///
  /// In pt, this message translates to:
  /// **'Meus Gigs'**
  String get settings_my_gigs;

  /// No description provided for @settings_my_gigs_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Publicações, status e vagas'**
  String get settings_my_gigs_subtitle;

  /// No description provided for @settings_my_applications.
  ///
  /// In pt, this message translates to:
  /// **'Minhas Candidaturas'**
  String get settings_my_applications;

  /// No description provided for @settings_my_applications_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Acompanhar respostas e mensagens'**
  String get settings_my_applications_subtitle;

  /// No description provided for @settings_matchpoint_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Descoberta e histórico'**
  String get settings_matchpoint_subtitle;

  /// No description provided for @settings_addresses_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Gerenciar entregas'**
  String get settings_addresses_subtitle;

  /// No description provided for @settings_band_management_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Integrantes e convites'**
  String get settings_band_management_subtitle;

  /// No description provided for @settings_my_bands_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Convites e parcerias'**
  String get settings_my_bands_subtitle;

  /// No description provided for @settings_change_password.
  ///
  /// In pt, this message translates to:
  /// **'Alterar Senha'**
  String get settings_change_password;

  /// No description provided for @settings_privacy_visibility.
  ///
  /// In pt, this message translates to:
  /// **'Privacidade e Visibilidade'**
  String get settings_privacy_visibility;

  /// No description provided for @settings_privacy_visibility_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'MatchPoint, Busca, Bloqueios'**
  String get settings_privacy_visibility_subtitle;

  /// No description provided for @settings_terms_of_use.
  ///
  /// In pt, this message translates to:
  /// **'Termos de Uso'**
  String get settings_terms_of_use;

  /// No description provided for @settings_privacy_policy.
  ///
  /// In pt, this message translates to:
  /// **'Política de Privacidade'**
  String get settings_privacy_policy;

  /// No description provided for @settings_logout_account.
  ///
  /// In pt, this message translates to:
  /// **'Sair da Conta'**
  String get settings_logout_account;

  /// No description provided for @settings_logout_confirm_title.
  ///
  /// In pt, this message translates to:
  /// **'Sair da conta?'**
  String get settings_logout_confirm_title;

  /// No description provided for @settings_logout_confirm_message.
  ///
  /// In pt, this message translates to:
  /// **'Você precisará fazer login novamente.'**
  String get settings_logout_confirm_message;

  /// No description provided for @settings_change_password_email_missing.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível encontrar seu email.'**
  String get settings_change_password_email_missing;

  /// No description provided for @settings_change_password_message.
  ///
  /// In pt, this message translates to:
  /// **'Enviaremos um link de redefinição para:\n\n{email}\n\nDeseja continuar?'**
  String settings_change_password_message(Object email);

  /// No description provided for @settings_change_password_send.
  ///
  /// In pt, this message translates to:
  /// **'Enviar'**
  String get settings_change_password_send;

  /// No description provided for @settings_change_password_sending.
  ///
  /// In pt, this message translates to:
  /// **'Enviando email...'**
  String get settings_change_password_sending;

  /// No description provided for @settings_change_password_email_sent.
  ///
  /// In pt, this message translates to:
  /// **'Email enviado! Verifique sua caixa de entrada.'**
  String get settings_change_password_email_sent;

  /// No description provided for @edit_profile_update_success.
  ///
  /// In pt, this message translates to:
  /// **'Perfil atualizado com sucesso!'**
  String get edit_profile_update_success;

  /// No description provided for @edit_profile_media_still_processing.
  ///
  /// In pt, this message translates to:
  /// **'Aguarde o processamento da mídia terminar antes de sair.'**
  String get edit_profile_media_still_processing;

  /// No description provided for @edit_profile_discard_title.
  ///
  /// In pt, this message translates to:
  /// **'Descartar alterações?'**
  String get edit_profile_discard_title;

  /// No description provided for @edit_profile_discard_message.
  ///
  /// In pt, this message translates to:
  /// **'Você tem alterações não salvas. Deseja realmente sair sem salvar?'**
  String get edit_profile_discard_message;

  /// No description provided for @edit_profile_discard_confirm.
  ///
  /// In pt, this message translates to:
  /// **'Descartar'**
  String get edit_profile_discard_confirm;

  /// No description provided for @edit_profile_music_links_revise.
  ///
  /// In pt, this message translates to:
  /// **'Revise os links musicais preenchidos.'**
  String get edit_profile_music_links_revise;

  /// No description provided for @delete_account_error_title.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível excluir'**
  String get delete_account_error_title;

  /// No description provided for @delete_account_type_to_confirm.
  ///
  /// In pt, this message translates to:
  /// **'Para confirmar, digite \"{word}\" abaixo.'**
  String delete_account_type_to_confirm(String word);

  /// No description provided for @delete_account_session_issue.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível validar sua sessão agora. Saia e entre novamente e tente excluir a conta outra vez.'**
  String get delete_account_session_issue;

  /// No description provided for @settings_delete_confirm_title.
  ///
  /// In pt, this message translates to:
  /// **'Excluir conta?'**
  String get settings_delete_confirm_title;

  /// No description provided for @settings_delete_confirm_message.
  ///
  /// In pt, this message translates to:
  /// **'Sua conta e todos os dados associados a ela serão excluídos permanentemente. Esta ação não pode ser desfeita.'**
  String get settings_delete_confirm_message;

  /// No description provided for @settings_delete_in_progress.
  ///
  /// In pt, this message translates to:
  /// **'Excluindo conta...'**
  String get settings_delete_in_progress;

  /// No description provided for @settings_delete_success.
  ///
  /// In pt, this message translates to:
  /// **'Conta excluída com sucesso.'**
  String get settings_delete_success;

  /// No description provided for @settings_delete_requires_recent_login.
  ///
  /// In pt, this message translates to:
  /// **'Por segurança, faça login novamente antes de excluir sua conta.'**
  String get settings_delete_requires_recent_login;

  /// No description provided for @settings_error_with_details.
  ///
  /// In pt, this message translates to:
  /// **'Erro: {error}'**
  String settings_error_with_details(Object error);

  /// No description provided for @settings_profile_guest_name.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo'**
  String get settings_profile_guest_name;

  /// No description provided for @settings_profile_guest_email.
  ///
  /// In pt, this message translates to:
  /// **'Visitante'**
  String get settings_profile_guest_email;

  /// No description provided for @settings_profile_apple_private_email.
  ///
  /// In pt, this message translates to:
  /// **'Email protegido pela Apple'**
  String get settings_profile_apple_private_email;

  /// No description provided for @settings_profile_favorites_label.
  ///
  /// In pt, this message translates to:
  /// **'Favoritos'**
  String get settings_profile_favorites_label;

  /// No description provided for @settings_profile_type_label.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de Perfil'**
  String get settings_profile_type_label;

  /// No description provided for @settings_profile_type_professional.
  ///
  /// In pt, this message translates to:
  /// **'Profissional'**
  String get settings_profile_type_professional;

  /// No description provided for @settings_profile_type_band.
  ///
  /// In pt, this message translates to:
  /// **'Banda'**
  String get settings_profile_type_band;

  /// No description provided for @settings_profile_type_studio.
  ///
  /// In pt, this message translates to:
  /// **'Estúdio'**
  String get settings_profile_type_studio;

  /// No description provided for @settings_profile_type_contractor.
  ///
  /// In pt, this message translates to:
  /// **'Contratante'**
  String get settings_profile_type_contractor;

  /// No description provided for @settings_user_not_found.
  ///
  /// In pt, this message translates to:
  /// **'Usuário não encontrado'**
  String get settings_user_not_found;

  /// No description provided for @settings_login_again.
  ///
  /// In pt, this message translates to:
  /// **'Faça login novamente.'**
  String get settings_login_again;

  /// No description provided for @settings_section_visibility.
  ///
  /// In pt, this message translates to:
  /// **'Visibilidade'**
  String get settings_section_visibility;

  /// No description provided for @settings_section_security.
  ///
  /// In pt, this message translates to:
  /// **'Segurança'**
  String get settings_section_security;

  /// No description provided for @settings_privacy_home_visibility_title.
  ///
  /// In pt, this message translates to:
  /// **'Aparecer na Home e Busca'**
  String get settings_privacy_home_visibility_title;

  /// No description provided for @settings_privacy_home_visibility_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Se desativado, seu perfil não aparecerá nas buscas gerais nem no feed.'**
  String get settings_privacy_home_visibility_subtitle;

  /// No description provided for @settings_privacy_matchpoint_title.
  ///
  /// In pt, this message translates to:
  /// **'Ativar MatchPoint'**
  String get settings_privacy_matchpoint_title;

  /// No description provided for @settings_privacy_matchpoint_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Se desativado, você não aparecerá para ninguém no MatchPoint e não receberá novos matches.'**
  String get settings_privacy_matchpoint_subtitle;

  /// No description provided for @settings_privacy_public_profile_title.
  ///
  /// In pt, this message translates to:
  /// **'Perfil público'**
  String get settings_privacy_public_profile_title;

  /// No description provided for @settings_privacy_public_profile_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Permite que seu local apareça na busca e tenha link compartilhável.'**
  String get settings_privacy_public_profile_subtitle;

  /// No description provided for @settings_privacy_public_profile_photo_required.
  ///
  /// In pt, this message translates to:
  /// **'Adicione uma foto de perfil antes de ativar o perfil público.'**
  String get settings_privacy_public_profile_photo_required;

  /// No description provided for @settings_privacy_public_profile_update_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao atualizar perfil público: {error}'**
  String settings_privacy_public_profile_update_error(Object error);

  /// No description provided for @settings_privacy_public_profile_updated.
  ///
  /// In pt, this message translates to:
  /// **'Perfil público atualizado.'**
  String get settings_privacy_public_profile_updated;

  /// No description provided for @settings_privacy_public_chat_title.
  ///
  /// In pt, this message translates to:
  /// **'Chat público'**
  String get settings_privacy_public_chat_title;

  /// No description provided for @settings_privacy_public_chat_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Se desativado, novas mensagens de quem ainda não tem vínculo com você irão para Solicitações.'**
  String get settings_privacy_public_chat_subtitle;

  /// No description provided for @settings_privacy_chat_update_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao atualizar privacidade do chat: {error}'**
  String settings_privacy_chat_update_error(Object error);

  /// No description provided for @settings_privacy_chat_promote_error.
  ///
  /// In pt, this message translates to:
  /// **'Chat atualizado, mas houve falha ao promover solicitações: {error}'**
  String settings_privacy_chat_promote_error(Object error);

  /// No description provided for @settings_privacy_chat_updated.
  ///
  /// In pt, this message translates to:
  /// **'Privacidade do chat atualizada.'**
  String get settings_privacy_chat_updated;

  /// No description provided for @settings_blocked_users_title.
  ///
  /// In pt, this message translates to:
  /// **'Usuários Bloqueados'**
  String get settings_blocked_users_title;

  /// No description provided for @settings_blocked_users_load_error.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar usuários bloqueados'**
  String get settings_blocked_users_load_error;

  /// No description provided for @settings_blocked_users_details_error.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os detalhes dos bloqueios'**
  String get settings_blocked_users_details_error;

  /// No description provided for @settings_blocked_users_empty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum usuário bloqueado'**
  String get settings_blocked_users_empty;

  /// No description provided for @settings_blocked_users_details_not_found.
  ///
  /// In pt, this message translates to:
  /// **'Os usuários bloqueados não foram encontrados.'**
  String get settings_blocked_users_details_not_found;

  /// No description provided for @settings_blocked_users_count.
  ///
  /// In pt, this message translates to:
  /// **'{count} usuários'**
  String settings_blocked_users_count(Object count);

  /// No description provided for @settings_unblock.
  ///
  /// In pt, this message translates to:
  /// **'Desbloquear'**
  String get settings_unblock;

  /// No description provided for @settings_user_unblocked.
  ///
  /// In pt, this message translates to:
  /// **'Usuário desbloqueado'**
  String get settings_user_unblocked;

  /// No description provided for @settings_addresses_loading.
  ///
  /// In pt, this message translates to:
  /// **'Carregando endereços...'**
  String get settings_addresses_loading;

  /// No description provided for @settings_addresses_load_error_title.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar seus endereços'**
  String get settings_addresses_load_error_title;

  /// No description provided for @settings_addresses_load_error_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Tente novamente para recuperar seus locais salvos.'**
  String get settings_addresses_load_error_subtitle;

  /// No description provided for @settings_addresses_session_expired_title.
  ///
  /// In pt, this message translates to:
  /// **'Sessão expirada'**
  String get settings_addresses_session_expired_title;

  /// No description provided for @settings_addresses_session_expired_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Entre novamente para gerenciar seus endereços.'**
  String get settings_addresses_session_expired_subtitle;

  /// No description provided for @settings_addresses_saved_group.
  ///
  /// In pt, this message translates to:
  /// **'Endereços salvos'**
  String get settings_addresses_saved_group;

  /// No description provided for @settings_addresses_empty_title.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum endereço salvo'**
  String get settings_addresses_empty_title;

  /// No description provided for @settings_addresses_empty_subtitle.
  ///
  /// In pt, this message translates to:
  /// **'Adicione um endereço para definir sua localização principal no app.'**
  String get settings_addresses_empty_subtitle;

  /// No description provided for @settings_addresses_empty_action.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar primeiro endereço'**
  String get settings_addresses_empty_action;

  /// No description provided for @settings_addresses_overview_title.
  ///
  /// In pt, this message translates to:
  /// **'Gerenciar endereços'**
  String get settings_addresses_overview_title;

  /// No description provided for @settings_addresses_overview_count.
  ///
  /// In pt, this message translates to:
  /// **'{savedCount} de {maxCount} endereços salvos'**
  String settings_addresses_overview_count(Object maxCount, Object savedCount);

  /// No description provided for @settings_addresses_primary_label.
  ///
  /// In pt, this message translates to:
  /// **'Endereço principal'**
  String get settings_addresses_primary_label;

  /// No description provided for @settings_addresses_search_unavailable.
  ///
  /// In pt, this message translates to:
  /// **'Busca automática indisponível no momento.'**
  String get settings_addresses_search_unavailable;

  /// No description provided for @settings_addresses_add_new.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar novo endereço'**
  String get settings_addresses_add_new;

  /// No description provided for @settings_addresses_limit_reached.
  ///
  /// In pt, this message translates to:
  /// **'Limite de {maxCount} endereços'**
  String settings_addresses_limit_reached(Object maxCount);

  /// No description provided for @settings_addresses_use_current_location.
  ///
  /// In pt, this message translates to:
  /// **'Usar minha localização atual'**
  String get settings_addresses_use_current_location;

  /// No description provided for @settings_addresses_limit_warning.
  ///
  /// In pt, this message translates to:
  /// **'Limite de {maxCount} endereços atingido.'**
  String settings_addresses_limit_warning(Object maxCount);

  /// No description provided for @settings_addresses_search_service_unavailable.
  ///
  /// In pt, this message translates to:
  /// **'Busca de endereço indisponível no momento. Tente novamente em instantes.'**
  String get settings_addresses_search_service_unavailable;

  /// No description provided for @settings_addresses_invalid_selection.
  ///
  /// In pt, this message translates to:
  /// **'Escolha um endereço válido para salvar.'**
  String get settings_addresses_invalid_selection;

  /// No description provided for @settings_addresses_add_success.
  ///
  /// In pt, this message translates to:
  /// **'Endereço adicionado e definido como principal.'**
  String get settings_addresses_add_success;

  /// No description provided for @settings_addresses_save_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar endereço: {error}'**
  String settings_addresses_save_error(Object error);

  /// No description provided for @settings_addresses_current_location_unavailable.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível determinar o endereço da localização atual.'**
  String get settings_addresses_current_location_unavailable;

  /// No description provided for @settings_addresses_confirm_current_location.
  ///
  /// In pt, this message translates to:
  /// **'Salvar endereço'**
  String get settings_addresses_confirm_current_location;

  /// No description provided for @settings_addresses_current_location_error.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível obter sua localização atual: {error}'**
  String settings_addresses_current_location_error(Object error);

  /// No description provided for @settings_addresses_permission_denied.
  ///
  /// In pt, this message translates to:
  /// **'Permissão de localização negada.'**
  String get settings_addresses_permission_denied;

  /// No description provided for @settings_addresses_permission_denied_forever.
  ///
  /// In pt, this message translates to:
  /// **'Permissão de localização negada permanentemente.'**
  String get settings_addresses_permission_denied_forever;

  /// No description provided for @settings_addresses_service_disabled.
  ///
  /// In pt, this message translates to:
  /// **'GPS desativado. Ative o serviço de localização.'**
  String get settings_addresses_service_disabled;

  /// No description provided for @settings_addresses_api_quota_exceeded.
  ///
  /// In pt, this message translates to:
  /// **'Limite da Google API atingido. Tente novamente mais tarde.'**
  String get settings_addresses_api_quota_exceeded;

  /// No description provided for @settings_addresses_primary_updated.
  ///
  /// In pt, this message translates to:
  /// **'Endereço principal atualizado.'**
  String get settings_addresses_primary_updated;

  /// No description provided for @settings_addresses_update_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao atualizar endereço: {error}'**
  String settings_addresses_update_error(Object error);

  /// No description provided for @settings_addresses_minimum_one_warning.
  ///
  /// In pt, this message translates to:
  /// **'Pelo menos 1 endereço deve permanecer salvo.'**
  String get settings_addresses_minimum_one_warning;

  /// No description provided for @settings_addresses_delete_confirm_title.
  ///
  /// In pt, this message translates to:
  /// **'Excluir endereço?'**
  String get settings_addresses_delete_confirm_title;

  /// No description provided for @settings_addresses_delete_confirm_message.
  ///
  /// In pt, this message translates to:
  /// **'Deseja excluir este endereço salvo?'**
  String get settings_addresses_delete_confirm_message;

  /// No description provided for @settings_addresses_delete_success.
  ///
  /// In pt, this message translates to:
  /// **'Endereço excluído.'**
  String get settings_addresses_delete_success;

  /// No description provided for @settings_addresses_delete_error.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao excluir endereço: {error}'**
  String settings_addresses_delete_error(Object error);

  /// No description provided for @settings_addresses_session_expired_exception.
  ///
  /// In pt, this message translates to:
  /// **'Sessão expirada. Entre novamente.'**
  String get settings_addresses_session_expired_exception;

  /// No description provided for @settings_addresses_primary_missing_coordinates.
  ///
  /// In pt, this message translates to:
  /// **'Endereço principal sem coordenadas válidas.'**
  String get settings_addresses_primary_missing_coordinates;

  /// No description provided for @settings_addresses_primary_missing_city_state.
  ///
  /// In pt, this message translates to:
  /// **'Endereço principal sem cidade e estado válidos.'**
  String get settings_addresses_primary_missing_city_state;

  /// No description provided for @settings_address_card_primary_fallback_title.
  ///
  /// In pt, this message translates to:
  /// **'Endereço principal'**
  String get settings_address_card_primary_fallback_title;

  /// No description provided for @settings_address_card_saved_fallback_title.
  ///
  /// In pt, this message translates to:
  /// **'Endereço salvo'**
  String get settings_address_card_saved_fallback_title;

  /// No description provided for @settings_address_card_primary_summary.
  ///
  /// In pt, this message translates to:
  /// **'Em uso como referência principal.'**
  String get settings_address_card_primary_summary;

  /// No description provided for @settings_address_card_saved_summary.
  ///
  /// In pt, this message translates to:
  /// **'Disponível para virar endereço principal.'**
  String get settings_address_card_saved_summary;

  /// No description provided for @settings_address_card_zip_code.
  ///
  /// In pt, this message translates to:
  /// **'CEP {postalCode}'**
  String settings_address_card_zip_code(Object postalCode);

  /// No description provided for @settings_address_card_gps_ok.
  ///
  /// In pt, this message translates to:
  /// **'GPS ok'**
  String get settings_address_card_gps_ok;

  /// No description provided for @settings_address_card_status_primary.
  ///
  /// In pt, this message translates to:
  /// **'Principal'**
  String get settings_address_card_status_primary;

  /// No description provided for @settings_address_card_status_saved.
  ///
  /// In pt, this message translates to:
  /// **'Salvo'**
  String get settings_address_card_status_saved;

  /// No description provided for @settings_address_card_set_primary.
  ///
  /// In pt, this message translates to:
  /// **'Definir principal'**
  String get settings_address_card_set_primary;

  /// No description provided for @settings_address_card_delete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir endereço'**
  String get settings_address_card_delete;

  /// No description provided for @settings_address_card_delete_disabled_tooltip.
  ///
  /// In pt, this message translates to:
  /// **'Pelo menos 1 endereço deve permanecer salvo'**
  String get settings_address_card_delete_disabled_tooltip;

  /// No description provided for @settings_address_card_active.
  ///
  /// In pt, this message translates to:
  /// **'Endereço ativo'**
  String get settings_address_card_active;

  /// No description provided for @settings_app_language.
  ///
  /// In pt, this message translates to:
  /// **'Idioma do app'**
  String get settings_app_language;

  /// No description provided for @settings_app_theme.
  ///
  /// In pt, this message translates to:
  /// **'Tema do app'**
  String get settings_app_theme;

  /// No description provided for @settings_language_device.
  ///
  /// In pt, this message translates to:
  /// **'Usar idioma do dispositivo'**
  String get settings_language_device;

  /// No description provided for @settings_language_portuguese_brazil.
  ///
  /// In pt, this message translates to:
  /// **'Português (Brasil)'**
  String get settings_language_portuguese_brazil;

  /// No description provided for @settings_language_english.
  ///
  /// In pt, this message translates to:
  /// **'English'**
  String get settings_language_english;

  /// No description provided for @settings_theme_follow_system.
  ///
  /// In pt, this message translates to:
  /// **'Seguir sistema'**
  String get settings_theme_follow_system;

  /// No description provided for @settings_theme_always_dark.
  ///
  /// In pt, this message translates to:
  /// **'Sempre escuro'**
  String get settings_theme_always_dark;

  /// No description provided for @settings_apply_preference.
  ///
  /// In pt, this message translates to:
  /// **'Aplicar'**
  String get settings_apply_preference;

  /// Mensagem exibida ao atualizar o idioma do app
  ///
  /// In pt, this message translates to:
  /// **'Idioma atualizado para {language}.'**
  String settings_language_updated(String language);

  /// Mensagem exibida ao atualizar o tema do app
  ///
  /// In pt, this message translates to:
  /// **'Tema atualizado para {theme}.'**
  String settings_theme_updated(String theme);

  /// No description provided for @onboarding_type_title.
  ///
  /// In pt, this message translates to:
  /// **'Escolha seu tipo de perfil'**
  String get onboarding_type_title;

  /// No description provided for @onboarding_type_professional.
  ///
  /// In pt, this message translates to:
  /// **'Profissional'**
  String get onboarding_type_professional;

  /// No description provided for @onboarding_type_professional_desc.
  ///
  /// In pt, this message translates to:
  /// **'Músicos, cantores, DJs, equipe técnica'**
  String get onboarding_type_professional_desc;

  /// No description provided for @onboarding_type_band.
  ///
  /// In pt, this message translates to:
  /// **'Banda'**
  String get onboarding_type_band;

  /// No description provided for @onboarding_type_band_desc.
  ///
  /// In pt, this message translates to:
  /// **'Grupos musicais'**
  String get onboarding_type_band_desc;

  /// No description provided for @onboarding_type_studio.
  ///
  /// In pt, this message translates to:
  /// **'Estúdio'**
  String get onboarding_type_studio;

  /// No description provided for @onboarding_type_studio_desc.
  ///
  /// In pt, this message translates to:
  /// **'Estúdios de gravação'**
  String get onboarding_type_studio_desc;

  /// No description provided for @onboarding_type_contractor.
  ///
  /// In pt, this message translates to:
  /// **'Contratante'**
  String get onboarding_type_contractor;

  /// No description provided for @onboarding_type_contractor_desc.
  ///
  /// In pt, this message translates to:
  /// **'Organizadores de eventos, casas de show'**
  String get onboarding_type_contractor_desc;

  /// No description provided for @error_generic.
  ///
  /// In pt, this message translates to:
  /// **'Algo deu errado. Tente novamente.'**
  String get error_generic;

  /// No description provided for @error_network.
  ///
  /// In pt, this message translates to:
  /// **'Sem conexão com a internet'**
  String get error_network;

  /// No description provided for @error_server.
  ///
  /// In pt, this message translates to:
  /// **'Erro no servidor. Tente mais tarde.'**
  String get error_server;

  /// No description provided for @error_unauthorized.
  ///
  /// In pt, this message translates to:
  /// **'Sessão expirada. Faça login novamente.'**
  String get error_unauthorized;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
