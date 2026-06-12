import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:enterprise_kit/core/router/route_names.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) context.go(RouteNames.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: colors.onPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.layers_rounded, size: 56, color: colors.onPrimary),
            ).animate()
              .scale(duration: 600.ms, curve: Curves.easeOutBack)
              .fade(duration: 600.ms),

            const SizedBox(height: 24),

            Text('Enterprise Kit',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: colors.onPrimary,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ).animate(delay: 300.ms)
              .slideY(begin: 0.3, duration: 500.ms, curve: Curves.easeOut)
              .fade(duration: 500.ms),

            const SizedBox(height: 8),

            Text('Flutter • Enterprise • 0 to 100',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onPrimary.withOpacity(0.7),
              ),
            ).animate(delay: 500.ms).fade(duration: 400.ms),

            const SizedBox(height: 64),

            SizedBox(
              width: 32, height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(colors.onPrimary.withOpacity(0.7)),
              ),
            ).animate(delay: 800.ms).fade(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
