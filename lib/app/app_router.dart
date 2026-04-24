import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_enums.dart';
import '../features/case_detail/presentation/case_detail_page.dart';
import '../features/cases/presentation/cases_page.dart';
import '../features/inbox/presentation/inbox_page.dart';
import '../features/intake/presentation/capture_simulation_page.dart';
import '../features/intake/presentation/extraction_result_page.dart';
import '../features/intake/presentation/processing_page.dart';
import '../features/intake/presentation/upload_review_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/screening/presentation/screening_page.dart';
import '../features/screening_hub/presentation/screening_hub_page.dart';
import '../features/tasks/presentation/task_detail_page.dart';
import 'app_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/inbox',
  routes: <RouteBase>[
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/inbox',
              builder: (context, state) => const InboxPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/cases',
              builder: (context, state) => const CasesPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/screening-hub',
              builder: (context, state) => const ScreeningHubPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/case/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return CaseDetailPage(caseId: id);
      },
    ),
    GoRoute(
      path: '/screening/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ScreeningPage(caseId: id);
      },
    ),
    GoRoute(
      path: '/task/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return TaskDetailPage(taskId: id);
      },
    ),
    GoRoute(
      path: '/upload-review/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return UploadReviewPage(jobId: id);
      },
    ),
    GoRoute(
      path: '/capture/:source',
      builder: (context, state) {
        final source =
            UploadSource.values.byName(state.pathParameters['source']!);
        return CaptureSimulationPage(source: source);
      },
    ),
    GoRoute(
      path: '/processing/:jobId',
      builder: (context, state) =>
          ProcessingPage(jobId: state.pathParameters['jobId']!),
    ),
    GoRoute(
      path: '/extraction/:jobId',
      builder: (context, state) =>
          ExtractionResultPage(jobId: state.pathParameters['jobId']!),
    ),
  ],
);
