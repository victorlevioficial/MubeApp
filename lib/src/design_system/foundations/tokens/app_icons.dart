import 'package:flutter/material.dart';

/// Tokens de ícones do Design System Mube.
///
/// Centraliza todos os ícones usados no aplicativo para garantir
/// consistência e facilitar manutenção.
///
/// Uso recomendado:
/// ```dart
/// Icon(AppIcons.arrowBack)
/// Icon(AppIcons.search)
/// ```
class AppIcons {
  const AppIcons._();

  // ===========================================================================
  // ARROWS
  // ===========================================================================

  /// Seta para voltar (iOS style)
  static const IconData arrowBack = Icons.arrow_back_ios;

  /// Seta para avançar
  static const IconData arrowForward = Icons.arrow_forward_ios;

  /// Seta para cima
  static const IconData arrowUp = Icons.keyboard_arrow_up;

  /// Seta para baixo
  static const IconData arrowDown = Icons.keyboard_arrow_down;

  /// Seta dropdown
  static const IconData dropdown = Icons.keyboard_arrow_down;

  /// Seta de expandir
  static const IconData expand = Icons.expand_more;

  /// Seta de recolher
  static const IconData collapse = Icons.expand_less;

  // ===========================================================================
  // NAVIGATION
  // ===========================================================================

  /// Ícone de home
  static const IconData home = Icons.home;
  static const IconData homeOutlined = Icons.home_outlined;

  /// Ícone de busca
  static const IconData search = Icons.search;
  static const IconData searchOutlined = Icons.search_outlined;

  /// Ícone de configurações
  static const IconData settings = Icons.settings;
  static const IconData settingsOutlined = Icons.settings_outlined;

  /// Ícone de perfil
  static const IconData profile = Icons.person;
  static const IconData profileOutlined = Icons.person_outline;

  /// Ícone de menu
  static const IconData menu = Icons.menu;

  /// Ícone de mais opções
  static const IconData more = Icons.more_vert;
  static const IconData moreHorizontal = Icons.more_horiz;

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  /// Ícone de adicionar
  static const IconData add = Icons.add;

  /// Ícone de editar
  static const IconData edit = Icons.edit;
  static const IconData editOutlined = Icons.edit_outlined;

  /// Ícone de deletar
  static const IconData delete = Icons.delete;
  static const IconData deleteOutlined = Icons.delete_outline;

  /// Ícone de fechar
  static const IconData close = Icons.close;

  /// Ícone de check
  static const IconData check = Icons.check;
  static const IconData checkCircle = Icons.check_circle;
  static const IconData checkCircleOutlined = Icons.check_circle_outline;

  /// Ícone de cancelar
  static const IconData cancel = Icons.cancel;
  static const IconData cancelOutlined = Icons.cancel_outlined;

  /// Ícone de favorito
  static const IconData favorite = Icons.favorite;
  static const IconData favoriteOutlined = Icons.favorite_outline;
  static const IconData favoriteBorder = Icons.favorite_border;

  /// Ícone de compartilhar
  static const IconData share = Icons.share;
  static const IconData shareOutlined = Icons.share_outlined;

  /// Ícone de copiar
  static const IconData copy = Icons.content_copy;

  /// Ícone de filtro
  static const IconData filter = Icons.filter_list;

  /// Ícone de ordenar
  static const IconData sort = Icons.sort;

  // ===========================================================================
  // INPUT
  // ===========================================================================

  /// Ícone de visibilidade (mostrar senha)
  static const IconData visibility = Icons.visibility;
  static const IconData visibilityOutlined = Icons.visibility_outlined;

  /// Ícone de visibilidade off (esconder senha)
  static const IconData visibilityOff = Icons.visibility_off;
  static const IconData visibilityOffOutlined = Icons.visibility_off_outlined;

  /// Ícone de calendário
  static const IconData calendar = Icons.calendar_today;
  static const IconData calendarToday = Icons.calendar_today;

  /// Ícone de relógio
  static const IconData clock = Icons.access_time;

  /// Ícone de localização
  static const IconData location = Icons.location_on;
  static const IconData locationOutlined = Icons.location_on_outlined;

  /// Ícone de email
  static const IconData email = Icons.email;
  static const IconData emailOutlined = Icons.email_outlined;

  /// Ícone de telefone
  static const IconData phone = Icons.phone;
  static const IconData phoneOutlined = Icons.phone_outlined;

  // ===========================================================================
  // FEEDBACK
  // ===========================================================================

  /// Ícone de erro
  static const IconData error = Icons.error;
  static const IconData errorOutlined = Icons.error_outline;

  /// Ícone de sucesso
  static const IconData success = Icons.check_circle;
  static const IconData successOutlined = Icons.check_circle_outline;

  /// Ícone de informação
  static const IconData info = Icons.info;
  static const IconData infoOutlined = Icons.info_outline;

  /// Ícone de aviso
  static const IconData warning = Icons.warning;
  static const IconData warningOutlined = Icons.warning_amber_outlined;

  /// Ícone de ajuda
  static const IconData help = Icons.help;
  static const IconData helpOutlined = Icons.help_outline;

  // ===========================================================================
  // SOCIAL
  // ===========================================================================

  /// Ícone de chat
  static const IconData chat = Icons.chat_bubble;
  static const IconData chatOutlined = Icons.chat_bubble_outline;

  /// Ícone de notificação
  static const IconData notification = Icons.notifications;
  static const IconData notificationOutlined = Icons.notifications_outlined;

  /// Ícone de camera
  static const IconData camera = Icons.camera_alt;
  static const IconData cameraOutlined = Icons.camera_alt_outlined;

  /// Ícone de imagem
  static const IconData image = Icons.image;
  static const IconData imageOutlined = Icons.image_outlined;

  /// Ícone de música
  static const IconData music = Icons.music_note;

  /// Ícone de video
  static const IconData video = Icons.videocam;
  static const IconData videoOutlined = Icons.videocam_outlined;

  /// Ícone de play
  static const IconData play = Icons.play_arrow;
  static const IconData playCircle = Icons.play_circle;

  /// Ícone de pause
  static const IconData pause = Icons.pause;
  static const IconData pauseCircle = Icons.pause_circle;

  /// Ícone de stop
  static const IconData stop = Icons.stop;
  static const IconData stopCircle = Icons.stop_circle;

  // ===========================================================================
  // CONTENT
  // ===========================================================================

  /// Ícone de lista
  static const IconData list = Icons.list;

  /// Ícone de grid
  static const IconData grid = Icons.grid_view;

  /// Ícone de card
  static const IconData card = Icons.view_agenda;

  /// Ícone de detalhes
  static const IconData details = Icons.article;
  static const IconData detailsOutlined = Icons.article_outlined;

  // ===========================================================================
  // MISCELLANEOUS
  // ===========================================================================

  /// Ícone de raio (MatchPoint)
  static const IconData bolt = Icons.bolt;
  static const IconData boltOutlined = Icons.bolt_outlined;
  static const IconData boltRounded = Icons.bolt_rounded;

  /// Ícone de estrela
  static const IconData star = Icons.star;
  static const IconData starOutlined = Icons.star_outline;
  static const IconData starHalf = Icons.star_half;

  /// Ícone de verificado
  static const IconData verified = Icons.verified;

  /// Ícone de link
  static const IconData link = Icons.link;

  /// Ícone de logout
  static const IconData logout = Icons.logout;

  /// Ícone de login
  static const IconData login = Icons.login;

  /// Ícone de refresh
  static const IconData refresh = Icons.refresh;

  /// Ícone de sync
  static const IconData sync = Icons.sync;

  /// Ícone de upload
  static const IconData upload = Icons.upload;
  static const IconData uploadFile = Icons.upload_file;

  /// Ícone de download
  static const IconData download = Icons.download;

  /// Ícone de attachment
  static const IconData attachment = Icons.attachment;

  /// Ícone de send
  static const IconData send = Icons.send;

  /// Ícone de mic
  static const IconData mic = Icons.mic;

  /// Ícone de search
  static const IconData searchIcon = Icons.search;
}
