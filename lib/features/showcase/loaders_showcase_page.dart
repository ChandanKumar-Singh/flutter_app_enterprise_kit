import 'package:flutter/material.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';
import 'package:enterprise_kit/shared/widgets/loaders/app_shimmer.dart';

class LoadersShowcasePage extends StatelessWidget {
  const LoadersShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loaders & Shimmer')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _label(context, 'Circular Progress'),
          const Row(children: [
            CircularProgressIndicator(), SizedBox(width: 20),
            SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 20),
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          ]),
          const SizedBox(height: AppSpacing.lg),

          _label(context, 'Linear Progress'),
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          const LinearProgressIndicator(value: 0.7),
          const SizedBox(height: AppSpacing.lg),

          _label(context, 'Shimmer — List Items'),
          AppShimmer.list(count: 3),
          const SizedBox(height: AppSpacing.lg),

          _label(context, 'Shimmer — Card'),
          AppShimmer.card(),
          const SizedBox(height: AppSpacing.lg),

          _label(context, 'Shimmer — Stat Cards'),
          Row(children: [
            Expanded(child: AppShimmer.statCard()),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: AppShimmer.statCard()),
          ]),
          const SizedBox(height: AppSpacing.lg),

          _label(context, 'Shimmer — Individual shapes'),
          AppShimmer(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppShimmer.circle(size: 56),
              const SizedBox(height: 12),
              AppShimmer.text(width: 200, height: 18),
              const SizedBox(height: 8),
              AppShimmer.text(width: double.infinity, height: 12),
              const SizedBox(height: 6),
              AppShimmer.text(width: 260, height: 12),
              const SizedBox(height: 12),
              AppShimmer.box(width: double.infinity, height: 120),
            ],
          )),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
  );
}
