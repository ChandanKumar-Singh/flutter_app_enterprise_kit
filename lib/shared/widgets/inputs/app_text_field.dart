import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

class AppTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helper;
  final String? error;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool readOnly;
  final bool autofocus;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onTap;
  final Widget? prefix;
  final Widget? suffix;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? prefixText;
  final String? suffixText;
  final bool showPasswordToggle;
  final TextCapitalization textCapitalization;
  final bool showCharacterCount;
  final String? initialValue;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? style;
  final bool filled;
  final Color? fillColor;
  final AutovalidateMode? autovalidateMode;
  final bool unfocusOnTapOutside;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.readOnly = false,
    this.autofocus = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.prefix,
    this.suffix,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixText,
    this.suffixText,
    this.showPasswordToggle = false,
    this.textCapitalization = TextCapitalization.none,
    this.showCharacterCount = false,
    this.initialValue,
    this.contentPadding,
    this.style,
    this.filled = true,
    this.fillColor,
    this.autovalidateMode,
    this.unfocusOnTapOutside = true,
  });

  // ── Factories ──────────────────────────────────────────────────────────────

  factory AppTextField.email({
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    TextInputAction? textInputAction,
    bool autofocus = false,
  }) => AppTextField(
    label: 'Email',
    hint: 'Enter your email',
    controller: controller,
    keyboardType: TextInputType.emailAddress,
    textInputAction: textInputAction,
    prefixIcon: const Icon(Iconsax.sms),
    validator: validator,
    onChanged: onChanged,
    autofocus: autofocus,
    textCapitalization: TextCapitalization.none,
  );

  factory AppTextField.password({
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    String label = 'Password',
  }) => AppTextField(
    label: label,
    hint: 'Enter your password',
    controller: controller,
    obscureText: true,
    showPasswordToggle: true,
    prefixIcon: const Icon(Iconsax.lock),
    validator: validator,
    onChanged: onChanged,
  );

  factory AppTextField.phone({
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) => AppTextField(
    label: 'Phone Number',
    hint: '+1 (555) 000-0000',
    controller: controller,
    keyboardType: TextInputType.phone,
    prefixIcon: const Icon(Iconsax.call),
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    validator: validator,
    onChanged: onChanged,
  );

  factory AppTextField.search({
    TextEditingController? controller,
    FocusNode? focusNode,
    String? hint,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
    VoidCallback? onClear,
  }) => AppTextField(
    hint: hint ?? 'Search...',
    controller: controller,
    focusNode: focusNode,
    keyboardType: TextInputType.text,
    textInputAction: TextInputAction.search,
    prefixIcon: const Icon(Iconsax.search_normal),
    onChanged: onChanged,
    onSubmitted: onSubmitted,
  );

  factory AppTextField.multiline({
    TextEditingController? controller,
    String? label,
    String? hint,
    int maxLines = 4,
    int? maxLength,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool showCharacterCount = true,
  }) => AppTextField(
    label: label,
    hint: hint,
    controller: controller,
    maxLines: maxLines,
    maxLength: maxLength,
    keyboardType: TextInputType.multiline,
    textInputAction: TextInputAction.newline,
    validator: validator,
    onChanged: onChanged,
    showCharacterCount: showCharacterCount,
  );

  factory AppTextField.number({
    TextEditingController? controller,
    String? label,
    String? hint,
    bool allowDecimals = false,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    Widget? suffixIcon,
  }) => AppTextField(
    label: label,
    hint: hint,
    controller: controller,
    keyboardType: allowDecimals
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.number,
    inputFormatters: [
      allowDecimals
          ? FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
          : FilteringTextInputFormatter.digitsOnly,
    ],
    validator: validator,
    onChanged: onChanged,
    suffixIcon: suffixIcon,
  );

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscure;
  late final TextEditingController _ctrl;
  bool _isControllerOwned = false;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
    if (widget.controller == null) {
      _ctrl = TextEditingController(text: widget.initialValue);
      _isControllerOwned = true;
    } else {
      _ctrl = widget.controller!;
    }
  }

  @override
  void dispose() {
    if (_isControllerOwned) _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget? effectiveSuffix = widget.suffixIcon;

    if (widget.showPasswordToggle) {
      effectiveSuffix = IconButton(
        icon: Icon(_obscure ? Iconsax.eye : Iconsax.eye_slash),
        onPressed: () => setState(() => _obscure = !_obscure),
      );
    }

    return TextFormField(
      controller: _ctrl,
      focusNode: widget.focusNode,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: _obscure,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      maxLines: _obscure ? 1 : widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.showCharacterCount ? widget.maxLength : null,
      inputFormatters: widget.inputFormatters,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      onTapOutside: widget.unfocusOnTapOutside
          ? (event) => FocusScope.of(context).unfocus()
          : null,
      textCapitalization: widget.textCapitalization,
      style: widget.style,
      autovalidateMode: widget.autovalidateMode,
      buildCounter: (!widget.showCharacterCount && widget.maxLength != null)
          ? (_, {required currentLength, required isFocused, required maxLength}) =>
              const SizedBox.shrink()
          : null,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.helper,
        errorText: widget.error,
        prefix: widget.prefix,
        suffix: widget.suffix,
        prefixIcon: widget.prefixIcon,
        suffixIcon: effectiveSuffix,
        prefixText: widget.prefixText,
        suffixText: widget.suffixText,
        contentPadding: widget.contentPadding,
        filled: widget.filled,
        fillColor: widget.fillColor,
      ),
    );
  }
}
