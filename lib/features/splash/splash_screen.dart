import 'package:birthday/core/theme/app_colors.dart';
import 'package:birthday/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      final session = Supabase.instance.client.auth.currentSession;
      context.go(session != null ? '/home' : '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: Lottie.asset(
                'assets/animations/splash_cake.json',
                repeat: true,
                errorBuilder: (ctx, e, s) => const _CakePlaceholder(),
              ),
            ).animate().scale(
              duration: 600.ms,
              curve: Curves.easeOutBack,
            ),
            const SizedBox(height: 28),
            Text(
              'Birthday Buddy',
              style: AppTextStyles.displayLarge,
            ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(
              begin: 0.2,
              end: 0,
              delay: 400.ms,
              duration: 500.ms,
            ),
            const SizedBox(height: 8),
            Text(
              'Nunca esqueça um aniversário',
              style: AppTextStyles.bodyLarge,
            ).animate().fadeIn(delay: 700.ms, duration: 600.ms),
            const SizedBox(height: 64),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                strokeWidth: 2.5,
              ),
            ).animate().fadeIn(delay: 1000.ms),
          ],
        ),
      ),
    );
  }
}

class _CakePlaceholder extends StatelessWidget {
  const _CakePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.cake_rounded, size: 80, color: AppColors.primary);
  }
}
