import 'package:flutter/material.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';
import 'package:enterprise_kit/shared/widgets/texts/app_text.dart';

class TypographyShowcasePage extends StatelessWidget {
  const TypographyShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Typography')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppText.displayLarge('Display Large'),
          AppText.displayMedium('Display Medium'),
          AppText.displaySmall('Display Small'),
          const Divider(height: AppSpacing.xl),
          AppText.headlineLarge('Headline Large'),
          AppText.headlineMedium('Headline Medium'),
          AppText.headlineSmall('Headline Small'),
          const Divider(height: AppSpacing.xl),
          AppText.titleLarge('Title Large'),
          AppText.titleMedium('Title Medium'),
          AppText.titleSmall('Title Small'),
          const Divider(height: AppSpacing.xl),
          AppText.bodyLarge('Body Large — The quick brown fox jumps over the lazy dog.'),
          AppText.bodyMedium('Body Medium — The quick brown fox jumps over the lazy dog.'),
          AppText.bodySmall('Body Small — The quick brown fox jumps over the lazy dog.'),
          const Divider(height: AppSpacing.xl),
          AppText.labelLarge('Label Large'),
          AppText.labelMedium('Label Medium'),
          AppText.labelSmall('Label Small'),
          const Divider(height: AppSpacing.xl),
          AppText.caption('Caption — fine print text'),
          AppText.overline('OVERLINE TEXT'),
          const Divider(height: AppSpacing.xl),
          _label(context, 'Rich / Linked Text'),
          AppText.rich([
            AppText.span('This is '),
            AppText.span('bold text', style: const TextStyle(fontWeight: FontWeight.bold)),
            AppText.span(' and this is '),
            AppText.linkSpan('a tappable link', onTap: () {}, color: colors.primary),
            AppText.span(' in the same line.'),
          ]),
          const SizedBox(height: AppSpacing.md),
          _label(context, 'Colored text'),
          AppText.bodyLarge('Success message', color: Colors.green),
          AppText.bodyLarge('Error message', color: colors.error),
          AppText.bodyLarge('Warning message', color: Colors.orange),
          AppText.bodyLarge('Info message', color: colors.primary),
          const SizedBox(height: AppSpacing.md),
          _label(context, 'Max lines / truncation'),
          AppText.bodyMedium(
            'This is a very long text that should be truncated after two lines. The quick brown fox jumps over the lazy dog. Lorem ipsum dolor sit amet consectetur adipiscing elit.',
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
  );
}
