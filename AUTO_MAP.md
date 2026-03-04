# AUTO MAP (generated)

Generated on: Tue Mar  3 23:59:12 -03 2026

## Pubspec
1:name: mube
2:description: "Mube - Conectando Músicos"
18:environment:
21:dependencies:
93:dev_dependencies:

## Feature folders
- address
- admin
- auth
- bands
- chat
- developer
- favorites
- feed
- gallery
- legal
- matchpoint
- moderation
- notifications
- onboarding
- profile
- search
- settings
- splash
- storage
- support

## Providers (Riverpod)
lib/src/core/providers/connectivity_provider.dart:5:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/core/providers/connectivity_provider.dart:13:final connectivityProvider = StreamProvider<ConnectivityStatus>((ref) {
lib/src/core/providers/connectivity_provider.dart:45:final isOnlineProvider = Provider<bool>((ref) {
lib/src/core/providers/app_config_provider.g.dart:20:        $FunctionalProvider<
lib/src/core/providers/app_config_provider.g.dart:25:    with $FutureModifier<AppConfig>, $FutureProvider<AppConfig> {
lib/src/core/providers/app_config_provider.g.dart:62:    extends $FunctionalProvider<List<String>, List<String>, List<String>>
lib/src/core/providers/app_config_provider.g.dart:63:    with $Provider<List<String>> {
lib/src/core/providers/app_config_provider.g.dart:89:  /// {@macro riverpod.override_with_value}
lib/src/core/providers/app_config_provider.g.dart:93:      providerOverride: $SyncValueProvider<List<String>>(value),
lib/src/core/providers/app_config_provider.g.dart:104:    extends $FunctionalProvider<List<String>, List<String>, List<String>>
lib/src/core/providers/app_config_provider.g.dart:105:    with $Provider<List<String>> {
lib/src/core/providers/app_config_provider.g.dart:130:  /// {@macro riverpod.override_with_value}
lib/src/core/providers/app_config_provider.g.dart:134:      providerOverride: $SyncValueProvider<List<String>>(value),
lib/src/core/providers/app_config_provider.g.dart:145:    extends $FunctionalProvider<List<String>, List<String>, List<String>>
lib/src/core/providers/app_config_provider.g.dart:146:    with $Provider<List<String>> {
lib/src/core/providers/app_config_provider.g.dart:171:  /// {@macro riverpod.override_with_value}
lib/src/core/providers/app_config_provider.g.dart:175:      providerOverride: $SyncValueProvider<List<String>>(value),
lib/src/core/providers/app_config_provider.g.dart:186:    extends $FunctionalProvider<List<String>, List<String>, List<String>>
lib/src/core/providers/app_config_provider.g.dart:187:    with $Provider<List<String>> {
lib/src/core/providers/app_config_provider.g.dart:212:  /// {@macro riverpod.override_with_value}
lib/src/core/providers/app_config_provider.g.dart:216:      providerOverride: $SyncValueProvider<List<String>>(value),
lib/src/core/providers/app_config_provider.g.dart:231:final class CanMatchProvider extends $FunctionalProvider<bool, bool, bool>
lib/src/core/providers/app_config_provider.g.dart:232:    with $Provider<bool> {
lib/src/core/providers/app_config_provider.g.dart:272:  /// {@macro riverpod.override_with_value}
lib/src/core/providers/app_config_provider.g.dart:276:      providerOverride: $SyncValueProvider<bool>(value),
lib/src/core/providers/app_config_provider.dart:1:import 'package:riverpod_annotation/riverpod_annotation.dart';
lib/src/core/providers/app_config_provider.dart:16:@riverpod
lib/src/core/providers/app_config_provider.dart:25:@riverpod
lib/src/core/providers/app_config_provider.dart:34:@riverpod
lib/src/core/providers/app_config_provider.dart:43:@riverpod
lib/src/core/providers/app_config_provider.dart:53:@riverpod
lib/src/core/data/app_seeder.g.dart:16:    extends $FunctionalProvider<AppSeeder, AppSeeder, AppSeeder>
lib/src/core/data/app_seeder.g.dart:17:    with $Provider<AppSeeder> {
lib/src/core/data/app_seeder.g.dart:42:  /// {@macro riverpod.override_with_value}
lib/src/core/data/app_seeder.g.dart:46:      providerOverride: $SyncValueProvider<AppSeeder>(value),
lib/src/features/search/presentation/search_controller.dart:5:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/search/presentation/search_controller.dart:605:    NotifierProvider<SearchController, SearchPaginationState>(() {
lib/src/core/services/analytics/analytics_provider.dart:2:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/core/services/analytics/analytics_provider.dart:6:final firebaseAnalyticsProvider = Provider<FirebaseAnalytics>((ref) {
lib/src/core/services/analytics/analytics_provider.dart:11:final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
lib/src/core/data/app_seeder.dart:7:import 'package:riverpod_annotation/riverpod_annotation.dart';
lib/src/core/data/app_seeder.dart:1334:@riverpod
lib/src/features/search/presentation/search_screen.dart:2:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/core/services/push_notification_provider.dart:1:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/core/services/push_notification_provider.dart:5:final pushNotificationServiceProvider = Provider<PushNotificationService>((
lib/src/core/data/app_config_repository.g.dart:17:        $FunctionalProvider<
lib/src/core/data/app_config_repository.g.dart:22:    with $Provider<AppConfigRepository> {
lib/src/core/data/app_config_repository.g.dart:48:  /// {@macro riverpod.override_with_value}
lib/src/core/data/app_config_repository.g.dart:52:      providerOverride: $SyncValueProvider<AppConfigRepository>(value),
lib/src/core/data/app_config_repository.dart:4:import 'package:riverpod_annotation/riverpod_annotation.dart';
lib/src/features/search/presentation/widgets/filter_modal.dart:2:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/core/mixins/pagination_mixin.dart:5:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/search/data/search_repository.dart:5:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/search/data/search_repository.dart:353:final searchRepositoryProvider = Provider<SearchRepository>((ref) {
lib/src/features/auth/presentation/account_deletion_provider.dart:1:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/auth/presentation/account_deletion_provider.dart:13:    NotifierProvider<AccountDeletionInProgressNotifier, bool>(
lib/src/features/auth/presentation/forgot_password_screen.g.dart:16:    extends $AsyncNotifierProvider<ForgotPasswordController, void> {
lib/src/features/developer/presentation/developer_tools_screen.dart:4:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/auth/presentation/email_verification_screen.g.dart:18:        $NotifierProvider<EmailVerificationController, EmailVerificationState> {
lib/src/features/auth/presentation/email_verification_screen.g.dart:37:  /// {@macro riverpod.override_with_value}
lib/src/features/auth/presentation/email_verification_screen.g.dart:41:      providerOverride: $SyncValueProvider<EmailVerificationState>(value),
lib/src/routing/auth_guard.dart:5:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/onboarding/providers/notification_permission_prompt_provider.dart:1:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/onboarding/providers/notification_permission_prompt_provider.dart:21:    AsyncNotifierProvider<NotificationPermissionPromptNotifier, bool>(
lib/src/routing/app_router.dart:2:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/routing/app_router.dart:57:final goRouterProvider = Provider<GoRouter>((ref) {
lib/src/features/auth/presentation/login_screen.g.dart:16:    extends $AsyncNotifierProvider<LoginController, void> {
lib/src/features/auth/presentation/register_controller.dart:2:import 'package:riverpod_annotation/riverpod_annotation.dart';
lib/src/features/auth/presentation/register_controller.dart:10:@riverpod
lib/src/features/auth/data/auth_repository.g.dart:16:    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
lib/src/features/auth/data/auth_repository.g.dart:17:    with $Provider<AuthRepository> {
lib/src/features/auth/data/auth_repository.g.dart:42:  /// {@macro riverpod.override_with_value}
lib/src/features/auth/data/auth_repository.g.dart:46:      providerOverride: $SyncValueProvider<AuthRepository>(value),
lib/src/features/auth/data/auth_repository.g.dart:61:    extends $FunctionalProvider<AsyncValue<User?>, User?, Stream<User?>>
lib/src/features/auth/data/auth_repository.g.dart:62:    with $FutureModifier<User?>, $StreamProvider<User?> {
lib/src/features/auth/data/auth_repository.g.dart:104:        $FunctionalProvider<AsyncValue<AppUser?>, AppUser?, Stream<AppUser?>>
lib/src/features/auth/data/auth_repository.g.dart:105:    with $FutureModifier<AppUser?>, $StreamProvider<AppUser?> {
lib/src/features/auth/data/auth_repository.g.dart:142:        $FunctionalProvider<
lib/src/features/auth/data/auth_repository.g.dart:147:    with $FutureModifier<List<AppUser>>, $FutureProvider<List<AppUser>> {
lib/src/features/onboarding/presentation/onboarding_controller.dart:1:import 'package:riverpod_annotation/riverpod_annotation.dart';
lib/src/features/onboarding/presentation/onboarding_controller.dart:11:@riverpod
lib/src/features/auth/presentation/email_verification_screen.dart:5:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/auth/presentation/email_verification_screen.dart:8:import 'package:riverpod_annotation/riverpod_annotation.dart';
lib/src/features/auth/presentation/email_verification_screen.dart:67:@riverpod
lib/src/features/storage/data/storage_repository.dart:6:import 'package:riverpod_annotation/riverpod_annotation.dart';
lib/src/design_system/components/buttons/app_like_button.dart:5:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/onboarding/presentation/notification_permission_screen.dart:2:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/auth/data/auth_remote_data_source.dart:6:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/auth/data/auth_remote_data_source.dart:408:final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
lib/src/features/auth/presentation/register_screen.dart:4:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/storage/data/storage_repository.g.dart:17:        $FunctionalProvider<
lib/src/features/storage/data/storage_repository.g.dart:22:    with $Provider<StorageRepository> {
lib/src/features/storage/data/storage_repository.g.dart:48:  /// {@macro riverpod.override_with_value}
lib/src/features/storage/data/storage_repository.g.dart:52:      providerOverride: $SyncValueProvider<StorageRepository>(value),
lib/src/features/auth/presentation/login_screen.dart:4:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/auth/presentation/login_screen.dart:8:import 'package:riverpod_annotation/riverpod_annotation.dart';
lib/src/features/auth/presentation/login_screen.dart:26:@riverpod
lib/src/features/auth/data/auth_repository.dart:6:import 'package:riverpod_annotation/riverpod_annotation.dart';
lib/src/features/auth/data/auth_repository.dart:464:@riverpod
lib/src/features/auth/data/auth_repository.dart:482:@riverpod
lib/src/features/auth/presentation/register_controller.g.dart:16:    extends $AsyncNotifierProvider<RegisterController, void> {
lib/src/features/auth/presentation/forgot_password_screen.dart:2:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/auth/presentation/forgot_password_screen.dart:5:import 'package:riverpod_annotation/riverpod_annotation.dart';
lib/src/features/auth/presentation/forgot_password_screen.dart:23:@riverpod
lib/src/features/onboarding/presentation/flows/onboarding_studio_flow.dart:2:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/shared/services/content_moderation_service.dart:5:import 'package:riverpod_annotation/riverpod_annotation.dart';
lib/src/features/chat/presentation/conversations_screen.dart:2:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/splash/providers/splash_provider.dart:1:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/splash/providers/splash_provider.dart:12:final splashFinishedProvider = NotifierProvider<SplashFinishedNotifier, bool>(
lib/src/features/onboarding/presentation/flows/onboarding_professional_flow.dart:2:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/splash/providers/app_bootstrap_provider.dart:5:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/splash/providers/app_bootstrap_provider.dart:19:final appCheckBootstrapperProvider = Provider<AppCheckBootstrapper>((ref) {
lib/src/features/splash/providers/app_bootstrap_provider.dart:66:    NotifierProvider<AppBootstrapNotifier, AppBootstrapState>(
lib/src/features/onboarding/presentation/flows/onboarding_band_flow.dart:2:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/shared/services/content_moderation_service.g.dart:17:        $FunctionalProvider<
lib/src/shared/services/content_moderation_service.g.dart:22:    with $Provider<ContentModerationService> {
lib/src/shared/services/content_moderation_service.g.dart:48:  /// {@macro riverpod.override_with_value}
lib/src/shared/services/content_moderation_service.g.dart:52:      providerOverride: $SyncValueProvider<ContentModerationService>(value),
lib/src/features/onboarding/presentation/flows/onboarding_contractor_flow.dart:2:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/feed/presentation/feed_view_controller.dart:2:import 'package:riverpod_annotation/riverpod_annotation.dart';
lib/src/features/feed/presentation/feed_view_controller.dart:53:@riverpod
lib/src/features/onboarding/presentation/onboarding_form_screen.dart:3:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/splash/presentation/splash_screen.dart:4:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/chat/presentation/chat_screen.dart:5:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/feed/presentation/feed_controller.g.dart:16:    extends $AsyncNotifierProvider<FeedController, FeedState> {
lib/src/features/onboarding/presentation/onboarding_type_screen.dart:2:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/support/presentation/support_controller.dart:3:import 'package:riverpod_annotation/riverpod_annotation.dart';
lib/src/features/support/presentation/support_controller.dart:13:@riverpod
lib/src/features/support/presentation/support_controller.dart:63:@riverpod
lib/src/features/support/data/support_repository.dart:2:import 'package:riverpod_annotation/riverpod_annotation.dart';
lib/src/features/support/presentation/ticket_detail_screen.dart:2:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/support/data/support_repository.g.dart:17:        $FunctionalProvider<
lib/src/features/support/data/support_repository.g.dart:22:    with $Provider<SupportRepository> {
lib/src/features/support/data/support_repository.g.dart:48:  /// {@macro riverpod.override_with_value}
lib/src/features/support/data/support_repository.g.dart:52:      providerOverride: $SyncValueProvider<SupportRepository>(value),
lib/src/features/chat/data/chat_providers.dart:2:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/chat/data/chat_providers.dart:10:final userConversationsProvider = StreamProvider<List<ConversationPreview>>((
lib/src/features/chat/data/chat_providers.dart:22:    Provider<AsyncValue<List<ConversationPreview>>>((ref) {
lib/src/features/chat/data/chat_providers.dart:31:    Provider<AsyncValue<List<ConversationPreview>>>((ref) {
lib/src/features/support/presentation/ticket_list_screen.dart:2:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/feed/presentation/feed_view_controller.g.dart:16:    extends $AsyncNotifierProvider<FeedListController, FeedListState> {
lib/src/features/onboarding/presentation/steps/onboarding_address_step.dart:2:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/support/presentation/support_controller.g.dart:16:    extends $AsyncNotifierProvider<SupportController, void> {
lib/src/features/support/presentation/support_controller.g.dart:62:        $FunctionalProvider<
lib/src/features/support/presentation/support_controller.g.dart:67:    with $FutureModifier<List<Ticket>>, $StreamProvider<List<Ticket>> {
lib/src/features/chat/data/chat_repository.dart:3:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/chat/data/chat_repository.dart:499:final chatRepositoryProvider = Provider<ChatRepository>((ref) {
lib/src/app.dart:6:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/onboarding/presentation/onboarding_controller.g.dart:16:    extends $AsyncNotifierProvider<OnboardingController, void> {
lib/src/features/support/presentation/create_ticket_screen.dart:4:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/chat/data/chat_unread_provider.dart:1:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/chat/data/chat_unread_provider.dart:11:final unreadMessagesCountProvider = StreamProvider<int>((ref) {
lib/src/features/settings/presentation/settings_screen.dart:5:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/onboarding/presentation/onboarding_form_provider.dart:4:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/onboarding/presentation/onboarding_form_provider.dart:431:    NotifierProvider<OnboardingFormNotifier, OnboardingFormState>(
lib/src/features/feed/presentation/feed_controller.dart:3:import 'package:riverpod_annotation/riverpod_annotation.dart';
lib/src/design_system/components/navigation/app_scaffold.dart:2:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/design_system/components/navigation/main_scaffold.dart:4:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/bands/presentation/manage_members_screen.dart:5:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/feed/presentation/feed_screen.dart:4:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/matchpoint/presentation/controllers/matchpoint_controller.dart:17:import 'package:riverpod_annotation/riverpod_annotation.dart';
lib/src/features/matchpoint/presentation/controllers/matchpoint_controller.dart:442:@riverpod
lib/src/features/matchpoint/presentation/controllers/matchpoint_controller.dart:457:@riverpod
lib/src/features/matchpoint/presentation/controllers/matchpoint_controller.dart:468:@riverpod
lib/src/features/admin/presentation/maintenance_screen.dart:4:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/settings/presentation/privacy_settings_screen.dart:2:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/matchpoint/presentation/controllers/matchpoint_controller.g.dart:16:    extends $AsyncNotifierProvider<MatchpointController, void> {
lib/src/features/matchpoint/presentation/controllers/matchpoint_controller.g.dart:62:    extends $NotifierProvider<LikesQuota, LikesQuotaState> {
lib/src/features/matchpoint/presentation/controllers/matchpoint_controller.g.dart:81:  /// {@macro riverpod.override_with_value}
lib/src/features/matchpoint/presentation/controllers/matchpoint_controller.g.dart:85:      providerOverride: $SyncValueProvider<LikesQuotaState>(value),
lib/src/features/matchpoint/presentation/controllers/matchpoint_controller.g.dart:115:    extends $AsyncNotifierProvider<MatchpointCandidates, List<AppUser>> {
lib/src/features/matchpoint/presentation/controllers/matchpoint_controller.g.dart:162:        $FunctionalProvider<
lib/src/features/matchpoint/presentation/controllers/matchpoint_controller.g.dart:167:    with $FutureModifier<List<MatchInfo>>, $FutureProvider<List<MatchInfo>> {
lib/src/features/matchpoint/presentation/controllers/matchpoint_controller.g.dart:201:        $FunctionalProvider<
lib/src/features/matchpoint/presentation/controllers/matchpoint_controller.g.dart:208:        $FutureProvider<List<HashtagRanking>> {
lib/src/features/matchpoint/presentation/controllers/matchpoint_controller.g.dart:278:        $FunctionalProvider<
lib/src/features/matchpoint/presentation/controllers/matchpoint_controller.g.dart:285:        $FutureProvider<List<HashtagRanking>> {
lib/src/features/matchpoint/presentation/controllers/matchpoint_controller.g.dart:354:    extends $NotifierProvider<SwipeHistory, List<SwipeHistoryEntry>> {
lib/src/features/matchpoint/presentation/controllers/matchpoint_controller.g.dart:373:  /// {@macro riverpod.override_with_value}
lib/src/features/matchpoint/presentation/controllers/matchpoint_controller.g.dart:377:      providerOverride: $SyncValueProvider<List<SwipeHistoryEntry>>(value),
lib/src/features/feed/data/feed_remote_data_source.dart:2:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/feed/data/feed_remote_data_source.dart:265:final feedRemoteDataSourceProvider = Provider<FeedRemoteDataSource>((ref) {
lib/src/features/notifications/presentation/notification_list_screen.dart:2:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/bands/data/invites_repository.dart:5:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/bands/data/invites_repository.dart:6:import 'package:riverpod_annotation/riverpod_annotation.dart';
lib/src/features/bands/data/invites_repository.dart:270:@riverpod
lib/src/features/settings/presentation/blocked_users_screen.dart:4:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/feed/data/featured_profiles_repository.dart:2:import 'package:riverpod_annotation/riverpod_annotation.dart';
lib/src/features/feed/presentation/widgets/feed_header.dart:3:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/feed/presentation/feed_list_screen.dart:2:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/feed/presentation/feed_image_precache_service.dart:7:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/feed/presentation/feed_image_precache_service.dart:13:final feedImagePrecacheServiceProvider = Provider<FeedImagePrecacheService>((
lib/src/features/feed/data/feed_repository.dart:2:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/feed/data/feed_repository.dart:18:final feedRepositoryProvider = Provider<FeedRepository>((ref) {
lib/src/features/notifications/data/notification_providers.dart:1:import 'package:flutter_riverpod/flutter_riverpod.dart';
lib/src/features/notifications/data/notification_providers.dart:22:final unreadNotificationCountProvider = Provider<int>((ref) {
lib/src/features/notifications/data/notification_providers.dart:29:final legacyUnreadCountProvider = NotifierProvider<LegacyUnreadNotifier, int>(
lib/src/features/feed/data/featured_profiles_repository.g.dart:27:        $FunctionalProvider<
lib/src/features/feed/data/featured_profiles_repository.g.dart:32:    with $Provider<FeaturedProfilesRepository> {
lib/src/features/feed/data/featured_profiles_repository.g.dart:62:  /// {@macro riverpod.override_with_value}

## Routes / Navigation hints
lib/src/core/services/analytics/analytics_service.dart:18:  NavigatorObserver getObserver();
lib/src/core/services/analytics/analytics_service.dart:101:  NavigatorObserver getObserver() {
lib/src/core/services/analytics/analytics_service.dart:103:      return _NoopNavigatorObserver();
lib/src/core/services/analytics/analytics_service.dart:145:class _NoopNavigatorObserver extends NavigatorObserver {
lib/src/core/services/analytics/analytics_service.dart:146:  _NoopNavigatorObserver();
lib/src/app.dart:121:    return MaterialApp.router(
lib/src/routing/auth_guard.dart:35:  FutureOr<String?> redirect(BuildContext context, GoRouterState state) async {
lib/src/design_system/components/feedback/app_confirmation_dialog.dart:38:          onPressed: () => Navigator.pop(context, false),
lib/src/design_system/components/feedback/app_confirmation_dialog.dart:47:          onPressed: () => Navigator.pop(context, true),
lib/src/design_system/components/feedback/app_overlay.dart:21:    bool useRootNavigator = true,
lib/src/design_system/components/feedback/app_overlay.dart:34:      useRootNavigator: useRootNavigator,
lib/src/design_system/components/feedback/app_overlay.dart:54:    bool useRootNavigator = false,
lib/src/design_system/components/feedback/app_overlay.dart:71:      useRootNavigator: useRootNavigator,
lib/src/routing/app_router.dart:52:class _GoRouterRefreshNotifier extends ChangeNotifier {
lib/src/routing/app_router.dart:57:final goRouterProvider = Provider<GoRouter>((ref) {
lib/src/routing/app_router.dart:58:  final notifier = _GoRouterRefreshNotifier();
lib/src/routing/app_router.dart:67:  return GoRouter(
lib/src/routing/app_router.dart:73:    routes: _buildRoutes(ref),
lib/src/routing/app_router.dart:125:      routes: [
lib/src/routing/app_router.dart:151:          routes: [
lib/src/routing/app_router.dart:158:              routes: [
lib/src/routing/app_router.dart:178:          routes: [
lib/src/routing/app_router.dart:190:          routes: [
lib/src/routing/app_router.dart:195:              routes: [
lib/src/routing/app_router.dart:209:          routes: [
lib/src/routing/app_router.dart:216:              routes: const [],
lib/src/routing/app_router.dart:222:          routes: [
lib/src/routing/app_router.dart:229:              routes: [
lib/src/routing/app_router.dart:273:                  routes: [
lib/src/routing/app_router.dart:287:                      routes: [
lib/src/design_system/components/inputs/enhanced_multi_select_modal.dart:224:                        onPressed: () => Navigator.of(context).pop(),
lib/src/design_system/components/inputs/enhanced_multi_select_modal.dart:234:                            ? () => Navigator.of(context).pop(_selected)
lib/src/design_system/components/inputs/app_selection_modal.dart:102:                  onTap: () => Navigator.pop(context),
lib/src/design_system/components/inputs/app_selection_modal.dart:162:                onPressed: () => Navigator.pop(context, _tempSelectedItems),
lib/src/features/search/presentation/widgets/filter_modal.dart:155:                    onPressed: () => Navigator.pop(context),
lib/src/features/search/presentation/widgets/filter_modal.dart:255:    Navigator.pop(context);
lib/src/design_system/components/navigation/app_app_bar.dart:18:  /// Se deve mostrar o botao de voltar. Padrao: true se Navigator.canPop().
lib/src/design_system/components/navigation/app_app_bar.dart:55:    final canPop = Navigator.of(context).canPop();
lib/src/features/notifications/presentation/notification_list_screen.dart:157:            onPressed: () => Navigator.pop(ctx),
lib/src/features/notifications/presentation/notification_list_screen.dart:167:              Navigator.pop(ctx);
lib/src/design_system/components/feedback/app_info_dialog.dart:171:                        onPressed: () => Navigator.of(context).pop(),
lib/src/design_system/components/feedback/app_info_dialog.dart:191:                      onPressed: () => Navigator.of(context).pop(),
lib/src/features/address/presentation/address_flow.dart:12:  return Navigator.of(context).push<ResolvedAddress>(
lib/src/features/address/presentation/address_flow.dart:28:  return Navigator.of(context).push<ResolvedAddress>(
lib/src/features/profile/presentation/public_profile_screen.dart:804:        onTap: () => Navigator.of(context).pop(),
lib/src/features/profile/presentation/public_profile_screen.dart:812:              onPressed: () => Navigator.of(context).pop(),
lib/src/features/address/presentation/address_confirm_screen.dart:61:      Navigator.of(context).pop(currentAddress);
lib/src/features/address/presentation/address_confirm_screen.dart:70:        Navigator.of(context).pop(currentAddress);
lib/src/features/address/presentation/address_search_screen.dart:133:      Navigator.of(context).pop<ResolvedAddress>(confirmed);
lib/src/features/profile/presentation/services/media_picker_service.dart:66:                onTap: () => Navigator.pop(ctx, ImageSource.camera),
lib/src/features/profile/presentation/services/media_picker_service.dart:72:                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
lib/src/features/profile/presentation/services/media_picker_service.dart:270:    return Navigator.of(context).push<File>(
lib/src/features/profile/presentation/widgets/video_trim_screen.dart:84:      Navigator.of(context).pop();
lib/src/features/profile/presentation/widgets/video_trim_screen.dart:243:      Navigator.of(context).pop(persistedFile);
lib/src/features/profile/presentation/widgets/video_trim_screen.dart:404:              : () => Navigator.of(context).pop(),
lib/src/features/profile/presentation/widgets/video_trim_screen.dart:551:                                  : () => Navigator.of(context).pop(),
lib/src/features/bands/presentation/manage_members_screen.dart:1094:        Navigator.pop(context);
lib/src/features/onboarding/presentation/widgets/band_profile_tutorial_dialog.dart:120:                                        Navigator.of(context).pop(false),
lib/src/features/onboarding/presentation/widgets/band_profile_tutorial_dialog.dart:191:                        onPressed: () => Navigator.of(context).pop(true),
lib/src/features/onboarding/presentation/widgets/band_profile_tutorial_dialog.dart:198:                        onPressed: () => Navigator.of(context).pop(false),
lib/src/features/feed/presentation/widgets/feed_header.dart:755:                        Navigator.of(sheetContext).pop();
lib/src/features/gallery/presentation/design_system_gallery_screen.dart:52:                    onPressed: () => Navigator.of(context).pop(),
lib/src/features/auth/presentation/email_verification_screen.dart:326:    final navigator = Navigator.of(context);
lib/src/features/auth/presentation/email_verification_screen.dart:332:    final router = GoRouter.of(context);
lib/src/features/chat/presentation/chat_screen.dart:476:            final router = GoRouter.of(context);
lib/src/features/support/presentation/ticket_detail_screen.dart:214:              onTap: () => Navigator.of(context).pop(),
lib/src/features/support/presentation/ticket_detail_screen.dart:223:                onPressed: () => Navigator.of(context).pop(),
lib/src/features/legal/presentation/legal_detail_screen.dart:150:                    onPressed: () => Navigator.of(context).pop(),
lib/src/features/matchpoint/presentation/widgets/match_profile_preview_sheet.dart:76:                    onPressed: () => Navigator.of(context).pop(),
lib/src/features/matchpoint/presentation/screens/matchpoint_explore_screen.dart:187:          final navigator = Navigator.of(context);
lib/src/features/profile/presentation/widgets/media_viewer_dialog.dart:93:            onPressed: () => Navigator.of(context).pop(),

## Screens (Widgets ending with Screen/Page)
lib/src/features/search/presentation/search_screen.dart:29:class SearchScreen extends ConsumerStatefulWidget {
lib/src/features/search/presentation/search_screen.dart:36:class _SearchScreenState extends ConsumerState<SearchScreen> {
lib/src/features/admin/presentation/maintenance_screen.dart:16:class MaintenanceScreen extends ConsumerStatefulWidget {
lib/src/features/admin/presentation/maintenance_screen.dart:23:class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
lib/src/features/gallery/presentation/design_system_gallery_screen.dart:17:class DesignSystemGalleryScreen extends StatefulWidget {
lib/src/features/gallery/presentation/design_system_gallery_screen.dart:25:class _DesignSystemGalleryScreenState extends State<DesignSystemGalleryScreen> {
lib/src/features/profile/presentation/edit_profile_screen.dart:30:class EditProfileScreen extends ConsumerStatefulWidget {
lib/src/features/profile/presentation/edit_profile_screen.dart:37:class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
lib/src/features/developer/presentation/developer_tools_screen.dart:12:class DeveloperToolsScreen extends ConsumerStatefulWidget {
lib/src/features/developer/presentation/developer_tools_screen.dart:20:class _DeveloperToolsScreenState extends ConsumerState<DeveloperToolsScreen> {
lib/src/features/profile/presentation/profile_screen.dart:19:class ProfileScreen extends ConsumerWidget {
lib/src/features/feed/presentation/feed_list_screen.dart:15:class FeedListScreen extends ConsumerStatefulWidget {
lib/src/features/feed/presentation/feed_list_screen.dart:24:class _FeedListScreenState extends ConsumerState<FeedListScreen> {
lib/src/features/address/presentation/address_confirm_screen.dart:14:class AddressConfirmScreen extends StatefulWidget {
lib/src/features/address/presentation/address_confirm_screen.dart:30:class _AddressConfirmScreenState extends State<AddressConfirmScreen> {
lib/src/features/onboarding/presentation/notification_permission_screen.dart:17:class NotificationPermissionScreen extends ConsumerStatefulWidget {
lib/src/features/splash/presentation/splash_screen.dart:10:class SplashScreen extends ConsumerStatefulWidget {
lib/src/features/splash/presentation/splash_screen.dart:17:class _SplashScreenState extends ConsumerState<SplashScreen> {
lib/src/features/auth/presentation/email_verification_screen.dart:263:class EmailVerificationScreen extends ConsumerStatefulWidget {
lib/src/features/onboarding/presentation/onboarding_form_screen.dart:25:class OnboardingFormScreen extends ConsumerStatefulWidget {
lib/src/features/onboarding/presentation/onboarding_form_screen.dart:33:class _OnboardingFormScreenState extends ConsumerState<OnboardingFormScreen> {
lib/src/features/auth/presentation/register_screen.dart:22:class RegisterScreen extends ConsumerStatefulWidget {
lib/src/features/auth/presentation/register_screen.dart:29:class _RegisterScreenState extends ConsumerState<RegisterScreen>
lib/src/features/profile/presentation/public_profile_screen.dart:30:class PublicProfileScreen extends ConsumerWidget {
lib/src/features/support/presentation/support_screen.dart:23:class SupportScreen extends StatefulWidget {
lib/src/features/support/presentation/support_screen.dart:30:class _SupportScreenState extends State<SupportScreen> {
lib/src/features/address/presentation/address_search_screen.dart:19:class AddressSearchScreen extends StatefulWidget {
lib/src/features/address/presentation/address_search_screen.dart:33:class _AddressSearchScreenState extends State<AddressSearchScreen> {
lib/src/features/feed/presentation/feed_screen.dart:38:class FeedScreen extends ConsumerStatefulWidget {
lib/src/features/feed/presentation/feed_screen.dart:45:class _FeedScreenState extends ConsumerState<FeedScreen> {
lib/src/features/chat/presentation/conversations_screen.dart:22:class ConversationsScreen extends ConsumerStatefulWidget {
lib/src/features/chat/presentation/conversations_screen.dart:30:class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
lib/src/features/auth/presentation/login_screen.dart:70:class LoginScreen extends ConsumerStatefulWidget {
lib/src/features/auth/presentation/login_screen.dart:77:class _LoginScreenState extends ConsumerState<LoginScreen>
lib/src/features/bands/presentation/manage_members_screen.dart:89:class ManageMembersScreen extends ConsumerStatefulWidget {
lib/src/features/bands/presentation/manage_members_screen.dart:97:class _ManageMembersScreenState extends ConsumerState<ManageMembersScreen> {
lib/src/features/onboarding/presentation/onboarding_type_screen.dart:28:class OnboardingTypeScreen extends ConsumerStatefulWidget {
lib/src/features/onboarding/presentation/onboarding_type_screen.dart:36:class _OnboardingTypeScreenState extends ConsumerState<OnboardingTypeScreen>
lib/src/features/legal/presentation/legal_detail_screen.dart:36:class LegalDetailScreen extends StatelessWidget {
lib/src/features/matchpoint/presentation/screens/swipe_history_screen.dart:16:class SwipeHistoryScreen extends ConsumerStatefulWidget {
lib/src/features/matchpoint/presentation/screens/swipe_history_screen.dart:23:class _SwipeHistoryScreenState extends ConsumerState<SwipeHistoryScreen> {
lib/src/features/profile/presentation/invites_screen.dart:18:class InvitesScreen extends ConsumerWidget {
lib/src/features/support/presentation/ticket_list_screen.dart:16:class TicketListScreen extends ConsumerWidget {
lib/src/features/favorites/presentation/received_favorites_screen.dart:18:class ReceivedFavoritesScreen extends ConsumerStatefulWidget {
lib/src/features/favorites/presentation/favorites_screen.dart:27:class FavoritesScreen extends ConsumerStatefulWidget {
lib/src/features/favorites/presentation/favorites_screen.dart:34:class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
lib/src/features/chat/presentation/chat_screen.dart:26:class ChatScreen extends ConsumerStatefulWidget {
lib/src/features/chat/presentation/chat_screen.dart:50:class _ChatScreenState extends ConsumerState<ChatScreen> {
lib/src/features/settings/presentation/privacy_settings_screen.dart:13:class PrivacySettingsScreen extends ConsumerWidget {
lib/src/features/profile/presentation/widgets/video_trim_screen.dart:22:class VideoTrimScreen extends StatefulWidget {
lib/src/features/profile/presentation/widgets/video_trim_screen.dart:36:class _VideoTrimScreenState extends State<VideoTrimScreen> {
lib/src/features/matchpoint/presentation/screens/matchpoint_setup_wizard_screen.dart:21:class MatchpointSetupWizardScreen extends ConsumerStatefulWidget {
lib/src/features/matchpoint/presentation/screens/hashtag_ranking_screen.dart:14:class HashtagRankingScreen extends ConsumerWidget {
lib/src/features/support/presentation/create_ticket_screen.dart:19:class CreateTicketScreen extends ConsumerStatefulWidget {
lib/src/features/support/presentation/create_ticket_screen.dart:26:class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
lib/src/features/matchpoint/presentation/screens/matchpoint_explore_screen.dart:22:class MatchpointExploreScreen extends ConsumerStatefulWidget {
lib/src/features/matchpoint/presentation/screens/matchpoint_wrapper_screen.dart:11:class MatchpointWrapperScreen extends ConsumerWidget {
lib/src/features/matchpoint/presentation/screens/matchpoint_intro_screen.dart:11:class MatchpointIntroScreen extends StatelessWidget {
lib/src/features/matchpoint/presentation/screens/matchpoint_matches_screen.dart:14:class MatchpointMatchesScreen extends ConsumerWidget {
lib/src/features/matchpoint/presentation/screens/match_success_screen.dart:15:class MatchSuccessScreen extends ConsumerStatefulWidget {
lib/src/features/matchpoint/presentation/screens/match_success_screen.dart:31:class _MatchSuccessScreenState extends ConsumerState<MatchSuccessScreen>
lib/src/features/settings/presentation/blocked_users_screen.dart:33:class BlockedUsersScreen extends ConsumerWidget {
lib/src/features/settings/presentation/addresses_screen.dart:27:class AddressesScreen extends ConsumerStatefulWidget {
lib/src/features/settings/presentation/addresses_screen.dart:34:class _AddressesScreenState extends ConsumerState<AddressesScreen> {
lib/src/features/settings/presentation/settings_screen.dart:34:class SettingsScreen extends ConsumerWidget {
lib/src/features/matchpoint/presentation/screens/matchpoint_tabs_screen.dart:17:class MatchpointTabsScreen extends ConsumerStatefulWidget {
lib/src/features/matchpoint/presentation/screens/matchpoint_tabs_screen.dart:25:class _MatchpointTabsScreenState extends ConsumerState<MatchpointTabsScreen> {
lib/src/features/notifications/presentation/notification_list_screen.dart:18:class NotificationListScreen extends ConsumerWidget {
lib/src/features/matchpoint/presentation/screens/matchpoint_unavailable_screen.dart:12:class MatchpointUnavailableScreen extends StatelessWidget {
lib/src/features/auth/presentation/forgot_password_screen.dart:47:class ForgotPasswordScreen extends ConsumerStatefulWidget {
lib/src/features/auth/presentation/forgot_password_screen.dart:55:class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
lib/src/features/support/presentation/ticket_detail_screen.dart:15:class TicketDetailScreen extends ConsumerWidget {

## Firebase usage
lib/src/utils/auth_exception_handler.dart:5:    if (e is FirebaseAuthException) {
lib/src/features/search/domain/paginated_search_response.dart:1:import 'package:cloud_firestore/cloud_firestore.dart';
lib/src/features/search/presentation/search_controller.dart:3:import 'package:cloud_firestore/cloud_firestore.dart';
lib/src/features/search/presentation/search_controller.dart:7:import '../../../constants/firestore_constants.dart';
lib/src/features/support/data/support_repository.dart:1:import 'package:cloud_firestore/cloud_firestore.dart';
lib/src/features/support/data/support_repository.dart:10:  return SupportRepository(FirebaseFirestore.instance);
lib/src/features/support/data/support_repository.dart:14:  final FirebaseFirestore _firestore;
lib/src/features/support/data/support_repository.dart:16:  SupportRepository(this._firestore);
lib/src/features/support/data/support_repository.dart:19:      _firestore.collection('tickets');
lib/src/features/matchpoint/domain/hashtag_ranking.dart:1:import 'package:cloud_firestore/cloud_firestore.dart';
lib/src/features/search/data/search_repository.dart:3:import 'package:cloud_firestore/cloud_firestore.dart';
lib/src/features/search/data/search_repository.dart:25:  final FirebaseFirestore _firestore;
lib/src/features/search/data/search_repository.dart:28:  SearchRepository({FirebaseFirestore? firestore, AnalyticsService? analytics})
lib/src/features/search/data/search_repository.dart:29:    : _firestore = firestore ?? FirebaseFirestore.instance,
lib/src/features/search/data/search_repository.dart:149:    Query<Map<String, dynamic>> query = _firestore.collection('users');
lib/src/features/storage/data/storage_repository.dart:16:  return StorageRepository(FirebaseStorage.instance);
lib/src/features/storage/data/storage_repository.dart:63:  final FirebaseStorage _storage;
lib/src/features/storage/data/storage_repository.dart:76:    final currentUser = FirebaseAuth.instance.currentUser;
lib/src/features/storage/data/storage_repository.dart:195:    final currentUser = FirebaseAuth.instance.currentUser;
lib/src/features/storage/data/storage_repository.dart:404:    final currentUser = FirebaseAuth.instance.currentUser;
lib/src/features/storage/data/storage_repository.dart:606:    final currentUser = FirebaseAuth.instance.currentUser;
lib/src/features/matchpoint/presentation/controllers/matchpoint_controller.dart:5:import 'package:mube/src/constants/firestore_constants.dart';
lib/src/features/matchpoint/presentation/controllers/matchpoint_controller.dart:138:      AppLogger.error('Swipe blocked: missing FirebaseAuth session.');
lib/src/features/matchpoint/presentation/controllers/matchpoint_controller.dart:149:        AppLogger.error('Swipe blocked: missing FirebaseAuth token.');
lib/src/features/matchpoint/presentation/controllers/matchpoint_controller.dart:157:      AppLogger.error('Swipe blocked: failed to read FirebaseAuth token: $e');
lib/src/features/developer/presentation/developer_tools_screen.dart:1:import 'package:cloud_firestore/cloud_firestore.dart';
lib/src/features/developer/presentation/developer_tools_screen.dart:34:      final usersQuery = await FirebaseFirestore.instance
lib/src/features/developer/presentation/developer_tools_screen.dart:68:      final batch = FirebaseFirestore.instance.batch();
lib/src/features/developer/presentation/developer_tools_screen.dart:70:      final conversationRef = FirebaseFirestore.instance
lib/src/features/developer/presentation/developer_tools_screen.dart:89:      final myPreviewRef = FirebaseFirestore.instance
lib/src/features/developer/presentation/developer_tools_screen.dart:108:      final senderPreviewRef = FirebaseFirestore.instance
lib/src/core/mixins/pagination_mixin.dart:3:import 'package:cloud_firestore/cloud_firestore.dart';
lib/src/features/bands/data/invites_repository.dart:1:import 'package:cloud_firestore/cloud_firestore.dart';
lib/src/features/bands/data/invites_repository.dart:2:import 'package:cloud_functions/cloud_functions.dart';
lib/src/features/bands/data/invites_repository.dart:16:    FirebaseFirestore.instance,
lib/src/features/bands/data/invites_repository.dart:22:  final FirebaseFirestore _firestore;
lib/src/features/bands/data/invites_repository.dart:23:  final FirebaseAuth? _auth;
lib/src/features/bands/data/invites_repository.dart:28:    this._firestore, {
lib/src/features/bands/data/invites_repository.dart:29:    FirebaseAuth? auth,
lib/src/features/bands/data/invites_repository.dart:53:    final currentUser = (_auth ?? FirebaseAuth.instance).currentUser;
lib/src/features/bands/data/invites_repository.dart:59:          'Falha ao atualizar token do FirebaseAuth antes do retry de convite',
lib/src/features/bands/data/invites_repository.dart:183:    return _firestore
lib/src/features/bands/data/invites_repository.dart:200:    return _firestore
lib/src/features/bands/data/invites_repository.dart:217:    return _firestore
lib/src/features/chat/domain/conversation_preview.dart:1:import 'package:cloud_firestore/cloud_firestore.dart';
lib/src/features/matchpoint/presentation/screens/matchpoint_explore_screen.dart:9:import '../../../../constants/firestore_constants.dart';
lib/src/core/services/push_notification_service.dart:3:import 'package:cloud_firestore/cloud_firestore.dart';
lib/src/core/services/push_notification_service.dart:13:  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
lib/src/core/services/push_notification_service.dart:14:  final FirebaseAuth _auth = FirebaseAuth.instance;
lib/src/core/services/push_notification_service.dart:214:      await _firestore.collection('users').doc(user.uid).update({
lib/src/features/chat/domain/message.dart:1:import 'package:cloud_firestore/cloud_firestore.dart';
lib/src/features/chat/domain/conversation.dart:1:import 'package:cloud_firestore/cloud_firestore.dart';
lib/src/features/matchpoint/presentation/screens/matchpoint_setup_wizard_screen.dart:6:import '../../../../constants/firestore_constants.dart';
lib/src/features/chat/presentation/chat_screen.dart:3:import 'package:cloud_firestore/cloud_firestore.dart';
lib/src/features/notifications/domain/notification_model.dart:1:import 'package:cloud_firestore/cloud_firestore.dart';
lib/src/features/chat/data/chat_providers.dart:1:import 'package:cloud_firestore/cloud_firestore.dart';
lib/src/features/matchpoint/presentation/widgets/match_card.dart:5:import '../../../../constants/firestore_constants.dart';
lib/src/core/errors/error_handler.dart:26:    if (error is FirebaseAuthException) {
lib/src/core/errors/error_handler.dart:27:      return _handleFirebaseAuthError(error);
lib/src/core/errors/error_handler.dart:64:  static Failure _handleFirebaseAuthError(FirebaseAuthException error) {
lib/src/features/notifications/data/notification_repository.dart:1:import 'package:cloud_firestore/cloud_firestore.dart';
lib/src/features/notifications/data/notification_repository.dart:8:  return NotificationRepository(FirebaseFirestore.instance);
lib/src/features/notifications/data/notification_repository.dart:13:  NotificationRepository(this._firestore);
lib/src/features/notifications/data/notification_repository.dart:15:  final FirebaseFirestore _firestore;
lib/src/features/notifications/data/notification_repository.dart:19:    return _firestore
lib/src/features/notifications/data/notification_repository.dart:35:    await _firestore
lib/src/features/notifications/data/notification_repository.dart:45:    final batch = _firestore.batch();
lib/src/features/notifications/data/notification_repository.dart:46:    final notifications = await _firestore
lib/src/features/notifications/data/notification_repository.dart:62:    await _firestore
lib/src/features/notifications/data/notification_repository.dart:72:    final batch = _firestore.batch();
lib/src/features/notifications/data/notification_repository.dart:73:    final notifications = await _firestore
lib/src/core/errors/failure_mapper.dart:63:    'permission-denied' => PermissionFailure.firestore(),
lib/src/features/matchpoint/data/matchpoint_repository.dart:1:import 'package:cloud_firestore/cloud_firestore.dart';
lib/src/features/matchpoint/data/matchpoint_repository.dart:2:import 'package:cloud_functions/cloud_functions.dart';
lib/src/features/matchpoint/data/matchpoint_repository.dart:4:import 'package:mube/src/constants/firestore_constants.dart';
lib/src/features/matchpoint/data/matchpoint_repository.dart:119:        return Left(PermissionFailure.firestore());
lib/src/features/admin/presentation/maintenance_screen.dart:1:import 'package:cloud_firestore/cloud_firestore.dart';
lib/src/features/admin/presentation/maintenance_screen.dart:2:import 'package:cloud_functions/cloud_functions.dart';
lib/src/features/admin/presentation/maintenance_screen.dart:120:    final stream = FirebaseFirestore.instance
lib/src/features/admin/presentation/maintenance_screen.dart:438:      final firestore = FirebaseFirestore.instance;
lib/src/features/admin/presentation/maintenance_screen.dart:439:      final snapshot = await firestore
lib/src/features/admin/presentation/maintenance_screen.dart:454:            await firestore.collection('users').doc(doc.id).update({
lib/src/features/admin/presentation/maintenance_screen.dart:508:      final firestore = FirebaseFirestore.instance;
lib/src/features/admin/presentation/maintenance_screen.dart:509:      final snapshot = await firestore
lib/src/features/admin/presentation/maintenance_screen.dart:538:            await firestore.collection('users').doc(doc.id).update({
lib/src/features/admin/presentation/maintenance_screen.dart:576:      final firestore = FirebaseFirestore.instance;
lib/src/features/admin/presentation/maintenance_screen.dart:577:      final snapshot = await firestore
lib/src/features/admin/presentation/maintenance_screen.dart:586:      var batch = firestore.batch();
lib/src/features/admin/presentation/maintenance_screen.dart:609:          batch = firestore.batch();
lib/src/core/data/app_seeder.dart:5:import 'package:cloud_firestore/cloud_firestore.dart';
lib/src/core/data/app_seeder.dart:11:import '../../constants/firestore_constants.dart';
lib/src/core/data/app_seeder.dart:27:  AppSeeder(this._firestore, this._configRepo);
lib/src/core/data/app_seeder.dart:29:  final FirebaseFirestore _firestore;
lib/src/core/data/app_seeder.dart:707:    final snapshot = await _firestore
lib/src/core/data/app_seeder.dart:726:      final batch = _firestore.batch();
lib/src/core/data/app_seeder.dart:769:      await _firestore
lib/src/core/data/app_seeder.dart:815:    final batch = _firestore.batch();
lib/src/core/data/app_seeder.dart:829:        _firestore
lib/src/core/data/app_seeder.dart:851:        _firestore
lib/src/core/data/app_seeder.dart:873:        _firestore
lib/src/core/data/app_seeder.dart:1277:    final configCollection = _firestore.collection('config');
lib/src/core/data/app_seeder.dart:1337:    FirebaseFirestore.instance,
lib/src/core/data/app_config_repository.dart:3:import 'package:cloud_firestore/cloud_firestore.dart';
lib/src/core/data/app_config_repository.dart:16:  final FirebaseFirestore _firestore;
lib/src/core/data/app_config_repository.dart:18:  AppConfigRepository(this._firestore);
lib/src/core/data/app_config_repository.dart:24:      final doc = await _firestore.collection('config').doc('app_data').get();
lib/src/core/data/app_config_repository.dart:122:  return AppConfigRepository(FirebaseFirestore.instance);
lib/src/features/chat/data/chat_repository.dart:1:import 'package:cloud_firestore/cloud_firestore.dart';
lib/src/features/chat/data/chat_repository.dart:15:  final FirebaseFirestore _firestore;
lib/src/features/chat/data/chat_repository.dart:18:  ChatRepository(this._firestore, {AnalyticsService? analytics})
lib/src/features/chat/data/chat_repository.dart:90:    final snapshot = await _firestore.collection('users').doc(uid).get();
lib/src/features/chat/data/chat_repository.dart:117:      final conversationRef = _firestore
lib/src/features/chat/data/chat_repository.dart:121:      await _firestore.runTransaction((transaction) async {
lib/src/features/chat/data/chat_repository.dart:124:        final myPreviewRef = _firestore
lib/src/features/chat/data/chat_repository.dart:130:        final otherPreviewRef = _firestore
lib/src/features/chat/data/chat_repository.dart:231:      final batch = _firestore.batch();
lib/src/features/chat/data/chat_repository.dart:233:      final conversationRef = _firestore
lib/src/features/chat/data/chat_repository.dart:266:      final myPreviewRef = _firestore
lib/src/features/chat/data/chat_repository.dart:284:      final otherPreviewRef = _firestore
lib/src/features/chat/data/chat_repository.dart:331:      final batch = _firestore.batch();
lib/src/features/chat/data/chat_repository.dart:333:      final conversationRef = _firestore
lib/src/features/chat/data/chat_repository.dart:341:      final myPreviewRef = _firestore
lib/src/features/chat/data/chat_repository.dart:359:    return _firestore
lib/src/features/chat/data/chat_repository.dart:374:    return _firestore
lib/src/features/chat/data/chat_repository.dart:390:    final doc = await _firestore
lib/src/features/chat/data/chat_repository.dart:400:    return _firestore
lib/src/features/chat/data/chat_repository.dart:415:      final previewRef = _firestore
lib/src/features/chat/data/chat_repository.dart:420:      final conversationRef = _firestore
lib/src/features/chat/data/chat_repository.dart:464:      final batch = _firestore.batch();
lib/src/features/chat/data/chat_repository.dart:466:      final myPreviewRef = _firestore
lib/src/features/chat/data/chat_repository.dart:501:  return ChatRepository(FirebaseFirestore.instance, analytics: analytics);
lib/src/features/matchpoint/data/matchpoint_remote_data_source.dart:3:import 'package:cloud_firestore/cloud_firestore.dart';
lib/src/features/matchpoint/data/matchpoint_remote_data_source.dart:4:import 'package:cloud_functions/cloud_functions.dart';
lib/src/features/matchpoint/data/matchpoint_remote_data_source.dart:17:import '../../../constants/firestore_constants.dart';
lib/src/features/matchpoint/data/matchpoint_remote_data_source.dart:54:  final FirebaseFirestore _firestore;
lib/src/features/matchpoint/data/matchpoint_remote_data_source.dart:59:    this._firestore,
lib/src/features/matchpoint/data/matchpoint_remote_data_source.dart:75:    final currentUser = FirebaseAuth.instance.currentUser;
lib/src/features/matchpoint/data/matchpoint_remote_data_source.dart:81:          'Failed to refresh FirebaseAuth token before retry.',
lib/src/features/matchpoint/data/matchpoint_remote_data_source.dart:208:        final nearbySnapshot = await _firestore
lib/src/features/matchpoint/data/matchpoint_remote_data_source.dart:231:      final fallbackSnapshot = await _firestore
lib/src/features/matchpoint/data/matchpoint_remote_data_source.dart:585:    final snapshot = await _firestore
lib/src/features/matchpoint/data/matchpoint_remote_data_source.dart:624:    final snapshot = await _firestore
lib/src/features/matchpoint/data/matchpoint_remote_data_source.dart:636:    final doc = await _firestore
lib/src/features/matchpoint/data/matchpoint_remote_data_source.dart:666:      final snapshot = await _firestore
lib/src/features/matchpoint/data/matchpoint_remote_data_source.dart:702:      final snapshot = await _firestore
lib/src/features/matchpoint/data/matchpoint_remote_data_source.dart:722:    await _firestore.collection(FirestoreCollections.users).doc(userId).update({
lib/src/features/matchpoint/data/matchpoint_remote_data_source.dart:731:      FirebaseFirestore.instance,
lib/src/core/errors/failures.dart:211:  factory PermissionFailure.firestore() => const PermissionFailure(
lib/src/routing/auth_guard.dart:405:        normalized.contains('cloud_firestore/permission-denied');
lib/src/features/moderation/data/blocked_users_provider.dart:1:import 'package:cloud_firestore/cloud_firestore.dart';
lib/src/features/moderation/data/blocked_users_provider.dart:4:import '../../../constants/firestore_constants.dart';
lib/src/features/moderation/data/blocked_users_provider.dart:12:  return FirebaseFirestore.instance
lib/src/features/feed/domain/paginated_feed_response.dart:1:import 'package:cloud_firestore/cloud_firestore.dart';
lib/src/features/moderation/data/moderation_repository.dart:1:import 'package:cloud_firestore/cloud_firestore.dart';
lib/src/features/moderation/data/moderation_repository.dart:5:import '../../../constants/firestore_constants.dart';
lib/src/features/moderation/data/moderation_repository.dart:10:  return ModerationRepository(FirebaseFirestore.instance);
lib/src/features/moderation/data/moderation_repository.dart:14:  final FirebaseFirestore _firestore;
lib/src/features/moderation/data/moderation_repository.dart:16:  ModerationRepository(this._firestore);
lib/src/features/moderation/data/moderation_repository.dart:26:      await _firestore.collection(FirestoreCollections.reports).add({
lib/src/features/moderation/data/moderation_repository.dart:47:      final userRef = _firestore
lib/src/features/moderation/data/moderation_repository.dart:54:      final batch = _firestore.batch();
lib/src/features/moderation/data/moderation_repository.dart:82:      final userRef = _firestore
lib/src/features/moderation/data/moderation_repository.dart:89:      final batch = _firestore.batch();
lib/src/features/feed/presentation/feed_view_controller.dart:1:import 'package:cloud_firestore/cloud_firestore.dart';
lib/src/features/feed/data/feed_remote_data_source.dart:1:import 'package:cloud_firestore/cloud_firestore.dart';
lib/src/features/feed/data/feed_remote_data_source.dart:4:import '../../../constants/firestore_constants.dart';
lib/src/features/feed/data/feed_remote_data_source.dart:50:  final FirebaseFirestore _firestore;
lib/src/features/feed/data/feed_remote_data_source.dart:52:  FeedRemoteDataSourceImpl(this._firestore);
lib/src/features/feed/data/feed_remote_data_source.dart:58:    return _firestore
lib/src/features/feed/data/feed_remote_data_source.dart:82:    var query = _firestore
lib/src/features/feed/data/feed_remote_data_source.dart:104:    var query = _firestore
lib/src/features/feed/data/feed_remote_data_source.dart:126:    return _firestore.collection(FirestoreCollections.users).doc(uid).get();
lib/src/features/feed/data/feed_remote_data_source.dart:136:    var query = _firestore
lib/src/features/feed/data/feed_remote_data_source.dart:177:    var query = _firestore
lib/src/features/feed/data/feed_remote_data_source.dart:214:        _firestore
lib/src/features/feed/data/feed_remote_data_source.dart:226:    return _firestore
lib/src/features/feed/data/feed_remote_data_source.dart:238:    var query = _firestore
lib/src/features/feed/data/feed_remote_data_source.dart:266:  return FeedRemoteDataSourceImpl(FirebaseFirestore.instance);
lib/src/features/feed/presentation/feed_state.dart:1:import 'package:cloud_firestore/cloud_firestore.dart';
lib/src/features/favorites/data/favorite_repository.dart:1:import 'package:cloud_firestore/cloud_firestore.dart';
lib/src/features/favorites/data/favorite_repository.dart:11:  final FirebaseFirestore _firestore;
lib/src/features/favorites/data/favorite_repository.dart:12:  final FirebaseAuth _auth;
lib/src/features/favorites/data/favorite_repository.dart:14:  FavoriteRepository(this._firestore, this._auth);
lib/src/features/favorites/data/favorite_repository.dart:26:      final snapshot = await _firestore
lib/src/features/favorites/data/favorite_repository.dart:46:      var query = _firestore
lib/src/features/favorites/data/favorite_repository.dart:78:      final snapshot = await _firestore
lib/src/features/favorites/data/favorite_repository.dart:125:      final userDoc = await _firestore.collection('users').doc(targetId).get();
lib/src/features/favorites/data/favorite_repository.dart:130:      final profileDoc = await _firestore
lib/src/features/favorites/data/favorite_repository.dart:149:    final userRef = _firestore
lib/src/features/favorites/data/favorite_repository.dart:165:    final userRef = _firestore
lib/src/features/favorites/data/favorite_repository.dart:191:  return FavoriteRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
lib/src/features/feed/data/feed_repository.dart:1:import 'package:cloud_firestore/cloud_firestore.dart';
lib/src/features/feed/data/feed_repository.dart:5:import '../../../constants/firestore_constants.dart';
lib/src/features/feed/data/featured_profiles_repository.dart:1:import 'package:cloud_firestore/cloud_firestore.dart';
lib/src/features/feed/data/featured_profiles_repository.dart:15:  return FeaturedProfilesRepository(FirebaseFirestore.instance);
lib/src/features/feed/data/featured_profiles_repository.dart:19:  final FirebaseFirestore _firestore;
lib/src/features/feed/data/featured_profiles_repository.dart:21:  FeaturedProfilesRepository(this._firestore);
lib/src/features/feed/data/featured_profiles_repository.dart:28:      final doc = await _firestore
lib/src/features/feed/data/featured_profiles_repository.dart:68:        final doc = await _firestore.collection('users').doc(uid).get();
lib/src/features/favorites/domain/paginated_favorites_response.dart:1:import 'package:cloud_firestore/cloud_firestore.dart';

