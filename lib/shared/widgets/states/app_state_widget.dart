import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';
import 'package:enterprise_kit/shared/widgets/buttons/app_button.dart';

enum AppStateType { loading, empty, error, noConnection, noResults, comingSoon, accessDenied }

class AppStateWidget extends StatelessWidget {
  final AppStateType type;
  final String? title;
  final String? message;
  final Widget? illustration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final bool showRetry;
  final VoidCallback? onRetry;

  const AppStateWidget({
    super.key,
    required this.type,
    this.title,
    this.message,
    this.illustration,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.showRetry = false,
    this.onRetry,
  });

  // ── Factories ──────────────────────────────────────────────────────────────
  factory AppStateWidget.loading({String? message}) =>
      AppStateWidget(type: AppStateType.loading, message: message);

  factory AppStateWidget.empty({
    String? title,
    String? message,
    String? actionLabel,
    VoidCallback? onAction,
  }) => AppStateWidget(type: AppStateType.empty, title: title,
      message: message, actionLabel: actionLabel, onAction: onAction);

  factory AppStateWidget.error({
    String? message,
    VoidCallback? onRetry,
  }) => AppStateWidget(type: AppStateType.error, message: message,
      showRetry: onRetry != null, onRetry: onRetry);

  factory AppStateWidget.noConnection({VoidCallback? onRetry}) =>
      AppStateWidget(type: AppStateType.noConnection,
          showRetry: onRetry != null, onRetry: onRetry);

  factory AppStateWidget.noResults({
    String? query,
    VoidCallback? onClear,
  }) => AppStateWidget(type: AppStateType.noResults,
      message: query != null ? 'No results for "$query"' : null,
      actionLabel: onClear != null ? 'Clear search' : null,
      onAction: onClear);

  @override
  Widget build(BuildContext context) {
    if (type == AppStateType.loading) return _buildLoading(context);
    return _buildState(context);
  }

  Widget _buildLoading(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(message!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }

  Widget _buildState(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final _StateConfig config = _getConfig(colors);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            illustration ??
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: config.iconBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(config.icon, size: 40, color: config.iconColor),
                ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title ?? config.defaultTitle,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            if (message != null || config.defaultMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message ?? config.defaultMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
            if (showRetry && onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AppButton.filled(label: 'Try Again', onPressed: onRetry,
                  size: AppButtonSize.sm),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: showRetry ? AppSpacing.sm : AppSpacing.xl),
              AppButton.outlined(label: actionLabel!, onPressed: onAction,
                  size: AppButtonSize.sm),
            ],
            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              const SizedBox(height: AppSpacing.sm),
              AppButton.text(label: secondaryActionLabel!,
                  onPressed: onSecondaryAction),
            ],
          ],
        ),
      ),
    );
  }

  _StateConfig _getConfig(ColorScheme colors) {
    return switch (type) {
      AppStateType.empty => _StateConfig(
          icon: Iconsax.archive,
          iconColor: colors.onSurfaceVariant,
          iconBackground: colors.surfaceVariant,
          defaultTitle: 'Nothing here yet',
          defaultMessage: 'There\'s no content to display.',
        ),
      AppStateType.error => _StateConfig(
          icon: Iconsax.danger,
          iconColor: colors.error,
          iconBackground: colors.errorContainer,
          defaultTitle: 'Something went wrong',
          defaultMessage: 'An unexpected error occurred. Please try again.',
        ),
      AppStateType.noConnection => _StateConfig(
          icon: Iconsax.wifi_square,
          iconColor: colors.error,
          iconBackground: colors.errorContainer,
          defaultTitle: 'No connection',
          defaultMessage: 'Check your internet connection and try again.',
        ),
      AppStateType.noResults => _StateConfig(
          icon: Iconsax.search_normal,
          iconColor: colors.onSurfaceVariant,
          iconBackground: colors.surfaceContainerHighest,
          defaultTitle: 'No results',
          defaultMessage: 'Try adjusting your search.',
        ),
      AppStateType.comingSoon => _StateConfig(
          icon: Iconsax.ranking,
          iconColor: colors.primary,
          iconBackground: colors.primaryContainer,
          defaultTitle: 'Coming soon',
          defaultMessage: 'This feature is under development.',
        ),
      AppStateType.accessDenied => _StateConfig(
          icon: Iconsax.lock,
          iconColor: colors.error,
          iconBackground: colors.errorContainer,
          defaultTitle: 'Access denied',
          defaultMessage: 'You don\'t have permission to view this.',
        ),
      _ => _StateConfig(
          icon: Iconsax.info_circle,
          iconColor: colors.onSurfaceVariant,
          iconBackground: colors.surfaceContainerHighest,
          defaultTitle: '',
          defaultMessage: null,
        ),
    };
  }
}

class _StateConfig {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String defaultTitle;
  final String? defaultMessage;

  const _StateConfig({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.defaultTitle,
    this.defaultMessage,
  });
}
