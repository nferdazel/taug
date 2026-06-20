import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/brief/presentation/pages/brief_page.dart';
import '../../features/calendar/presentation/pages/calendar_page.dart';
import '../../features/chart/presentation/pages/chart_page.dart';
import '../../features/companies/presentation/pages/companies_workspace_page.dart';
import '../../features/company/presentation/pages/company_workspace_page.dart';
import '../../features/data/presentation/pages/data_workspace_page.dart';
import '../../features/company/presentation/pages/company_page.dart';
import '../../features/layout/presentation/pages/main_layout.dart';
import '../../features/market/presentation/pages/market_page.dart';
import '../../features/news/presentation/pages/news_page.dart';
import '../../features/policy/presentation/pages/policy_page.dart';
import '../../features/portfolio/presentation/pages/portfolio_page.dart';
import '../../features/portfolio/presentation/pages/portfolio_workspace_page.dart';
import '../../features/research/presentation/pages/research_page.dart';
import '../../features/screener/presentation/pages/screener_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/valuation/presentation/pages/valuation_page.dart';
import '../../features/watchlist/presentation/pages/watchlist_page.dart';

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
    return null;
  },
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(state.error.toString(), textAlign: TextAlign.center),
      ),
    ),
  ),
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        // New MVP routes
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
                GoRoute(path: 'overview', builder: (_, __) => const SizedBox()),
                GoRoute(path: 'financials', builder: (_, __) => const SizedBox()),
                GoRoute(path: 'research', builder: (_, __) => const SizedBox()),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/research',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ResearchPage()),
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
        // Legacy terminal routes (preserved)
        GoRoute(
          path: '/brief',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: BriefPage()),
        ),
        GoRoute(
          path: '/market',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: MarketPage()),
        ),
        GoRoute(
          path: '/watchlist',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: WatchlistPage()),
        ),
        GoRoute(
          path: '/portfolio',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PortfolioPage()),
        ),
        GoRoute(
          path: '/chart',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ChartPage()),
        ),
        GoRoute(
          path: '/company',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CompanyPage()),
        ),
        GoRoute(
          path: '/screener',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ScreenerPage()),
        ),
        GoRoute(
          path: '/valuation',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ValuationPage()),
        ),
        GoRoute(
          path: '/news',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: NewsPage()),
        ),
        GoRoute(
          path: '/policy',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PolicyPage()),
        ),
        GoRoute(
          path: '/calendar',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CalendarPage()),
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
