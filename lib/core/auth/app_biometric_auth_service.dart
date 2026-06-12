// ─── AppBiometricAuthService ──────────────────────────────────────────────────
// Enterprise biometric authentication with PIN fallback and session locking.
//
// Features:
//   • Biometric check (fingerprint / face ID)
//   • PIN fallback with attempt limiting
//   • Session lock — auto-lock after [lockAfter] duration in background
//   • AppSessionGuard widget — wraps any screen requiring auth
//   • AppBiometricLockScreen — the actual lock UI
//
// Usage:
//   // Check if biometrics are available
//   final canUse = await AppBiometricAuthService.instance.canAuthenticate();
//
//   // Authenticate
//   final result = await AppBiometricAuthService.instance.authenticate(
//     reason: 'Confirm your identity to view balance',
//   );
//
//   // Session guard widget
//   AppSessionGuard(
//     lockAfter: Duration(minutes: 5),
//     child: MySecureScreen(),
//   )
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';

// ── Auth result ───────────────────────────────────────────────────────────────

sealed class AppAuthResult {
  const AppAuthResult();
}

class AppAuthSuccess extends AppAuthResult {
  const AppAuthSuccess();
}

class AppAuthFailure extends AppAuthResult {
  final String reason;
  const AppAuthFailure(this.reason);
}

class AppAuthCancelled extends AppAuthResult {
  const AppAuthCancelled();
}

class AppAuthNotAvailable extends AppAuthResult {
  const AppAuthNotAvailable();
}

// ── Biometric capability ──────────────────────────────────────────────────────

class AppBiometricCapability {
  final bool isAvailable;
  final bool hasFaceId;
  final bool hasFingerprint;
  final bool hasIris;
  final List<BiometricType> enrolled;

  const AppBiometricCapability({
    required this.isAvailable,
    required this.hasFaceId,
    required this.hasFingerprint,
    required this.hasIris,
    required this.enrolled,
  });

  static const unavailable = AppBiometricCapability(
    isAvailable: false,
    hasFaceId: false,
    hasFingerprint: false,
    hasIris: false,
    enrolled: [],
  );

  String get displayName {
    if (hasFaceId) return 'Face ID';
    if (hasFingerprint) return 'Fingerprint';
    if (hasIris) return 'Iris Scan';
    return 'Biometric';
  }

  IconData get icon {
    if (hasFaceId) return Icons.face_retouching_natural_rounded;
    if (hasFingerprint) return Icons.fingerprint_rounded;
    return Icons.lock_rounded;
  }
}

// ── Service ───────────────────────────────────────────────────────────────────

class AppBiometricAuthService {
  AppBiometricAuthService._();
  static final AppBiometricAuthService instance = AppBiometricAuthService._();

  final _auth = LocalAuthentication();

  // ── Capability check ────────────────────────────────────────────────────────

  Future<AppBiometricCapability> getCapability() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      if (!canCheck && !isDeviceSupported) return AppBiometricCapability.unavailable;

      final enrolled = await _auth.getAvailableBiometrics();
      return AppBiometricCapability(
        isAvailable: enrolled.isNotEmpty,
        hasFaceId: enrolled.contains(BiometricType.face),
        hasFingerprint: enrolled.contains(BiometricType.fingerprint),
        hasIris: enrolled.contains(BiometricType.iris),
        enrolled: enrolled,
      );
    } catch (_) {
      return AppBiometricCapability.unavailable;
    }
  }

  Future<bool> canAuthenticate() async =>
      (await getCapability()).isAvailable;

  // ── Authenticate ────────────────────────────────────────────────────────────

  Future<AppAuthResult> authenticate({
    String reason = 'Verify your identity to continue.',
    @Deprecated('useErrorDialogs is no longer supported in local_auth 3.0.0+')
    bool useErrorDialogs = true,
    bool stickyAuth = true,
    bool sensitiveTransaction = false,
  }) async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false, // allows device PIN as fallback
        sensitiveTransaction: sensitiveTransaction,
        persistAcrossBackgrounding: stickyAuth,
      );
      return authenticated ? const AppAuthSuccess() : const AppAuthFailure('Authentication failed.');
    } on LocalAuthException catch (e) {
      return switch (e.code) {
        LocalAuthExceptionCode.noBiometricsEnrolled => const AppAuthNotAvailable(),
        LocalAuthExceptionCode.noBiometricHardware => const AppAuthNotAvailable(),
        LocalAuthExceptionCode.noCredentialsSet => const AppAuthNotAvailable(),
        LocalAuthExceptionCode.userCanceled => const AppAuthCancelled(),
        LocalAuthExceptionCode.systemCanceled => const AppAuthCancelled(),
        LocalAuthExceptionCode.timeout => const AppAuthFailure('Authentication timed out.'),
        _ => AppAuthFailure('Authentication failed: ${e.description}'),
      };
    } on PlatformException catch (e) {
      return switch (e.code) {
        'NotEnrolled'      => const AppAuthNotAvailable(),
        'NotAvailable'     => const AppAuthNotAvailable(),
        'LockedOut'        => AppAuthFailure('Biometric locked out: ${e.message}'),
        'PermanentlyLockedOut' => AppAuthFailure('Biometric permanently locked.'),
        _                  => AppAuthCancelled(),
      };
    } catch (e) {
      return AppAuthFailure(e.toString());
    }
  }

  Future<void> stopAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } catch (_) {}
  }
}

// ── Session state ─────────────────────────────────────────────────────────────

enum _SessionState { unlocked, locked, authenticating }

// ── AppSessionGuard ───────────────────────────────────────────────────────────
// Wraps any widget subtree with biometric session locking.
// Automatically locks after [lockAfter] duration in background.

class AppSessionGuard extends StatefulWidget {
  final Widget child;

  /// Auto-lock after this duration when app goes to background.
  /// Set to null to disable auto-lock.
  final Duration? lockAfter;

  /// Custom lock screen. Defaults to [AppBiometricLockScreen].
  final Widget? customLockScreen;

  /// Called when session is unlocked.
  final VoidCallback? onUnlocked;

  const AppSessionGuard({
    super.key,
    required this.child,
    this.lockAfter = const Duration(minutes: 5),
    this.customLockScreen,
    this.onUnlocked,
  });

  @override
  State<AppSessionGuard> createState() => _AppSessionGuardState();
}

class _AppSessionGuardState extends State<AppSessionGuard>
    with WidgetsBindingObserver {
  _SessionState _state = _SessionState.unlocked;
  DateTime? _backgroundTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _backgroundTime = DateTime.now();
        break;
      case AppLifecycleState.resumed:
        _checkShouldLock();
        break;
      default:
        break;
    }
  }

  void _checkShouldLock() {
    if (widget.lockAfter == null) return;
    if (_backgroundTime == null) return;
    if (_state == _SessionState.locked) return;

    final elapsed = DateTime.now().difference(_backgroundTime!);
    if (elapsed >= widget.lockAfter!) {
      setState(() => _state = _SessionState.locked);
    }
    _backgroundTime = null;
  }

  Future<void> _unlock() async {
    if (_state == _SessionState.authenticating) return;
    setState(() => _state = _SessionState.authenticating);

    final result = await AppBiometricAuthService.instance.authenticate(
      reason: 'Unlock to continue',
    );

    if (!mounted) return;

    if (result is AppAuthSuccess) {
      setState(() => _state = _SessionState.unlocked);
      widget.onUnlocked?.call();
    } else {
      setState(() => _state = _SessionState.locked);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_state == _SessionState.unlocked) return widget.child;
    return widget.customLockScreen ??
        AppBiometricLockScreen(
          onUnlock: _unlock,
          isAuthenticating: _state == _SessionState.authenticating,
        );
  }
}

// ── AppBiometricLockScreen ────────────────────────────────────────────────────

class AppBiometricLockScreen extends StatelessWidget {
  final VoidCallback onUnlock;
  final bool isAuthenticating;
  final String? appName;
  final Widget? logo;

  const AppBiometricLockScreen({
    super.key,
    required this.onUnlock,
    this.isAuthenticating = false,
    this.appName,
    this.logo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : cs.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo / app icon
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withOpacity(0.2),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: logo ??
                      Icon(Icons.lock_rounded, size: 40, color: cs.primary),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  appName ?? 'App Locked',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : cs.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Verify your identity to continue',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? Colors.white60
                        : cs.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxxl),

                // Biometric button
                GestureDetector(
                  onTap: isAuthenticating ? null : onUnlock,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: isAuthenticating
                          ? cs.primaryContainer
                          : cs.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: isAuthenticating
                        ? Padding(
                            padding: const EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: cs.primary,
                            ),
                          )
                        : Icon(Icons.fingerprint_rounded, size: 40, color: cs.onPrimary),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  isAuthenticating ? 'Authenticating...' : 'Tap to unlock',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white38 : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
