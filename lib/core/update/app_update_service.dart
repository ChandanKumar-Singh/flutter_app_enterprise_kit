// ─── AppUpdateService ─────────────────────────────────────────────────────────
// App version checking with force-update gate and optional update sheet.
//
// Architecture:
//   AppUpdateBackend (abstract)
//     └── _RemoteJsonUpdateBackend  (fetch JSON from your API)
//     └── _NoopUpdateBackend        (default no-op)
//
// Usage:
//   // 1. Init with your backend
//   AppUpdateService.init(backend: _RemoteJsonUpdateBackend('https://...'));
//
//   // 2. Check after login / on resume
//   await AppUpdateService.instance.checkAndPrompt(context);
//
// The update info JSON contract (from your API):
//   {
//     "minVersion": "2.0.0",
//     "latestVersion": "2.3.1",
//     "storeUrl": "https://play.google.com/store/apps/...",
//     "releaseNotes": "Bug fixes and performance improvements.",
//     "isForced": false
//   }
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:iconsax/iconsax.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';

// ── Version helpers ───────────────────────────────────────────────────────────

class _SemVer implements Comparable<_SemVer> {
  final int major, minor, patch;

  const _SemVer(this.major, this.minor, this.patch);

  factory _SemVer.parse(String version) {
    final cleaned = version.replaceAll(RegExp(r'[^0-9.]'), '');
    final parts = cleaned.split('.').map(int.tryParse).toList();
    return _SemVer(
      parts.length > 0 ? (parts[0] ?? 0) : 0,
      parts.length > 1 ? (parts[1] ?? 0) : 0,
      parts.length > 2 ? (parts[2] ?? 0) : 0,
    );
  }

  @override
  int compareTo(_SemVer other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  bool operator >(other) => compareTo(other as _SemVer) > 0;
  bool operator <(other) => compareTo(other as _SemVer) < 0;
  bool operator >=(other) => compareTo(other as _SemVer) >= 0;

  @override
  String toString() => '$major.$minor.$patch';
}

// ── Update info model ─────────────────────────────────────────────────────────

class AppUpdateInfo {
  /// Minimum version required to run the app (force update below this).
  final String minVersion;

  /// Latest available version in the store.
  final String latestVersion;

  /// App store / Play store URL.
  final String storeUrl;

  /// What's new in the latest version.
  final String? releaseNotes;

  /// If true, the app cannot continue without updating.
  final bool isForced;

  const AppUpdateInfo({
    required this.minVersion,
    required this.latestVersion,
    required this.storeUrl,
    this.releaseNotes,
    this.isForced = false,
  });

  factory AppUpdateInfo.fromMap(Map<String, dynamic> map) => AppUpdateInfo(
        minVersion: map['minVersion'] as String,
        latestVersion: map['latestVersion'] as String,
        storeUrl: map['storeUrl'] as String,
        releaseNotes: map['releaseNotes'] as String?,
        isForced: map['isForced'] as bool? ?? false,
      );
}

// ── Update check result ───────────────────────────────────────────────────────

sealed class AppUpdateResult {
  const AppUpdateResult();
}

class AppUpdateUpToDate extends AppUpdateResult {
  const AppUpdateUpToDate();
}

class AppUpdateAvailable extends AppUpdateResult {
  final AppUpdateInfo info;
  final String currentVersion;
  const AppUpdateAvailable({required this.info, required this.currentVersion});
}

class AppUpdateForced extends AppUpdateResult {
  final AppUpdateInfo info;
  final String currentVersion;
  const AppUpdateForced({required this.info, required this.currentVersion});
}

class AppUpdateCheckError extends AppUpdateResult {
  final Object error;
  const AppUpdateCheckError(this.error);
}

// ── Backend interface ─────────────────────────────────────────────────────────

abstract class AppUpdateBackend {
  /// Fetch the latest update info from your server.
  /// Throw on network error — [AppUpdateService] catches it.
  Future<AppUpdateInfo> fetchUpdateInfo();
}

class _NoopUpdateBackend implements AppUpdateBackend {
  @override
  Future<AppUpdateInfo> fetchUpdateInfo() async =>
      const AppUpdateInfo(
        minVersion: '0.0.0',
        latestVersion: '0.0.0',
        storeUrl: '',
      );
}

// ── Service ───────────────────────────────────────────────────────────────────

class AppUpdateService {
  AppUpdateService._();
  static AppUpdateService instance = AppUpdateService._();

  AppUpdateBackend _backend = _NoopUpdateBackend();

  static void init({required AppUpdateBackend backend}) {
    instance._backend = backend;
  }

  // ── Check ───────────────────────────────────────────────────────────────────

  Future<AppUpdateResult> check() async {
    try {
      final info = await _backend.fetchUpdateInfo();
      final pkg = await PackageInfo.fromPlatform();
      final current = _SemVer.parse(pkg.version);
      final min = _SemVer.parse(info.minVersion);
      final latest = _SemVer.parse(info.latestVersion);

      if (current < min || info.isForced) {
        return AppUpdateForced(info: info, currentVersion: pkg.version);
      }
      if (current < latest) {
        return AppUpdateAvailable(info: info, currentVersion: pkg.version);
      }
      return const AppUpdateUpToDate();
    } catch (e) {
      return AppUpdateCheckError(e);
    }
  }

  // ── Check + show UI ────────────────────────────────────────────────────────

  /// Check for updates and show the appropriate dialog / sheet.
  /// Returns true if an update prompt was shown.
  Future<bool> checkAndPrompt(BuildContext context) async {
    final result = await check();

    if (!context.mounted) return false;

    return switch (result) {
      AppUpdateForced(:final info, :final currentVersion) => _showForceDialog(
          context,
          info: info,
          currentVersion: currentVersion,
        ),
      AppUpdateAvailable(:final info, :final currentVersion) =>
        _showOptionalSheet(
          context,
          info: info,
          currentVersion: currentVersion,
        ),
      _ => false,
    };
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  Future<bool> _showForceDialog(
    BuildContext context, {
    required AppUpdateInfo info,
    required String currentVersion,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AppForceUpdateDialog(info: info, currentVersion: currentVersion),
    );
    return true;
  }

  Future<bool> _showOptionalSheet(
    BuildContext context, {
    required AppUpdateInfo info,
    required String currentVersion,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (_) => _AppOptionalUpdateSheet(info: info, currentVersion: currentVersion),
    );
    return true;
  }
}

// ── Force Update Dialog ───────────────────────────────────────────────────────

class _AppForceUpdateDialog extends StatelessWidget {
  final AppUpdateInfo info;
  final String currentVersion;

  const _AppForceUpdateDialog({
    required this.info,
    required this.currentVersion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return PopScope(
      canPop: false, // Cannot dismiss
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.xl),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.refresh, size: 36, color: cs.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Update Required',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Version $currentVersion is no longer supported. '
              'Please update to version ${info.latestVersion} to continue.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (info.releaseNotes != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Text(
                  info.releaseNotes!,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openStore(info.storeUrl),
                icon: const Icon(Iconsax.document_download),
                label: const Text('Update Now'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Optional Update Sheet ─────────────────────────────────────────────────────

class _AppOptionalUpdateSheet extends StatelessWidget {
  final AppUpdateInfo info;
  final String currentVersion;

  const _AppOptionalUpdateSheet({
    required this.info,
    required this.currentVersion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl, AppSpacing.xs, AppSpacing.xl, AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(Iconsax.flash, color: cs.primary, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Update Available',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'v$currentVersion → v${info.latestVersion}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (info.releaseNotes != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              "What's New",
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              info.releaseNotes!,
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: const Text('Later'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _openStore(info.storeUrl);
                  },
                  icon: const Icon(Iconsax.document_download),
                  label: const Text('Update'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _openStore(String storeUrl) async {
  final uri = Uri.tryParse(storeUrl);
  if (uri != null && await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
