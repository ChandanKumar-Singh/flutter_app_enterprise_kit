// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';

// ─── Tag Variant ──────────────────────────────────────────────────────────────
enum AppTagVariant { filled, outlined, soft, text }
enum AppTagSize { xs, sm, md, lg }
enum AppTagStatus { default_, success, warning, error, info, pending }

// ─── App Tag ──────────────────────────────────────────────────────────────────
class AppTag extends StatelessWidget {
  final String label;
  final AppTagVariant variant;
  final AppTagSize size;
  final AppTagStatus status;
  final Color? color;
  final Widget? leading;
  final Widget? trailing;
  final bool closeable;
  final bool toggleable;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onClose;
  final ValueChanged<bool>? onToggle;
  final IconData? leadingIcon;

  const AppTag({
    super.key,
    required this.label,
    this.variant = AppTagVariant.soft,
    this.size = AppTagSize.sm,
    this.status = AppTagStatus.default_,
    this.color,
    this.leading,
    this.trailing,
    this.closeable = false,
    this.toggleable = false,
    this.selected = false,
    this.onTap,
    this.onClose,
    this.onToggle,
    this.leadingIcon,
  });

  factory AppTag.success(String label) =>
      AppTag(label: label, status: AppTagStatus.success);

  factory AppTag.error(String label) =>
      AppTag(label: label, status: AppTagStatus.error);

  factory AppTag.warning(String label) =>
      AppTag(label: label, status: AppTagStatus.warning);

  factory AppTag.info(String label) =>
      AppTag(label: label, status: AppTagStatus.info);

  factory AppTag.pending(String label) =>
      AppTag(label: label, status: AppTagStatus.pending);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final cfg = _tagConfig(status, color, cs);
    final isToggled = toggleable && selected;

    // Size dims
    final double fontSize = switch (size) {
      AppTagSize.xs => 10,
      AppTagSize.sm => 11,
      AppTagSize.md => 13,
      AppTagSize.lg => 15,
    };
    final EdgeInsets innerPad = switch (size) {
      AppTagSize.xs => const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      AppTagSize.sm => const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      AppTagSize.md => const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      AppTagSize.lg => const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    };
    final double iconSize = switch (size) {
      AppTagSize.xs => 10,
      AppTagSize.sm => 12,
      AppTagSize.md => 14,
      AppTagSize.lg => 16,
    };

    // Colors based on variant
    Color bg, fg, border;
    switch (variant) {
      case AppTagVariant.filled:
        bg = isToggled ? cfg.color : cfg.color;
        fg = Colors.white;
        border = Colors.transparent;
        break;
      case AppTagVariant.outlined:
        bg = Colors.transparent;
        fg = cfg.color;
        border = cfg.color;
        break;
      case AppTagVariant.text:
        bg = Colors.transparent;
        fg = cfg.color;
        border = Colors.transparent;
        break;
      case AppTagVariant.soft:
        bg = isToggled ? cfg.color : cfg.color.withOpacity(0.12);
        fg = isToggled ? Colors.white : cfg.color;
        border = isToggled ? cfg.color : cfg.color.withOpacity(0.3);
        break;
    }

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[leading!, SizedBox(width: iconSize / 2)],
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: iconSize, color: fg),
          SizedBox(width: iconSize / 2),
        ],
        // Dot for status
        if (status != AppTagStatus.default_ && leading == null && leadingIcon == null) ...[
          Container(
            width: iconSize * 0.5,
            height: iconSize * 0.5,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: iconSize / 2),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
        if (trailing != null) ...[SizedBox(width: iconSize / 2), trailing!],
        if (closeable) ...[
          SizedBox(width: iconSize / 2),
          GestureDetector(
            onTap: onClose,
            child: Icon(Iconsax.close_circle, size: iconSize, color: fg.withOpacity(0.7)),
          ),
        ],
      ],
    );

    content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: innerPad,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: border, width: 1),
      ),
      child: content,
    );

    if (onTap != null || toggleable) {
      return GestureDetector(
        onTap: toggleable
            ? () => onToggle?.call(!selected)
            : onTap,
        child: content,
      );
    }

    return content;
  }
}

class _TagConfig {
  final Color color;
  const _TagConfig({required this.color});
}

_TagConfig _tagConfig(AppTagStatus status, Color? custom, ColorScheme cs) {
  if (custom != null) return _TagConfig(color: custom);
  return switch (status) {
    AppTagStatus.success => const _TagConfig(color: Color(0xFF16A34A)),
    AppTagStatus.warning => const _TagConfig(color: Color(0xFFD97706)),
    AppTagStatus.error => const _TagConfig(color: Color(0xFFDC2626)),
    AppTagStatus.info => const _TagConfig(color: Color(0xFF0284C7)),
    AppTagStatus.pending => const _TagConfig(color: Color(0xFF7C3AED)),
    _ => _TagConfig(color: cs.primary),
  };
}

// ─── Tag Group ────────────────────────────────────────────────────────────────
class AppTagGroup extends StatefulWidget {
  final List<String> tags;
  final List<String>? selected;
  final bool multiSelect;
  final void Function(List<String>)? onChanged;
  final AppTagVariant variant;
  final AppTagSize size;
  final WrapAlignment alignment;

  const AppTagGroup({
    super.key,
    required this.tags,
    this.selected,
    this.multiSelect = true,
    this.onChanged,
    this.variant = AppTagVariant.soft,
    this.size = AppTagSize.sm,
    this.alignment = WrapAlignment.start,
  });

  @override
  State<AppTagGroup> createState() => _AppTagGroupState();
}

class _AppTagGroupState extends State<AppTagGroup> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.of(widget.selected ?? []);
  }

  void _toggle(String tag) {
    setState(() {
      if (_selected.contains(tag)) {
        _selected.remove(tag);
      } else {
        if (!widget.multiSelect) _selected.clear();
        _selected.add(tag);
      }
    });
    widget.onChanged?.call(_selected.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: widget.alignment,
      children: widget.tags.map((tag) {
        return AppTag(
          label: tag,
          variant: widget.variant,
          size: widget.size,
          toggleable: true,
          selected: _selected.contains(tag),
          onToggle: (_) => _toggle(tag),
        );
      }).toList(),
    );
  }
}
