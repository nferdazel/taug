import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/companies/presentation/pages/companies_workspace_page.dart';
import '../../features/company/presentation/pages/company_workspace_page.dart';
import '../../features/data/presentation/pages/data_workspace_page.dart';
import '../../features/layout/presentation/pages/main_layout.dart';
import '../../features/portfolio/presentation/pages/portfolio_workspace_page.dart';
import '../../features/research/presentation/pages/research_workspace_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isAuthRoute =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    if (session == null && !isAuthRoute) {
      return '/login';
    }
    if (session != null && isAuthRoute) {
      return '/companies';
    }

    // Redirect legacy terminal routes to new workspace routes
    final legacyRedirects = {
      '/brief': '/companies',
      '/market': '/companies',
      '/company': '/companies',
      '/screener': '/companies',
      '/valuation': '/companies',
      '/watchlist': '/companies',
      '/chart': '/companies',
      '/news': '/companies',
      '/policy': '/companies',
      '/calendar': '/companies',
      '/portfolio': '/portfolio-workspace',
    };

    for (final entry in legacyRedirects.entries) {
      if (state.matchedLocation.startsWith(entry.key)) {
        return entry.value;
      }
    }

    return null;
  },
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFF43F5E)),
            const SizedBox(height: 16),
            const Text('Page not found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(state.error.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/companies'),
              child: const Text('Go to Companies'),
            ),
          ],
        ),
      ),
    ),
  ),
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(
          path: '/companies',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CompaniesWorkspacePage()),
          routes: [
            GoRoute(
              path: ':id',
              pageBuilder: (context, state) => NoTransitionPage(
                child: CompanyWorkspacePage(
                  companyId: state.pathParameters['id']!,
                ),
              ),
              routes: [
                GoRoute(path: 'overview', builder: (_, _) => const SizedBox()),
                GoRoute(path: 'financials', builder: (_, _) => const SizedBox()),
                GoRoute(path: 'research', builder: (_, _) => const SizedBox()),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/research',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ResearchWorkspacePage()),
        ),
        GoRoute(
          path: '/portfolio-workspace',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PortfolioWorkspacePage()),
        ),
        GoRoute(
          path: '/data',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DataWorkspacePage()),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SettingsPage()),
        ),
      ],
    ),
  ],
);
