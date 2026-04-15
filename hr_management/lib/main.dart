import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'app_colors.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_shell.dart';
import 'l10n/app_localizations.dart';
import 'providers/language_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return MaterialApp(
      title: 'HR Nepal',
      debugShowCheckedModeBanner: false,

      // ── Localization (NEW) ──────────────────────────────────────────────
      locale: lang.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ── Theme (unchanged from your original) ───────────────────────────
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// SplashScreen is identical to your original — no changes needed
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 1));
    final isLoggedIn = await _authService.isLoggedIn();
    if (!mounted) return;
    if (isLoggedIn) {
      final employee = await _authService.getCurrentUser();
      if (employee != null) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => MainShell(employee: employee)));
        return;
      }
    }
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.headerGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 24, offset: const Offset(0, 8)),
              ],
            ),
            child: const Icon(Icons.business_center_rounded,
                size: 40, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text('HR Nepal',
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          const Text('HR Management System',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 40),
          const CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2),
        ]),
      ),
    );
  }
}
