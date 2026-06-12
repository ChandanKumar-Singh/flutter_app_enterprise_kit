import 'package:flutter/material.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppButton — All button variants in one configurable widget
// ─────────────────────────────────────────────────────────────────────────────

enum AppButtonVariant {
  filled,
  outlined,
  text,
  elevated,
  tonal,
  destructive,
  ghost,
  link,
  icon,
  fab,
  extendedFab,
}

enum AppButtonSize { xs, sm, md, lg, xl }

class AppButton extends StatelessWidget {
  final String? label;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final Widget? icon;
  final Widget? trailingIcon;
  final bool isLoading;
  final bool isDisabled;
  final bool isFullWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final String? tooltip;
  final double? elevation;

  const AppButton({
    super.key,
    this.label,
    this.onPressed,
    this.onLongPress,
    this.variant = AppButtonVariant.filled,
    this.size = AppButtonSize.md,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isDisabled = false,
    this.isFullWidth = true,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.padding,
    this.tooltip,
    this.elevation,
  });

  // ── Factory constructors ───────────────────────────────────────────────────

  factory AppButton.filled({
    required String label,
    required VoidCallback? onPressed,
    Widget? icon,
    AppButtonSize size = AppButtonSize.md,
    bool isLoading = false,
    bool isFullWidth = true,
    Color? backgroundColor,
    Color? foregroundColor,
  }) => AppButton(
    label: label, onPressed: onPressed, icon: icon,
    variant: AppButtonVariant.filled, size: size,
    isLoading: isLoading, isFullWidth: isFullWidth,
    backgroundColor: backgroundColor, foregroundColor: foregroundColor,
  );

  factory AppButton.outlined({
    required String label,
    required VoidCallback? onPressed,
    Widget? icon,
    AppButtonSize size = AppButtonSize.md,
    bool isLoading = false,
    bool isFullWidth = true,
  }) => AppButton(
    label: label, onPressed: onPressed, icon: icon,
    variant: AppButtonVariant.outlined, size: size,
    isLoading: isLoading, isFullWidth: isFullWidth,
  );

  factory AppButton.text({
    required String label,
    required VoidCallback? onPressed,
    Widget? icon,
    AppButtonSize size = AppButtonSize.md,
    bool isFullWidth = false,
  }) => AppButton(
    label: label, onPressed: onPressed, icon: icon,
    variant: AppButtonVariant.text, size: size, isFullWidth: isFullWidth,
  );

  factory AppButton.tonal({
    required String label,
    required VoidCallback? onPressed,
    Widget? icon,
    AppButtonSize size = AppButtonSize.md,
    bool isLoading = false,
    bool isFullWidth = true,
  }) => AppButton(
    label: label, onPressed: onPressed, icon: icon,
    variant: AppButtonVariant.tonal, size: size,
    isLoading: isLoading, isFullWidth: isFullWidth,
  );

  factory AppButton.destructive({
    required String label,
    required VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.md,
    bool isLoading = false,
    bool isFullWidth = true,
  }) => AppButton(
    label: label, onPressed: onPressed,
    variant: AppButtonVariant.destructive, size: size,
    isLoading: isLoading, isFullWidth: isFullWidth,
  );

  factory AppButton.icon({
    required Widget icon,
    required VoidCallback? onPressed,
    String? tooltip,
    AppButtonSize size = AppButtonSize.md,
    Color? backgroundColor,
    Color? foregroundColor,
  }) => AppButton(
    icon: icon, onPressed: onPressed, tooltip: tooltip,
    variant: AppButtonVariant.icon, size: size,
    backgroundColor: backgroundColor, foregroundColor: foregroundColor,
    isFullWidth: false,
  );

  factory AppButton.fab({
    required Widget icon,
    String? label,
    required VoidCallback? onPressed,
    Color? backgroundColor,
  }) => AppButton(
    icon: icon, label: label, onPressed: onPressed,
    variant: label != null ? AppButtonVariant.extendedFab : AppButtonVariant.fab,
    isFullWidth: false, backgroundColor: backgroundColor,
  );

  // ── Sizes ──────────────────────────────────────────────────────────────────
  _ButtonDimensions get _dims => switch (size) {
    AppButtonSize.xs => const _ButtonDimensions(height: 28, hPad: 10, vPad: 4,  fontSize: 11, iconSize: 14, loaderSize: 12),
    AppButtonSize.sm => const _ButtonDimensions(height: 36, hPad: 14, vPad: 6,  fontSize: 13, iconSize: 16, loaderSize: 14),
    AppButtonSize.md => const _ButtonDimensions(height: 48, hPad: 20, vPad: 10, fontSize: 14, iconSize: 18, loaderSize: 16),
    AppButtonSize.lg => const _ButtonDimensions(height: 56, hPad: 24, vPad: 14, fontSize: 16, iconSize: 20, loaderSize: 18),
    AppButtonSize.xl => const _ButtonDimensions(height: 64, hPad: 32, vPad: 18, fontSize: 18, iconSize: 24, loaderSize: 20),
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isEnabled = onPressed != null && !isLoading && !isDisabled;
    final d = _dims;

    final br = borderRadius ?? BorderRadius.circular(AppSpacing.radiusMd);
    final pad = padding ?? EdgeInsets.symmetric(horizontal: d.hPad, vertical: d.vPad);

    Widget child = _buildChild(context, d);

    Widget button = switch (variant) {
      AppButtonVariant.filled => ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          onLongPress: isEnabled ? onLongPress : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? colors.primary,
            foregroundColor: foregroundColor ?? colors.onPrimary,
            elevation: elevation ?? 0,
            padding: pad,
            minimumSize: Size(0, d.height),
            shape: RoundedRectangleBorder(borderRadius: br),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: child,
        ),

      AppButtonVariant.outlined => OutlinedButton(
          onPressed: isEnabled ? onPressed : null,
          onLongPress: isEnabled ? onLongPress : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: foregroundColor ?? colors.primary,
            side: BorderSide(color: isEnabled ? colors.primary : colors.outline, width: 1.5),
            padding: pad,
            minimumSize: Size(0, d.height),
            shape: RoundedRectangleBorder(borderRadius: br),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: child,
        ),

      AppButtonVariant.text => TextButton(
          onPressed: isEnabled ? onPressed : null,
          onLongPress: isEnabled ? onLongPress : null,
          style: TextButton.styleFrom(
            foregroundColor: foregroundColor ?? colors.primary,
            padding: pad,
            minimumSize: Size(0, d.height),
            shape: RoundedRectangleBorder(borderRadius: br),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: child,
        ),

      AppButtonVariant.elevated => ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? colors.surface,
            foregroundColor: foregroundColor ?? colors.primary,
            elevation: elevation ?? 4,
            padding: pad,
            minimumSize: Size(0, d.height),
            shape: RoundedRectangleBorder(borderRadius: br),
          ),
          child: child,
        ),

      AppButtonVariant.tonal => FilledButton.tonal(
          onPressed: isEnabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: backgroundColor ?? colors.secondaryContainer,
            foregroundColor: foregroundColor ?? colors.onSecondaryContainer,
            padding: pad,
            minimumSize: Size(0, d.height),
            shape: RoundedRectangleBorder(borderRadius: br),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: child,
        ),

      AppButtonVariant.destructive => ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? colors.error,
            foregroundColor: foregroundColor ?? colors.onError,
            elevation: 0,
            padding: pad,
            minimumSize: Size(0, d.height),
            shape: RoundedRectangleBorder(borderRadius: br),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: child,
        ),

      AppButtonVariant.ghost => TextButton(
          onPressed: isEnabled ? onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: foregroundColor ?? colors.onSurface,
            overlayColor: colors.onSurface.withOpacity(0.06),
            padding: pad,
            minimumSize: Size(0, d.height),
            shape: RoundedRectangleBorder(borderRadius: br),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: child,
        ),

      AppButtonVariant.link => TextButton(
          onPressed: isEnabled ? onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: foregroundColor ?? colors.primary,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: TextStyle(
              fontSize: d.fontSize,
              decoration: TextDecoration.underline,
              decorationColor: colors.primary,
            ),
          ),
          child: child,
        ),

      AppButtonVariant.icon => IconButton(
          onPressed: isEnabled ? onPressed : null,
          onLongPress: isEnabled ? onLongPress : null,
          tooltip: tooltip,
          icon: _buildLoader(context, d) ?? icon ?? const SizedBox(),
          color: foregroundColor ?? colors.onSurface,
          style: IconButton.styleFrom(
            backgroundColor: backgroundColor,
            minimumSize: Size(d.height, d.height),
            padding: pad,
            shape: RoundedRectangleBorder(borderRadius: br),
          ),
        ),

      AppButtonVariant.fab => FloatingActionButton(
          onPressed: isEnabled ? onPressed : null,
          tooltip: tooltip,
          backgroundColor: backgroundColor ?? colors.primaryContainer,
          foregroundColor: foregroundColor ?? colors.onPrimaryContainer,
          elevation: elevation ?? 4,
          child: _buildLoader(context, d) ?? icon ?? const SizedBox(),
        ),

      AppButtonVariant.extendedFab => FloatingActionButton.extended(
          onPressed: isEnabled ? onPressed : null,
          backgroundColor: backgroundColor ?? colors.primaryContainer,
          foregroundColor: foregroundColor ?? colors.onPrimaryContainer,
          elevation: elevation ?? 4,
          icon: icon,
          label: Text(label ?? '', style: TextStyle(fontSize: d.fontSize, fontWeight: FontWeight.w600)),
        ),
    };

    if (isFullWidth && variant != AppButtonVariant.icon &&
        variant != AppButtonVariant.fab && variant != AppButtonVariant.extendedFab) {
      button = SizedBox(width: double.infinity, child: button);
    }

    if (tooltip != null && variant != AppButtonVariant.icon) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }

  Widget _buildChild(BuildContext context, _ButtonDimensions d) {
    final loader = _buildLoader(context, d);
    if (loader != null) return loader;

    if (icon == null && trailingIcon == null) {
      return Text(label ?? '', style: TextStyle(fontSize: d.fontSize, fontWeight: FontWeight.w600));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          SizedBox(width: d.iconSize, height: d.iconSize, child: icon),
          if (label != null) const SizedBox(width: 8),
        ],
        if (label != null)
          Text(label!, style: TextStyle(fontSize: d.fontSize, fontWeight: FontWeight.w600)),
        if (trailingIcon != null) ...[
          const SizedBox(width: 8),
          SizedBox(width: d.iconSize, height: d.iconSize, child: trailingIcon),
        ],
      ],
    );
  }

  Widget? _buildLoader(BuildContext context, _ButtonDimensions d) {
    if (!isLoading) return null;
    final color = switch (variant) {
      AppButtonVariant.filled || AppButtonVariant.destructive =>
          Theme.of(context).colorScheme.onPrimary,
      _ => Theme.of(context).colorScheme.primary,
    };
    return SizedBox(
      width: d.loaderSize,
      height: d.loaderSize,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );
  }
}

class _ButtonDimensions {
  final double height;
  final double hPad;
  final double vPad;
  final double fontSize;
  final double iconSize;
  final double loaderSize;
  const _ButtonDimensions({
    required this.height,
    required this.hPad,
    required this.vPad,
    required this.fontSize,
    required this.iconSize,
    required this.loaderSize,
  });
}
