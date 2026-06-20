import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dictionary/presentation/dictionary_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/review/presentation/review_setup_screen.dart';
import '../../features/review/presentation/review_session_screen.dart';
import '../../features/review/presentation/review_result_screen.dart';

final appRouterHelperProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dictionary',
    routes: [
      GoRoute(
        path: '/dictionary',
        name: 'dictionary',
        builder: (context, state) {
          final query = state.uri.queryParameters['query'];
          return DictionaryScreen(autoQuery: query);
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/favorites',
        name: 'favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/review/setup',
        name: 'review_setup',
        builder: (context, state) => const ReviewSetupScreen(),
      ),
      GoRoute(
        path: '/review/session',
        name: 'review_session',
        builder: (context, state) => const ReviewSessionScreen(),
      ),
      GoRoute(
        path: '/review/result',
        name: 'review_result',
        builder: (context, state) => const ReviewResultScreen(),
      ),
    ],
  );
});
