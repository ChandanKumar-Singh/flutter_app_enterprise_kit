import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';
import 'package:enterprise_kit/shared/widgets/buttons/app_button.dart';

class ButtonsShowcasePage extends StatefulWidget {
  const ButtonsShowcasePage({super.key});
  @override State<ButtonsShowcasePage> createState() => _ButtonsShowcasePageState();
}

class _ButtonsShowcasePageState extends State<ButtonsShowcasePage> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buttons')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _Section('Variants', [
            AppButton.filled(label: 'Filled', onPressed: () {}),
            const SizedBox(height: 8),
            AppButton.outlined(label: 'Outlined', onPressed: () {}),
            const SizedBox(height: 8),
            AppButton.tonal(label: 'Tonal', onPressed: () {}),
            const SizedBox(height: 8),
            AppButton(label: 'Elevated', onPressed: () {}, variant: AppButtonVariant.elevated),
            const SizedBox(height: 8),
            AppButton.text(label: 'Text Button', onPressed: () {}),
            const SizedBox(height: 8),
            AppButton.destructive(label: 'Destructive', onPressed: () {}),
            const SizedBox(height: 8),
            AppButton(label: 'Ghost', onPressed: () {}, variant: AppButtonVariant.ghost),
            const SizedBox(height: 8),
            AppButton(label: 'Link Button', onPressed: () {}, variant: AppButtonVariant.link),
          ]),

          _Section('Sizes', [
            AppButton.filled(label: 'Extra Small', onPressed: () {}, size: AppButtonSize.xs),
            const SizedBox(height: 8),
            AppButton.filled(label: 'Small', onPressed: () {}, size: AppButtonSize.sm),
            const SizedBox(height: 8),
            AppButton.filled(label: 'Medium (Default)', onPressed: () {}, size: AppButtonSize.md),
            const SizedBox(height: 8),
            AppButton.filled(label: 'Large', onPressed: () {}, size: AppButtonSize.lg),
            const SizedBox(height: 8),
            AppButton.filled(label: 'Extra Large', onPressed: () {}, size: AppButtonSize.xl),
          ]),

          _Section('States', [
            AppButton.filled(label: 'Loading', onPressed: () {}, isLoading: _loading,
              icon: const Icon(Iconsax.document_download)),
            const SizedBox(height: 8),
            AppButton.filled(label: 'Disabled', onPressed: null),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => setState(() => _loading = !_loading),
              child: Text(_loading ? 'Stop Loading' : 'Start Loading'),
            ),
          ]),

          _Section('With Icons', [
            AppButton.filled(
              label: 'Leading Icon',
              onPressed: () {},
              icon: const Icon(Iconsax.star, size: 18),
            ),
            const SizedBox(height: 8),
            AppButton(
              label: 'Trailing Icon',
              onPressed: () {},
              trailingIcon: const Icon(Iconsax.arrow_right_1, size: 18),
              variant: AppButtonVariant.outlined,
            ),
            const SizedBox(height: 8),
            Row(children: [
              AppButton.icon(
                icon: const Icon(Iconsax.heart),
                onPressed: () {},
                tooltip: 'Favourite',
              ),
              const SizedBox(width: 8),
              AppButton.icon(
                icon: const Icon(Iconsax.send_2),
                onPressed: () {},
                tooltip: 'Share',
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              ),
              const SizedBox(width: 8),
              AppButton.icon(
                icon: const Icon(Iconsax.trash),
                onPressed: () {},
                foregroundColor: Theme.of(context).colorScheme.error,
                tooltip: 'Delete',
              ),
            ]),
          ]),

          _Section('FAB', [
            Row(children: [
              AppButton.fab(
                icon: const Icon(Iconsax.add),
                onPressed: () {},
              ),
              const SizedBox(width: 16),
              AppButton.fab(
                icon: const Icon(Iconsax.edit),
                label: 'Edit',
                onPressed: () {},
              ),
            ]),
          ]),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section(this.title, this.children);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary)),
        ),
        ...children,
        const Divider(height: AppSpacing.xxl),
      ],
    );
  }
}
