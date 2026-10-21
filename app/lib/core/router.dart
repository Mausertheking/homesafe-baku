import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_service.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/checks/check_flow_screen.dart';
import '../features/checks/check_outcome.dart';
import '../features/checks/check_result_screen.dart';
import '../features/checks/history_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/emergency/emergency_screen.dart';
import '../features/evidence/evidence_screen.dart';
import '../features/evidence/report_screen.dart';
import '../features/home_profile/home_profile_screen.dart';
import '../features/letters/letters_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/rights/legal_doc_screen.dart';
import '../features/rights/rights_screen.dart';
import '../features/settings/settings_screen.dart';
import 'settings.dart';

/// Routes that never redirect: the emergency screen must always open.
const _openRoutes = {'/emergency', '/onboarding', '/sign-in', '/legal/privacy', '/legal/terms'};

final routerProvider = Provider<GoRouter>((ref) {
  // Re-run redirects when onboarding / auth / guest state changes.
  final refresh = ValueNotifier(0);
  ref.listen(settingsProvider, (_, _) => refresh.value++);
  ref.listen(currentUserProvider, (_, _) => refresh.value++);
  ref.listen(authResolvedProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final path = state.matchedLocation;
      if (path == '/emergency') return null;
      final settings = ref.read(settingsProvider);
      if (!settings.onboardingDone) return path == '/onboarding' ? null : '/onboarding';
      // Still restoring the saved login: stay where we are for now.
      if (!ref.read(authResolvedProvider)) return null;
      final signedIn = ref.read(currentUserProvider) != null;
      if (!signedIn && !settings.guestMode && !_openRoutes.contains(path)) return '/sign-in';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
      GoRoute(path: '/emergency', builder: (_, _) => const EmergencyScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/sign-in', builder: (_, _) => const SignInScreen()),
      GoRoute(path: '/profile', builder: (_, _) => const HomeProfileScreen()),
      GoRoute(
        path: '/check/:id',
        builder: (_, s) => CheckFlowScreen(checkId: s.pathParameters['id'] == 'damp_mold' ? 'damp_mold' : 'gas_co'),
      ),
      GoRoute(
        path: '/result',
        redirect: (_, s) => s.extra is CheckOutcome ? null : '/',
        builder: (_, s) => CheckResultScreen(outcome: s.extra! as CheckOutcome),
      ),
      GoRoute(path: '/history', builder: (_, _) => const HistoryScreen()),
      GoRoute(path: '/evidence', builder: (_, _) => const EvidenceScreen()),
      GoRoute(path: '/evidence/report', builder: (_, _) => const ReportScreen()),
      GoRoute(path: '/letters', builder: (_, _) => const LettersScreen()),
      GoRoute(path: '/letters/new', builder: (_, s) => NewLetterScreen(initialProblem: s.extra as String?)),
      GoRoute(
        path: '/letters/preview',
        redirect: (_, s) => s.extra is LetterPreviewData ? null : '/letters',
        builder: (_, s) => LetterPreviewScreen(data: s.extra! as LetterPreviewData),
      ),
      GoRoute(path: '/rights', builder: (_, _) => const RightsScreen()),
      GoRoute(
        path: '/rights/topic',
        redirect: (_, s) => s.extra is LegalTopic ? null : '/rights',
        builder: (_, s) => RightsTopicScreen(topic: s.extra! as LegalTopic),
      ),
      GoRoute(path: '/chat', builder: (_, s) => ChatScreen(initialText: s.extra as String?)),
      GoRoute(path: '/legal/privacy', builder: (_, _) => const LegalDocScreen(kind: 'privacy')),
      GoRoute(path: '/legal/terms', builder: (_, _) => const LegalDocScreen(kind: 'terms')),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    ],
  );
});
