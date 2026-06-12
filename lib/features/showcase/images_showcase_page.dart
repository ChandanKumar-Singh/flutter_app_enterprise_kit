import 'package:flutter/material.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';
import 'package:enterprise_kit/shared/widgets/images/app_image.dart';

class ImagesShowcasePage extends StatelessWidget {
  const ImagesShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Images')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _label(context, 'Network Image (cached)'),
          AppImage.network(
            'https://picsum.photos/seed/ek1/600/300',
            width: double.infinity, height: 180,
            shape: AppImageShape.rounded, borderRadius: 12,
            enableFullScreen: true,
          ),
          const SizedBox(height: AppSpacing.md),

          _label(context, 'Network with placeholder'),
          AppImage.network(
            'https://picsum.photos/seed/ek2/400/400',
            width: 120, height: 120,
            shape: AppImageShape.circle,
          ),
          const SizedBox(height: AppSpacing.md),

          _label(context, 'Error state (broken URL)'),
          AppImage.network(
            'https://not-a-real-url.invalid/image.jpg',
            width: 200, height: 120, shape: AppImageShape.rounded,
          ),
          const SizedBox(height: AppSpacing.md),

          _label(context, 'Avatars'),
          Row(children: [
            AppAvatar(url: 'https://i.pravatar.cc/150?img=1', size: 64, fallbackText: 'JA'),
            const SizedBox(width: 12),
            const AppAvatar(url: null, size: 64, fallbackText: 'John Appleseed'),
            const SizedBox(width: 12),
            const AppAvatar(url: null, size: 48, fallbackText: 'AB', backgroundColor: Colors.teal),
            const SizedBox(width: 12),
            const AppAvatar(url: null, size: 36, fallbackText: 'X', backgroundColor: Colors.purple),
          ]),
          const SizedBox(height: AppSpacing.md),

          _label(context, 'Full Screen tap (network)'),
          GestureDetector(
            child: AppImage.network(
              'https://picsum.photos/seed/ek3/800/600',
              width: double.infinity, height: 200,
              shape: AppImageShape.rounded,
              heroTag: 'showcase_img',
              enableFullScreen: true,
            ),
          ),
          const SizedBox(height: 4),
          Text('Tap image to view full screen', style: Theme.of(context).textTheme.bodySmall),
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
