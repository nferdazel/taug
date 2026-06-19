import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/calendar/presentation/pages/calendar_page.dart';
import '../../features/chart/presentation/pages/chart_page.dart';
import '../../features/layout/presentation/pages/main_layout.dart';
import '../../features/market/presentation/pages/market_page.dart';
import '../../features/news/presentation/pages/news_page.dart';
import '../../features/policy/presentation/pages/policy_page.dart';
import '../../features/portfolio/presentation/pages/portfolio_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/watchlist/presentation/pages/watchlist_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/watchlist',
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isAuthRoute =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    if (session == null && !isAuthRoute) {
      return '/login';
    }
    if (session != null && isAuthRoute) {
      return '/watchlist';
    }
    return null;
  },
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
