// ignore_for_file: deprecated_member_use
import 'dart:ui';
import 'package:flutter/material.dart';

// ─── Gradient Presets ─────────────────────────────────────────────────────────
class AppGradients {
  AppGradients._();

  // Ocean
  static const ocean = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF0891B2)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  // Sunset
  static const sunset = LinearGradient(
    colors: [Color(0xFFEC4899), Color(0xFFEF4444), Color(0xFFF97316)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  // Forest
  static const forest = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF0D9488)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  // Midnight
  static const midnight = LinearGradient(
    colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  // Aurora
  static const aurora = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6), Color(0xFFEC4899)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  // Fire
  static const fire = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFF97316), Color(0xFFFBBF24)],
    begin: Alignment.bottomLeft, end: Alignment.topRight,
  );

  // Lavender
  static const lavender = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  // Arctic
  static const arctic = LinearGradient(
    colors: [Color(0xFFBAE6FD), Color(0xFFEDE9FE)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  // Radial
  static const radialGlow = RadialGradient(
    colors: [Color(0xFF60A5FA), Color(0xFF1E3A8A)],
    radius: 0.8,
  );

  static LinearGradient fromColor(Color color, {double opacity = 0.8}) =>
      LinearGradient(
        colors: [
          color.withOpacity(opacity),
          color.withOpacity(opacity * 0.6),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient shimmer({bool dark = false}) => LinearGradient(
        colors: dark
            ? [
                const Color(0xFF1F2937),
                const Color(0xFF374151),
                const Color(0xFF1F2937),
              ]
            : [
                const Color(0xFFF1F5F9),
                const Color(0xFFE2E8F0),
                const Color(0xFFF1F5F9),
              ],
        stops: const [0.0, 0.5, 1.0],
        begin: const Alignment(-1, 0),
        end: const Alignment(1, 0),
      );
}

// ─── Gradient Container ───────────────────────────────────────────────────────
class AppGradientBox extends StatelessWidget {
  final Gradient gradient;
  final Widget? child;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;

  const AppGradientBox({
    super.key,
    required this.gradient,
    this.child,
    this.borderRadius,
    this.width,
    this.height,
    this.padding,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: border,
        boxShadow: boxShadow,
      ),
      child: child,
    );
  }
}

// ─── Glassmorphism Card ───────────────────────────────────────────────────────
class AppGlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final Color? tint;
  final double tintOpacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Border? border;
  final double? width;
  final double? height;

  const AppGlassCard({
    super.key,
    required this.child,
    this.blur = 12,
    this.tint,
    this.tintOpacity = 0.15,
    this.borderRadius,
    this.padding,
    this.border,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultTint = isDark ? Colors.white : Colors.white;
    final radius = borderRadius ?? BorderRadius.circular(20);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: radius,
            color: (tint ?? defaultTint).withOpacity(tintOpacity),
            border: border ??
                Border.all(
                  color: (isDark ? Colors.white : Colors.white).withOpacity(0.25),
                  width: 1,
                ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── Frosted Surface ──────────────────────────────────────────────────────────
class AppFrostedSurface extends StatelessWidget {
  final Widget child;
  final double blur;
  final Color? color;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  const AppFrostedSurface({
    super.key,
    required this.child,
    this.blur = 20,
    this.color,
    this.opacity = 0.7,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          color: (color ?? surface).withOpacity(opacity),
          child: child,
        ),
      ),
    );
  }
}

// ─── Gradient Text ────────────────────────────────────────────────────────────
class AppGradientText extends StatelessWidget {
  final String text;
  final Gradient gradient;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;

  const AppGradientText({
    super.key,
    required this.text,
    this.gradient = AppGradients.aurora,
    this.style,
    this.textAlign,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
      ),
    );
  }
}

// ─── Gradient Icon ────────────────────────────────────────────────────────────
class AppGradientIcon extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final double size;

  const AppGradientIcon({
    super.key,
    required this.icon,
    this.gradient = AppGradients.ocean,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) =>
          gradient.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Icon(icon, size: size, color: Colors.white),
    );
  }
}

// ─── Gradient Scaffold Background ─────────────────────────────────────────────
class AppGradientBackground extends StatelessWidget {
  final Widget child;
  final Gradient gradient;

  const AppGradientBackground({
    super.key,
    required this.child,
    this.gradient = AppGradients.midnight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: child,
    );
  }
}

// ─── Mesh Gradient (simulated with radial gradients) ──────────────────────────
class AppMeshGradient extends StatelessWidget {
  final Color primary;
  final Color secondary;
  final Color? tertiary;

  const AppMeshGradient({
    super.key,
    required this.primary,
    required this.secondary,
    this.tertiary,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.8, -0.8),
                radius: 1.2,
                colors: [primary.withOpacity(0.6), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.8, 0.8),
                radius: 1.2,
                colors: [secondary.withOpacity(0.5), Colors.transparent],
              ),
            ),
          ),
        ),
        if (tertiary != null)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.5),
                  radius: 0.8,
                  colors: [tertiary!.withOpacity(0.3), Colors.transparent],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
