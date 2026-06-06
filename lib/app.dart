import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'data/models/parsed_excel_model.dart';
import 'presentation/home/home_screen.dart';
import 'presentation/import/column_selection_screen.dart';
import 'presentation/section/section_screen.dart';
import 'presentation/session/session_screen.dart';
import 'presentation/session/summary_screen.dart';
import 'presentation/session/edit_session_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/import/columns',
      builder: (context, state) {
        final model = state.extra as ParsedExcelModel;
        return ColumnSelectionScreen(parsedExcel: model);
      },
    ),
    GoRoute(
      path: '/section/:sectionId',
      builder: (context, state) {
        final sectionId = int.parse(state.pathParameters['sectionId']!);
        return SectionScreen(sectionId: sectionId);
      },
      routes: [
        GoRoute(
          path: 'session/:sessionId',
          builder: (context, state) {
            final sectionId =
                int.parse(state.pathParameters['sectionId']!);
            final sessionId =
                int.parse(state.pathParameters['sessionId']!);
            return SessionScreen(
              sectionId: sectionId,
              sessionId: sessionId,
            );
          },
          routes: [
            GoRoute(
              path: 'summary',
              builder: (context, state) {
                final sectionId =
                    int.parse(state.pathParameters['sectionId']!);
                final sessionId =
                    int.parse(state.pathParameters['sessionId']!);
                return SummaryScreen(
                  sectionId: sectionId,
                  sessionId: sessionId,
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: 'session/:sessionId/edit',
          builder: (context, state) {
            final sectionId =
                int.parse(state.pathParameters['sectionId']!);
            final sessionId =
                int.parse(state.pathParameters['sessionId']!);
            return EditSessionScreen(
              sectionId: sectionId,
              sessionId: sessionId,
            );
          },
        ),
      ],
    ),
  ],
);

class AttendanceApp extends ConsumerWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoApp.router(
      title: 'AttendAce',
      debugShowCheckedModeBanner: false,
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: Color(0xFF0D1B2A),
        barBackgroundColor: Color(0xFFFFFFFF),
        textTheme: CupertinoTextThemeData(
          primaryColor: Color(0xFF0D1B2A),
        ),
      ),
      routerConfig: router,
    );
  }
}
