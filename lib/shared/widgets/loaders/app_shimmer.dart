import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AppShimmer extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;

  const AppShimmer({
    super.key,
    required this.child,
    this.isLoading = true,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;
    final colors = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: baseColor ?? colors.surfaceVariant,
      highlightColor: highlightColor ?? colors.surface,
      child: child,
    );
  }

  // ── Pre-built skeleton shapes ──────────────────────────────────────────────

  static Widget box({
    required double width,
    required double height,
    double borderRadius = 8,
    Color? color,
  }) => _ShimmerBox(width: width, height: height, borderRadius: borderRadius, color: color);

  static Widget text({
    required double width,
    double height = 14,
    Color? color,
  }) => _ShimmerBox(width: width, height: height, borderRadius: 4, color: color);

  static Widget circle({required double size, Color? color}) =>
      _ShimmerBox(width: size, height: size, borderRadius: size / 2, color: color);

  // ── Pre-built skeleton cards ───────────────────────────────────────────────

  static Widget listItem({bool hasAvatar = true}) => _ShimmerListItem(hasAvatar: hasAvatar);
  static Widget card() => const _ShimmerCard();
  static Widget mediaCard() => const _ShimmerMediaCard();
  static Widget statCard() => const _ShimmerStatCard();

  // ── List of N skeleton items ───────────────────────────────────────────────
  static Widget list({
    int count = 5,
    bool hasAvatar = true,
    Widget? itemBuilder,
  }) {
    return Column(
      children: List.generate(count, (i) =>
          Padding(padding: const EdgeInsets.only(bottom: 12),
              child: listItem(hasAvatar: hasAvatar))),
    );
  }

  static Widget grid({int count = 6, int crossAxisCount = 2}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: count,
      itemBuilder: (_, __) => const _ShimmerMediaCard(),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double width, height, borderRadius;
  final Color? color;
  const _ShimmerBox({required this.width, required this.height,
      required this.borderRadius, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class _ShimmerListItem extends StatelessWidget {
  final bool hasAvatar;
  const _ShimmerListItem({required this.hasAvatar});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasAvatar) ...[
            AppShimmer.circle(size: 48),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmer.text(width: double.infinity, height: 14),
                const SizedBox(height: 8),
                AppShimmer.text(width: 200, height: 12),
                const SizedBox(height: 6),
                AppShimmer.text(width: 140, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppShimmer.text(width: 160, height: 16),
            const SizedBox(height: 12),
            AppShimmer.text(width: double.infinity, height: 12),
            const SizedBox(height: 6),
            AppShimmer.text(width: double.infinity, height: 12),
            const SizedBox(height: 6),
            AppShimmer.text(width: 200, height: 12),
          ],
        ),
      ),
    );
  }
}

class _ShimmerMediaCard extends StatelessWidget {
  const _ShimmerMediaCard();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppShimmer.box(
              width: double.infinity, height: 120, borderRadius: 8),
          const SizedBox(height: 8),
          AppShimmer.text(width: double.infinity, height: 14),
          const SizedBox(height: 6),
          AppShimmer.text(width: 100, height: 12),
        ],
      ),
    );
  }
}

class _ShimmerStatCard extends StatelessWidget {
  const _ShimmerStatCard();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            AppShimmer.circle(size: 40),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmer.text(width: 80, height: 12),
                const SizedBox(height: 6),
                AppShimmer.text(width: 120, height: 20),
              ],
            )),
          ],
        ),
      ),
    );
  }
}
