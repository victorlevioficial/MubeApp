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
