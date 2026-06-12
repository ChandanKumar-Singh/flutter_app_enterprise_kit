import 'package:flutter/material.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';

// ─── Card Variants ─────────────────────────────────────────────────────────────
// 1. basic       2. elevated    3. outlined     4. filled      5. media
// 6. stat        7. list        8. profile      9. gradient   10. action
// 11. banner    12. horizontal

enum AppCardVariant {
  basic, elevated, outlined, filled, media, stat, list,
  profile, gradient, action, banner, horizontal,
}

class AppCard extends StatelessWidget {
  final AppCardVariant variant;
  final Widget? child;
  final String? title;
  final String? subtitle;
  final String? body;
  final Widget? leading;
  final Widget? trailing;
  final Widget? media;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final double? elevation;
  final List<Color>? gradientColors;
  final List<Widget>? actions;
  final String? badge;
  final Color? badgeColor;

  const AppCard({
    super.key,
    this.variant = AppCardVariant.basic,
    this.child,
    this.title,
    this.subtitle,
    this.body,
    this.leading,
    this.trailing,
    this.media,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.elevation,
    this.gradientColors,
    this.actions,
    this.badge,
    this.badgeColor,
  });

  // ── Factory constructors ───────────────────────────────────────────────────

  factory AppCard.basic({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? backgroundColor,
  }) => AppCard(variant: AppCardVariant.basic, child: child,
      onTap: onTap, padding: padding, margin: margin,
      backgroundColor: backgroundColor);

  factory AppCard.elevated({
    required Widget child,
    VoidCallback? onTap,
    double? elevation,
    EdgeInsetsGeometry? padding,
  }) => AppCard(variant: AppCardVariant.elevated, child: child,
      onTap: onTap, elevation: elevation, padding: padding);

  factory AppCard.outlined({
    required Widget child,
    VoidCallback? onTap,
    Color? borderColor,
    EdgeInsetsGeometry? padding,
  }) => AppCard(variant: AppCardVariant.outlined, child: child,
      onTap: onTap, borderColor: borderColor, padding: padding);

  factory AppCard.filled({
    required Widget child,
    VoidCallback? onTap,
    Color? backgroundColor,
    EdgeInsetsGeometry? padding,
  }) => AppCard(variant: AppCardVariant.filled, child: child,
      onTap: onTap, backgroundColor: backgroundColor, padding: padding);

  factory AppCard.media({
    required Widget media,
    String? title,
    String? subtitle,
    String? body,
    VoidCallback? onTap,
    List<Widget>? actions,
    String? badge,
  }) => AppCard(variant: AppCardVariant.media, media: media,
      title: title, subtitle: subtitle, body: body,
      onTap: onTap, actions: actions, badge: badge);

  factory AppCard.stat({
    required String title,
    required String value,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    Color? accentColor,
    VoidCallback? onTap,
  }) => AppCard(variant: AppCardVariant.stat, title: title,
      body: value, subtitle: subtitle, leading: leading,
      trailing: trailing, backgroundColor: accentColor, onTap: onTap);

  factory AppCard.list({
    required String title,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) => AppCard(variant: AppCardVariant.list, title: title,
      subtitle: subtitle, leading: leading, trailing: trailing,
      onTap: onTap, onLongPress: onLongPress);

  factory AppCard.profile({
    required String name,
    String? role,
    Widget? avatar,
    Widget? trailing,
    List<Widget>? actions,
    VoidCallback? onTap,
  }) => AppCard(variant: AppCardVariant.profile, title: name,
      subtitle: role, leading: avatar, trailing: trailing,
      actions: actions, onTap: onTap);

  factory AppCard.gradient({
    required String title,
    String? subtitle,
    Widget? child,
    required List<Color> gradientColors,
    Widget? trailing,
    VoidCallback? onTap,
  }) => AppCard(variant: AppCardVariant.gradient, title: title,
      subtitle: subtitle, child: child, gradientColors: gradientColors,
      trailing: trailing, onTap: onTap);

  factory AppCard.action({
    required String title,
    String? subtitle,
    required Widget leading,
    required VoidCallback onTap,
    String? badge,
    Color? badgeColor,
  }) => AppCard(variant: AppCardVariant.action, title: title,
      subtitle: subtitle, leading: leading, onTap: onTap,
      badge: badge, badgeColor: badgeColor);

  factory AppCard.banner({
    required String title,
    required String message,
    required IconData icon,
    Color? backgroundColor,
    Color? foregroundColor,
    Widget? action,
    VoidCallback? onDismiss,
  }) => AppCard(variant: AppCardVariant.banner, title: title,
      body: message, leading: Icon(icon, color: foregroundColor),
      trailing: action, backgroundColor: backgroundColor, onTap: null);

  factory AppCard.horizontal({
    required Widget leading,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    EdgeInsetsGeometry? padding,
  }) => AppCard(variant: AppCardVariant.horizontal, leading: leading,
      title: title, subtitle: subtitle, trailing: trailing,
      onTap: onTap, padding: padding);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final br = borderRadius ?? BorderRadius.circular(AppSpacing.radiusMd);
    final pad = padding ?? const EdgeInsets.all(AppSpacing.md);

    Widget content = _buildContent(context, colors, br, pad);

    if (variant == AppCardVariant.gradient) {
      content = _wrapGradient(content, br);
    }

    if (onTap != null || onLongPress != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: br,
          onTap: onTap,
          onLongPress: onLongPress,
          child: content,
        ),
      );
    }

    Widget card = switch (variant) {
      AppCardVariant.elevated => Card(
          elevation: elevation ?? 4,
          color: backgroundColor ?? colors.surface,
          shape: RoundedRectangleBorder(borderRadius: br),
          margin: margin ?? EdgeInsets.zero,
          child: ClipRRect(borderRadius: br, child: content),
        ),
      AppCardVariant.outlined => Card(
          elevation: 0,
          color: backgroundColor ?? colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: br,
            side: BorderSide(color: borderColor ?? colors.outline, width: 1),
          ),
          margin: margin ?? EdgeInsets.zero,
          child: ClipRRect(borderRadius: br, child: content),
        ),
      AppCardVariant.filled => Card(
          elevation: 0,
          color: backgroundColor ?? colors.surfaceVariant,
          shape: RoundedRectangleBorder(borderRadius: br),
          margin: margin ?? EdgeInsets.zero,
          child: ClipRRect(borderRadius: br, child: content),
        ),
      AppCardVariant.gradient => Card(
          elevation: elevation ?? 0,
          color: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: br),
          margin: margin ?? EdgeInsets.zero,
          child: ClipRRect(borderRadius: br, child: content),
        ),
      _ => Card(
          elevation: elevation ?? (variant == AppCardVariant.basic ? 0 : 1),
          color: backgroundColor ?? colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: br,
            side: variant == AppCardVariant.basic
                ? BorderSide(color: colors.outlineVariant)
                : BorderSide.none,
          ),
          margin: margin ?? EdgeInsets.zero,
          child: ClipRRect(borderRadius: br, child: content),
        ),
    };

    // Badge overlay
    if (badge != null) {
      card = Stack(
        clipBehavior: Clip.none,
        children: [
          card,
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor ?? colors.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(badge!, style: TextStyle(
                color: colors.onError, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    }

    return card;
  }

  Widget _buildContent(BuildContext context, ColorScheme colors,
      BorderRadius br, EdgeInsetsGeometry pad) {
    return switch (variant) {
      AppCardVariant.media => _buildMedia(context, colors, pad),
      AppCardVariant.stat  => _buildStat(context, colors, pad),
      AppCardVariant.list  => _buildList(context, colors),
      AppCardVariant.profile => _buildProfile(context, colors, pad),
      AppCardVariant.gradient => _buildGradient(context, pad),
      AppCardVariant.action => _buildAction(context, colors, pad),
      AppCardVariant.banner => _buildBanner(context, colors, pad),
      AppCardVariant.horizontal => _buildHorizontal(context, colors, pad),
      _ => Padding(padding: pad, child: _buildDefaultContent(context)),
    };
  }

  Widget _buildDefaultContent(BuildContext context) {
    if (child != null) return child!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null || title != null || trailing != null)
          Row(children: [
            if (leading != null) ...[leading!, const SizedBox(width: AppSpacing.sm)],
            if (title != null) Expanded(child: Text(title!, style: theme.textTheme.titleMedium)),
            if (trailing != null) trailing!,
          ]),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant)),
        ],
        if (body != null) ...[
          const SizedBox(height: 8),
          Text(body!, style: theme.textTheme.bodyMedium),
        ],
        if (actions != null) ...[
          const SizedBox(height: AppSpacing.md),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: actions!),
        ],
      ],
    );
  }

  Widget _buildMedia(BuildContext context, ColorScheme colors, EdgeInsetsGeometry pad) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (media != null)
          AspectRatio(aspectRatio: 16 / 9, child: media!),
        Padding(
          padding: pad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null) Text(title!, style: theme.textTheme.titleMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant)),
              ],
              if (body != null) ...[
                const SizedBox(height: 8),
                Text(body!, style: theme.textTheme.bodyMedium),
              ],
              if (actions != null) ...[
                const SizedBox(height: AppSpacing.md),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: actions!),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStat(BuildContext context, ColorScheme colors, EdgeInsetsGeometry pad) {
    final theme = Theme.of(context);
    return Padding(
      padding: pad,
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: AppSpacing.md)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title ?? '', style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant)),
                Text(body ?? '', style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold)),
                if (subtitle != null) Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, ColorScheme colors) {
    return ListTile(
      leading: leading,
      title: title != null ? Text(title!) : null,
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing ?? (onTap != null
          ? Icon(Icons.chevron_right, color: colors.onSurfaceVariant) : null),
      onTap: onTap,
    );
  }

  Widget _buildProfile(BuildContext context, ColorScheme colors, EdgeInsetsGeometry pad) {
    final theme = Theme.of(context);
    return Padding(
      padding: pad,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (leading != null) ...[
                CircleAvatar(radius: 24, child: leading),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title ?? '', style: theme.textTheme.titleSmall),
                  if (subtitle != null) Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant)),
                ],
              )),
              if (trailing != null) trailing!,
            ],
          ),
          if (actions != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(children: actions!),
          ],
        ],
      ),
    );
  }

  Widget _buildGradient(BuildContext context, EdgeInsetsGeometry pad) {
    final theme = Theme.of(context);
    return Container(
      padding: pad,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors ?? [Colors.blue, Colors.purple],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || trailing != null)
            Row(children: [
              if (title != null) Expanded(child: Text(title!,
                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.white))),
              if (trailing != null) trailing!,
            ]),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white70)),
          ],
          if (child != null) ...[
            const SizedBox(height: AppSpacing.md),
            child!,
          ],
        ],
      ),
    );
  }

  Widget _buildAction(BuildContext context, ColorScheme colors, EdgeInsetsGeometry pad) {
    final theme = Theme.of(context);
    return Padding(
      padding: pad,
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Center(child: leading ?? const SizedBox()),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title ?? '', style: theme.textTheme.titleSmall),
              if (subtitle != null) Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant)),
            ],
          )),
          Icon(Icons.arrow_forward_ios, size: 16, color: colors.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _buildBanner(BuildContext context, ColorScheme colors, EdgeInsetsGeometry pad) {
    final theme = Theme.of(context);
    final bg = backgroundColor ?? colors.primaryContainer;
    final fg = colors.onPrimaryContainer;
    return Container(
      padding: pad,
      color: bg,
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: AppSpacing.sm)],
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title ?? '', style: theme.textTheme.titleSmall?.copyWith(color: fg)),
              if (body != null) Text(body!, style: theme.textTheme.bodySmall?.copyWith(color: fg)),
            ],
          )),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }

  Widget _buildHorizontal(BuildContext context, ColorScheme colors, EdgeInsetsGeometry pad) {
    final theme = Theme.of(context);
    return Padding(
      padding: pad,
      child: Row(
        children: [
          if (leading != null)
            SizedBox(width: 80, height: 80,
                child: ClipRRect(borderRadius: BorderRadius.circular(8), child: leading)),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title ?? '', style: theme.textTheme.titleSmall),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant)),
              ],
            ],
          )),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }

  Widget _wrapGradient(Widget child, BorderRadius br) => child;
}
