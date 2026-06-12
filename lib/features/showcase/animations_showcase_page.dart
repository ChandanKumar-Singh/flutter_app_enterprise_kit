import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';
import 'package:enterprise_kit/shared/widgets/buttons/app_button.dart';

class AnimationsShowcasePage extends StatefulWidget {
  const AnimationsShowcasePage({super.key});
  @override State<AnimationsShowcasePage> createState() => _AnimationsShowcasePageState();
}

class _AnimationsShowcasePageState extends State<AnimationsShowcasePage> {
  bool _show = true;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Animations')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _label(context, 'Stagger (tap to replay)'),
          AppButton.outlined(label: 'Replay', onPressed: () {
            setState(() { _show = false; });
            Future.delayed(50.ms, () { if (mounted) setState(() => _show = true); });
          }),
          const SizedBox(height: AppSpacing.md),
          if (_show) Column(
            children: List.generate(5, (i) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              height: 48,
              decoration: BoxDecoration(
                color: HSLColor.fromAHSL(1, i * 40.0, 0.7, 0.5).toColor(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Text('Item ${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ).animate(delay: Duration(milliseconds: 100 * i))
              .slideX(begin: -0.3, duration: 400.ms, curve: Curves.easeOut)
              .fade(duration: 400.ms)),
          ),

          const SizedBox(height: AppSpacing.lg),
          _label(context, 'Effect types'),
          Wrap(spacing: 12, runSpacing: 12, children: [
            _AnimTile('Fade', colors.primaryContainer, colors.onPrimaryContainer,
                (child) => child.animate(onPlay: (c) => c.repeat(reverse: true)).fade(duration: 1.seconds)),
            _AnimTile('Scale', colors.secondaryContainer, colors.onSecondaryContainer,
                (child) => child.animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: 800.ms)),
            _AnimTile('Slide', colors.tertiaryContainer, colors.onTertiaryContainer,
                (child) => child.animate(onPlay: (c) => c.repeat(reverse: true)).slideX(begin: -0.2, duration: 700.ms)),
            _AnimTile('Blur', colors.errorContainer, colors.onErrorContainer,
                (child) => child.animate(onPlay: (c) => c.repeat(reverse: true)).blur(begin: const Offset(0, 0), end: const Offset(4, 4), duration: 1.seconds)),
            _AnimTile('Shake', colors.surfaceVariant, colors.onSurfaceVariant,
                (child) => child.animate(onPlay: (c) => c.repeat()).shake(duration: 1.seconds)),
            _AnimTile('Flip H', colors.primaryContainer, colors.onPrimaryContainer,
                (child) => child.animate(onPlay: (c) => c.repeat()).flipH(duration: 1.2.seconds)),
          ]),
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

class _AnimTile extends StatelessWidget {
  final String label;
  final Color bg, fg;
  final Widget Function(Widget) animate;
  const _AnimTile(this.label, this.bg, this.fg, this.animate);

  @override
  Widget build(BuildContext context) {
    return animate(
      Container(
        width: 90, height: 80,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12))),
      ),
    );
  }
}
