import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ─── App Rating ───────────────────────────────────────────────────────────────
class AppRating extends StatefulWidget {
  final double value;
  final int count;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool readOnly;
  final bool halfAllowed;
  final bool animated;
  final void Function(double)? onChanged;
  final IconData activeIcon;
  final IconData halfIcon;
  final IconData inactiveIcon;
  final MainAxisAlignment alignment;
  final Widget Function(BuildContext, int)? itemBuilder;
  final double spacing;

  const AppRating({
    super.key,
    this.value = 0,
    this.count = 5,
    this.size = 28,
    this.activeColor,
    this.inactiveColor,
    this.readOnly = false,
    this.halfAllowed = true,
    this.animated = true,
    this.onChanged,
    this.activeIcon = Icons.star_rounded,
    this.halfIcon = Icons.star_half_rounded,
    this.inactiveIcon = Icons.star_outline_rounded,
    this.alignment = MainAxisAlignment.start,
    this.itemBuilder,
    this.spacing = 4,
  });

  @override
  State<AppRating> createState() => _AppRatingState();
}

class _AppRatingState extends State<AppRating> {
  late double _hoverValue;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _hoverValue = widget.value;
  }

  double get _displayValue => _isHovering ? _hoverValue : widget.value;

  void _onTap(int index, double fraction) {
    if (widget.readOnly) return;
    double newValue;
    if (widget.halfAllowed && fraction < 0.6) {
      newValue = index + 0.5;
    } else {
      newValue = index + 1.0;
    }
    widget.onChanged?.call(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.activeColor ?? const Color(0xFFFBBF24);
    final inactive = widget.inactiveColor ??
        Theme.of(context).colorScheme.onSurface.withOpacity(0.2);

    return Row(
      mainAxisAlignment: widget.alignment,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.count, (i) {
        final starValue = i + 1;
        final isFull = _displayValue >= starValue;
        final isHalf =
            widget.halfAllowed && _displayValue >= i + 0.5 && _displayValue < starValue;

        IconData icon;
        Color color;
        if (isFull) {
          icon = widget.activeIcon;
          color = active;
        } else if (isHalf) {
          icon = widget.halfIcon;
          color = active;
        } else {
          icon = widget.inactiveIcon;
          color = inactive;
        }

        Widget star = widget.itemBuilder?.call(context, i) ??
            Icon(icon, size: widget.size, color: color);

        if (widget.animated && isFull) {
          star = star
              .animate(key: ValueKey('star_${i}_${isFull}_${isHalf}'))
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0), duration: 200.ms, curve: Curves.elasticOut);
        }

        if (!widget.readOnly) {
          star = GestureDetector(
            onTapDown: (d) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final localPos = box.globalToLocal(d.globalPosition);
              final starWidth = box.size.width / widget.count;
              final starOffset = localPos.dx - i * starWidth;
              _onTap(i, starOffset / starWidth);
            },
            onHorizontalDragUpdate: (d) {
              if (!_isHovering) setState(() => _isHovering = true);
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final localPos = box.globalToLocal(d.globalPosition);
              final starWidth = box.size.width / widget.count;
              final idx = (localPos.dx / starWidth).floor().clamp(0, widget.count - 1);
              final frac = (localPos.dx / starWidth) - idx;
              setState(() {
                _hoverValue = widget.halfAllowed && frac < 0.6
                    ? idx + 0.5
                    : idx + 1.0;
              });
            },
            onHorizontalDragEnd: (_) {
              widget.onChanged?.call(_hoverValue);
              setState(() => _isHovering = false);
            },
            child: star,
          );
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
          child: star,
        );
      }),
    );
  }
}

// ─── Compact Rating Display ───────────────────────────────────────────────────
class AppRatingDisplay extends StatelessWidget {
  final double rating;
  final int? totalReviews;
  final double size;
  final bool showLabel;

  const AppRatingDisplay({
    super.key,
    required this.rating,
    this.totalReviews,
    this.size = 16,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, color: const Color(0xFFFBBF24), size: size),
        const SizedBox(width: 4),
        if (showLabel)
          Text(
            rating.toStringAsFixed(1),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        if (totalReviews != null) ...[
          const SizedBox(width: 4),
          Text(
            '($totalReviews)',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}
