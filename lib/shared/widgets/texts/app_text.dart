import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// ─── Reusable text variants with consistent semantics ─────────────────────────

class AppText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;
  final bool selectable;

  const AppText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.selectable = false,
  });

  // ── Semantic factory constructors ──────────────────────────────────────────
  factory AppText.displayLarge(String text, {Color? color, TextAlign? textAlign}) =>
      _AppTextVariant(text, variant: _Variant.displayLarge, color: color, textAlign: textAlign);

  factory AppText.displayMedium(String text, {Color? color, TextAlign? textAlign}) =>
      _AppTextVariant(text, variant: _Variant.displayMedium, color: color, textAlign: textAlign);

  factory AppText.displaySmall(String text, {Color? color, TextAlign? textAlign}) =>
      _AppTextVariant(text, variant: _Variant.displaySmall, color: color, textAlign: textAlign);

  factory AppText.headlineLarge(String text, {Color? color, TextAlign? textAlign}) =>
      _AppTextVariant(text, variant: _Variant.headlineLarge, color: color, textAlign: textAlign);

  factory AppText.headlineMedium(String text, {Color? color, TextAlign? textAlign}) =>
      _AppTextVariant(text, variant: _Variant.headlineMedium, color: color, textAlign: textAlign);

  factory AppText.headlineSmall(String text, {Color? color, TextAlign? textAlign}) =>
      _AppTextVariant(text, variant: _Variant.headlineSmall, color: color, textAlign: textAlign);

  factory AppText.titleLarge(String text, {Color? color, TextAlign? textAlign}) =>
      _AppTextVariant(text, variant: _Variant.titleLarge, color: color, textAlign: textAlign);

  factory AppText.titleMedium(String text, {Color? color, TextAlign? textAlign}) =>
      _AppTextVariant(text, variant: _Variant.titleMedium, color: color, textAlign: textAlign);

  factory AppText.titleSmall(String text, {Color? color, TextAlign? textAlign}) =>
      _AppTextVariant(text, variant: _Variant.titleSmall, color: color, textAlign: textAlign);

  factory AppText.bodyLarge(String text, {Color? color, int? maxLines, TextAlign? textAlign}) =>
      _AppTextVariant(text, variant: _Variant.bodyLarge, color: color,
          maxLines: maxLines, textAlign: textAlign);

  factory AppText.bodyMedium(String text, {Color? color, int? maxLines, TextAlign? textAlign}) =>
      _AppTextVariant(text, variant: _Variant.bodyMedium, color: color,
          maxLines: maxLines, textAlign: textAlign);

  factory AppText.bodySmall(String text, {Color? color, int? maxLines, TextAlign? textAlign}) =>
      _AppTextVariant(text, variant: _Variant.bodySmall, color: color,
          maxLines: maxLines, textAlign: textAlign);

  factory AppText.labelLarge(String text, {Color? color}) =>
      _AppTextVariant(text, variant: _Variant.labelLarge, color: color);

  factory AppText.labelMedium(String text, {Color? color}) =>
      _AppTextVariant(text, variant: _Variant.labelMedium, color: color);

  factory AppText.labelSmall(String text, {Color? color}) =>
      _AppTextVariant(text, variant: _Variant.labelSmall, color: color);

  factory AppText.caption(String text, {Color? color}) =>
      _AppTextVariant(text, variant: _Variant.caption, color: color);

  factory AppText.overline(String text, {Color? color}) =>
      _AppTextVariant(text, variant: _Variant.overline, color: color);

  // ── Rich / Linked text ─────────────────────────────────────────────────────
  static Widget rich(
    List<InlineSpan> spans, {
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
  }) => Text.rich(
    TextSpan(children: spans),
    style: style,
    textAlign: textAlign,
    maxLines: maxLines,
    overflow: maxLines != null ? TextOverflow.ellipsis : null,
  );

  static InlineSpan span(
    String text, {
    TextStyle? style,
    VoidCallback? onTap,
  }) => TextSpan(
    text: text,
    style: style,
    recognizer: onTap != null ? (TapGestureRecognizer()..onTap = onTap) : null,
  );

  static InlineSpan linkSpan(
    String text, {
    required VoidCallback onTap,
    Color? color,
  }) => TextSpan(
    text: text,
    style: TextStyle(
      color: color ?? Colors.blue,
      decoration: TextDecoration.underline,
    ),
    recognizer: TapGestureRecognizer()..onTap = onTap,
  );

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = (style ?? const TextStyle()).copyWith(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );

    final widget = Text(
      text,
      style: effectiveStyle.copyWith(color: color),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow ?? (maxLines != null ? TextOverflow.ellipsis : null),
    );

    return selectable ? SelectableText(text, style: effectiveStyle) : widget;
  }
}

enum _Variant {
  displayLarge, displayMedium, displaySmall,
  headlineLarge, headlineMedium, headlineSmall,
  titleLarge, titleMedium, titleSmall,
  bodyLarge, bodyMedium, bodySmall,
  labelLarge, labelMedium, labelSmall,
  caption, overline,
}

class _AppTextVariant extends AppText {
  final _Variant _variant;
  const _AppTextVariant(super.text, {
    required this._variant,
    super.color,
    super.maxLines,
    super.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    TextStyle? base = switch (_variant) {
      _Variant.displayLarge  => textTheme.displayLarge,
      _Variant.displayMedium => textTheme.displayMedium,
      _Variant.displaySmall  => textTheme.displaySmall,
      _Variant.headlineLarge  => textTheme.headlineLarge,
      _Variant.headlineMedium => textTheme.headlineMedium,
      _Variant.headlineSmall  => textTheme.headlineSmall,
      _Variant.titleLarge   => textTheme.titleLarge,
      _Variant.titleMedium  => textTheme.titleMedium,
      _Variant.titleSmall   => textTheme.titleSmall,
      _Variant.bodyLarge   => textTheme.bodyLarge,
      _Variant.bodyMedium  => textTheme.bodyMedium,
      _Variant.bodySmall   => textTheme.bodySmall,
      _Variant.labelLarge  => textTheme.labelLarge,
      _Variant.labelMedium => textTheme.labelMedium,
      _Variant.labelSmall  => textTheme.labelSmall,
      _Variant.caption     => textTheme.bodySmall?.copyWith(fontSize: 11),
      _Variant.overline    => textTheme.labelSmall?.copyWith(
          letterSpacing: 1.2, fontWeight: FontWeight.w600),
    };

    if (color != null) base = base?.copyWith(color: color);

    return Text(
      text,
      style: base,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
    );
  }
}
