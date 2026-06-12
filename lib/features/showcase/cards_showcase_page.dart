import 'package:flutter/material.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';
import 'package:enterprise_kit/shared/widgets/cards/app_card.dart';

class CardsShowcasePage extends StatelessWidget {
  const CardsShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cards')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _label(context, 'Basic'),
          AppCard.basic(child: const Padding(padding: EdgeInsets.all(16), child: Text('Basic card — no elevation, outlined border.'))),
          const SizedBox(height: AppSpacing.md),

          _label(context, 'Elevated'),
          AppCard.elevated(child: const Padding(padding: EdgeInsets.all(16), child: Text('Elevated card with shadow.')), elevation: 6),
          const SizedBox(height: AppSpacing.md),

          _label(context, 'Outlined'),
          AppCard.outlined(child: const Padding(padding: EdgeInsets.all(16), child: Text('Outlined card with colored border.')), borderColor: Colors.blue),
          const SizedBox(height: AppSpacing.md),

          _label(context, 'Filled'),
          AppCard.filled(child: const Padding(padding: EdgeInsets.all(16), child: Text('Filled card with surface-variant background.'))),
          const SizedBox(height: AppSpacing.md),

          _label(context, 'Media'),
          AppCard.media(
            media: Container(height: 160, color: Colors.blue.shade100,
                child: const Icon(Icons.image, size: 64, color: Colors.blue)),
            title: 'Media Card',
            subtitle: 'Card with media area at top',
            body: 'This card contains a media area above content.',
            actions: [TextButton(onPressed: () {}, child: const Text('Action'))],
          ),
          const SizedBox(height: AppSpacing.md),

          _label(context, 'Stat'),
          Row(children: [
            Expanded(child: AppCard.stat(
              title: 'Total Users',
              value: '12.4K',
              subtitle: '+8.3% this week',
              leading: Icon(Icons.people_outline, color: Colors.blue.shade600, size: 32),
            )),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: AppCard.stat(
              title: 'Revenue',
              value: '\$48.2K',
              subtitle: '+12% vs last month',
              leading: Icon(Icons.attach_money, color: Colors.green.shade600, size: 32),
            )),
          ]),
          const SizedBox(height: AppSpacing.md),

          _label(context, 'List'),
          AppCard.list(
            title: 'List Card', subtitle: 'Subtitle text goes here',
            leading: CircleAvatar(backgroundColor: Colors.blue.shade100,
                child: Icon(Icons.person_outline, color: Colors.blue.shade700)),
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.md),

          _label(context, 'Profile'),
          AppCard.profile(
            name: 'John Appleseed', role: 'Senior Engineer',
            avatar: const Icon(Icons.person),
            actions: [
              TextButton(onPressed: () {}, child: const Text('Message')),
              TextButton(onPressed: () {}, child: const Text('Follow')),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          _label(context, 'Gradient'),
          AppCard.gradient(
            title: 'Gradient Card',
            subtitle: 'With linear gradient background',
            gradientColors: [Colors.blue.shade400, Colors.purple.shade600],
            trailing: const Icon(Icons.star, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.md),

          _label(context, 'Action'),
          AppCard.action(
            title: 'Notifications',
            subtitle: 'Manage your alerts',
            leading: Icon(Icons.notifications_outlined, color: Colors.orange.shade700),
            badge: '3',
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.md),

          _label(context, 'Horizontal'),
          AppCard.horizontal(
            leading: Container(color: Colors.teal.shade100,
                child: Icon(Icons.music_note, color: Colors.teal.shade700, size: 40)),
            title: 'Horizontal Card',
            subtitle: 'Image + text side by side',
            trailing: const Icon(Icons.more_vert),
            onTap: () {},
          ),
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
