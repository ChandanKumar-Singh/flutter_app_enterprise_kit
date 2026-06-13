import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

/// A customizable back button widget that can be placed anywhere in the layout.
/// Supports custom callbacks, customized icons/tooltips, and optional PopScope integration
/// to intercept system gestures and physical back buttons.
class AppBackButton extends StatelessWidget {
  /// Custom callback when the back button is pressed.
  /// If null, defaults to Navigator.maybePop(context).
  final VoidCallback? onPressed;

  /// Optional custom icon to replace the default back icon (Iconsax.arrow_left).
  final IconData? icon;

  /// Optional custom tooltip message. Defaults to 'Back'.
  final String? tooltip;

  /// Whether to integrate PopScope to intercept system back button/gestures.
  final bool enablePopScope;

  /// Control if the route can pop when PopScope is enabled.
  final bool canPop;

  /// Optional callback triggered when a pop is attempted and denied.
  final VoidCallback? onPopDenied;

  /// Optional callback invoked when a pop attempt is processed (e.g. system gestures).
  final void Function(bool didPop)? onPopInvoked;

  const AppBackButton({
    super.key,
    this.onPressed,
    this.icon,
    this.tooltip = 'Back',
    this.enablePopScope = false,
    this.canPop = true,
    this.onPopDenied,
    this.onPopInvoked,
  });

  @override
  Widget build(BuildContext context) {
    final Widget button = IconButton(
      icon: Icon(icon ?? Iconsax.arrow_left),
      tooltip: tooltip,
      onPressed: () {
        if (onPressed != null) {
          onPressed!();
        } else {
          final navigator = Navigator.of(context);
          if (!enablePopScope || canPop) {
            navigator.maybePop();
          } else {
            onPopDenied?.call();
          }
        }
      },
    );

    if (enablePopScope) {
      return PopScope(
        canPop: canPop,
        onPopInvokedWithResult: (didPop, result) {
          onPopInvoked?.call(didPop);
          if (!didPop && !canPop) {
            onPopDenied?.call();
          }
        },
        child: button,
      );
    }

    return button;
  }
}
