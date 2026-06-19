import 'package:flutter/material.dart';
import 'package:signals/signals.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/config/app_env.dart';
import 'core/config/app_router.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_typography.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SignalsObserver.instance = null;
  GoogleFonts.config.allowRuntimeFetching = false;

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint(details.exceptionAsString());
    debugPrintStack(stackTrace: details.stack);
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return _BootstrapErrorApp(
      message: details.exceptionAsString(),
      details: details.stack.toString(),
    );
  };

  try {
    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      anonKey: AppEnv.supabaseAnonKey,
      postgrestOptions: const PostgrestClientOptions(schema: 'taug'),
    );
    runApp(const TaugApp());
  } catch (error, stackTrace) {
    debugPrint('[Bootstrap] $error');
    debugPrintStack(stackTrace: stackTrace);
    runApp(
      _BootstrapErrorApp(
        message: error.toString(),
        details: stackTrace.toString(),
      ),
    );
  }
}

class TaugApp extends StatelessWidget {
  const TaugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Taug',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}

class _BootstrapErrorApp extends StatelessWidget {
  final String message;
  final String details;

  const _BootstrapErrorApp({required this.message, required this.details});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taug',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: Scaffold(
        backgroundColor: const Color(AppColors.background),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(AppColors.surface),
                  border: Border.all(color: const Color(AppColors.border)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TAUG STARTUP FAILURE',
                        style: AppTypography.monoSection.copyWith(
                          color: const Color(AppColors.bearish),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(message, style: AppTypography.bodyMedium),
                      const SizedBox(height: 12),
                      SelectableText(
                        details,
                        style: AppTypography.monoTiny.copyWith(
                          color: const Color(AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
