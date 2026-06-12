// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';
import 'package:enterprise_kit/shared/widgets/buttons/app_button.dart';

// ─── Permission Types ─────────────────────────────────────────────────────────

/// All permission types the app can request.
/// Platform availability is resolved internally — callers never need to check OS.
enum AppPermissionType {
  /// Take photos/videos with the camera. iOS + Android.
  camera,

  /// Read the photo library / gallery.
  /// iOS: `photos` (returns `limited` on iOS 14+ if partial access granted).
  /// Android < 13: `storage`. Android 13+: `photos` + `videos`.
  photoLibrary,

  /// Add images to the photo library without read access.
  /// iOS only — Android doesn't distinguish add-only vs read.
  photoLibraryAdd,

  /// Record audio using the microphone. iOS + Android.
  microphone,

  /// Fine location while the app is in use (foreground). iOS + Android.
  locationWhenInUse,

  /// Precise background location. iOS + Android.
  locationAlways,

  /// Push / local notification delivery. iOS (required), Android 13+.
  notifications,

  /// Read and write device contacts. iOS + Android.
  contacts,

  /// General file storage (documents, downloads).
  /// Android < 13: `storage`. Android 13+: auto-skipped (scoped storage).
  /// iOS: not applicable.
  storage,

  /// Read calendar events. iOS + Android.
  calendarRead,

  /// Create/edit calendar events. iOS + Android.
  calendarWrite,

  /// Bluetooth device discovery & connection.
  /// Android < 12: `bluetooth`. Android 12+: `bluetoothScan` + `bluetoothConnect`.
  bluetooth,

  /// Bluetooth scanning for nearby devices.
  /// Android 12+ only.
  bluetoothScan,

  /// Make and manage phone calls. Android only.
  phone,

  /// Send and receive SMS messages. Android only.
  sms,

  /// On-device speech recognition. iOS only.
  speechRecognition,

  /// Physical activity / step counting. Android 10+ + iOS.
  activityRecognition,

  /// App Tracking Transparency (show tracking authorization prompt). iOS 14+ only.
  appTracking,

  /// Access to nearby Wi-Fi networks. Android 12+ only.
  nearbyWifi,

  /// Broad external storage management (document pickers).
  /// Android 11+ MANAGE_EXTERNAL_STORAGE — granted via special Settings page.
  manageExternalStorage,
}

// ─── Status ───────────────────────────────────────────────────────────────────

enum AppPermissionStatus {
  /// Permission granted — proceed.
  granted,

  /// iOS Photos limited access — proceed with reduced set.
  limited,

  /// User denied — can request again (hasn't tapped "Never ask again").
  denied,

  /// Permanently denied — must redirect to OS Settings.
  permanentlyDenied,

  /// Parental controls / MDM restrict this permission. iOS only.
  restricted,

  /// This permission type is not applicable on the current OS/version.
  notApplicable,
}

// ─── Result ───────────────────────────────────────────────────────────────────

class AppPermissionResult {
  final AppPermissionType type;
  final AppPermissionStatus status;

  const AppPermissionResult({required this.type, required this.status});

  bool get isGranted => status == AppPermissionStatus.granted || status == AppPermissionStatus.limited;
  bool get isDenied => status == AppPermissionStatus.denied;
  bool get isPermanentlyDenied => status == AppPermissionStatus.permanentlyDenied;
  bool get isRestricted => status == AppPermissionStatus.restricted;
  bool get isNotApplicable => status == AppPermissionStatus.notApplicable;

  @override
  String toString() => 'AppPermissionResult($type, $status)';
}

// ─── Rationale ────────────────────────────────────────────────────────────────

class AppPermissionMeta {
  final String title;
  final String rationale;         // shown before first request
  final String deniedMessage;     // shown after denial, before Settings redirect
  final IconData icon;
  final Color color;

  const AppPermissionMeta({
    required this.title,
    required this.rationale,
    required this.deniedMessage,
    required this.icon,
    required this.color,
  });

  AppPermissionMeta copyWith({
    String? title,
    String? rationale,
    String? deniedMessage,
    IconData? icon,
    Color? color,
  }) {
    return AppPermissionMeta(
      title: title ?? this.title,
      rationale: rationale ?? this.rationale,
      deniedMessage: deniedMessage ?? this.deniedMessage,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }
}

// ─── AppPermissionManager ─────────────────────────────────────────────────────
/// Enterprise-grade, platform-aware permission manager.
///
/// Usage:
/// ```dart
/// // Single
/// final result = await AppPermissionManager.request(
///   context, AppPermissionType.camera,
/// );
/// if (result.isGranted) { ... }
///
/// // Multi
/// final results = await AppPermissionManager.requestAll(
///   context,
///   [AppPermissionType.camera, AppPermissionType.microphone],
/// );
/// ```
///
/// Handles:
/// - iOS `limited` photos access
/// - Android 13+ granular media permissions vs legacy `storage`
/// - Android 12+ bluetooth split permissions
/// - iOS-only types (ATT, speechRecognition, photoLibraryAdd)
/// - Android-only types (phone, sms, nearbyWifi, manageExternalStorage)
/// - `permanentlyDenied` → Settings redirect dialog
/// - Rationale dialog before first OS prompt (optional)
class AppPermissionManager {
  AppPermissionManager._();

  static final _deviceInfo = DeviceInfoPlugin();
  static int? _androidSdkVersion;

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Request a single permission. Shows rationale first, then the OS dialog.
  /// Returns [AppPermissionResult.notApplicable] if the type isn't supported
  /// on the current platform/OS version.
  static Future<AppPermissionResult> request(
    BuildContext context,
    AppPermissionType type, {
    bool showRationale = true,
    String? location,
    String? useCase,
    Map<String, String>? variables,
    AppPermissionMeta? metaOverride,
    Widget Function(BuildContext context, AppPermissionMeta meta, VoidCallback onAllow, VoidCallback onCancel)? rationaleDialogBuilder,
    Widget Function(BuildContext context, AppPermissionMeta meta, VoidCallback onOpenSettings, VoidCallback onCancel)? settingsDialogBuilder,
  }) async {
    final permissions = await _resolve(type);
    if (permissions.isEmpty) {
      return AppPermissionResult(type: type, status: AppPermissionStatus.notApplicable);
    }

    // Check current status first
    final currentStatuses = await Future.wait(permissions.map((p) => p.status));
    final isAlreadyGranted = currentStatuses.every((s) => s.isGranted || s.isLimited);
    if (isAlreadyGranted) {
      return AppPermissionResult(type: type, status: _mapStatus(currentStatuses.first));
    }

    final meta = resolveMeta(
      type,
      location: location,
      useCase: useCase,
      variables: variables,
      metaOverride: metaOverride,
    );

    // Rationale dialog before asking OS
    if (showRationale && context.mounted) {
      final shouldProceed = await _showRationaleDialog(
        context,
        type,
        meta,
        rationaleDialogBuilder: rationaleDialogBuilder,
      );
      if (!shouldProceed) {
        return AppPermissionResult(type: type, status: AppPermissionStatus.denied);
      }
    }

    // Request
    final Map<Permission, PermissionStatus> statuses =
        await permissions.request();

    final combined = _combineStatuses(statuses.values.toList());

    if ((combined.isPermanentlyDenied || combined.isRestricted) && context.mounted) {
      await _showSettingsDialog(
        context,
        type,
        meta,
        settingsDialogBuilder: settingsDialogBuilder,
      );
    }

    return AppPermissionResult(type: type, status: _mapStatus(combined));
  }

  /// Request multiple permissions at once.
  /// Returns a map from each type to its result.
  static Future<Map<AppPermissionType, AppPermissionResult>> requestAll(
    BuildContext context,
    List<AppPermissionType> types, {
    bool showRationale = true,
    String? location,
    String? useCase,
    Map<String, String>? variables,
    Map<AppPermissionType, AppPermissionMeta>? overrides,
    Widget Function(BuildContext context, List<AppPermissionType> types, List<AppPermissionMeta> metas, VoidCallback onContinue, VoidCallback onCancel)? batchedRationaleDialogBuilder,
    Widget Function(BuildContext context, AppPermissionMeta meta, VoidCallback onOpenSettings, VoidCallback onCancel)? settingsDialogBuilder,
  }) async {
    final results = <AppPermissionType, AppPermissionResult>{};

    // Show grouped rationale for types that need it
    final needsRequest = <AppPermissionType>[];
    for (final type in types) {
      final permissions = await _resolve(type);
      if (permissions.isEmpty) {
        results[type] = AppPermissionResult(type: type, status: AppPermissionStatus.notApplicable);
        continue;
      }
      final statuses = await Future.wait(permissions.map((p) => p.status));
      if (statuses.every((s) => s.isGranted || s.isLimited)) {
        results[type] = AppPermissionResult(type: type, status: _mapStatus(statuses.first));
      } else {
        needsRequest.add(type);
      }
    }

    if (needsRequest.isEmpty) return results;

    // Resolve metas
    final resolvedMetas = needsRequest.map((type) {
      return resolveMeta(
        type,
        location: location,
        useCase: useCase,
        variables: variables,
        metaOverride: overrides?[type],
      );
    }).toList();

    // Show batched rationale
    if (showRationale && context.mounted) {
      final shouldProceed = await _showBatchedRationaleDialog(
        context,
        needsRequest,
        resolvedMetas,
        batchedRationaleDialogBuilder: batchedRationaleDialogBuilder,
      );
      if (!shouldProceed) {
        for (final type in needsRequest) {
          results[type] = AppPermissionResult(type: type, status: AppPermissionStatus.denied);
        }
        return results;
      }
    }

    // Collect all Permission objects and request together
    final allPerms = <AppPermissionType, List<Permission>>{};
    for (final type in needsRequest) {
      allPerms[type] = await _resolve(type);
    }

    final flat = allPerms.values.expand((p) => p).toSet().toList();
    final statuses = await flat.request();

    // Map back
    for (int i = 0; i < needsRequest.length; i++) {
      final type = needsRequest[i];
      final meta = resolvedMetas[i];
      final typePerms = allPerms[type] ?? [];
      final typeStatuses = typePerms.map((p) => statuses[p] ?? PermissionStatus.denied).toList();
      final combined = _combineStatuses(typeStatuses);

      if ((combined.isPermanentlyDenied || combined.isRestricted) && context.mounted) {
        await _showSettingsDialog(
          context,
          type,
          meta,
          settingsDialogBuilder: settingsDialogBuilder,
        );
      }

      results[type] = AppPermissionResult(type: type, status: _mapStatus(combined));
    }

    return results;
  }

  /// Check the current status without requesting.
  static Future<AppPermissionResult> check(
    AppPermissionType type, {
    String? location,
    String? useCase,
    Map<String, String>? variables,
    AppPermissionMeta? metaOverride,
  }) async {
    final permissions = await _resolve(type);
    if (permissions.isEmpty) {
      return AppPermissionResult(type: type, status: AppPermissionStatus.notApplicable);
    }
    final statuses = await Future.wait(permissions.map((p) => p.status));
    return AppPermissionResult(type: type, status: _mapStatus(_combineStatuses(statuses)));
  }

  /// Quick boolean — true if all permissions for this type are granted.
  static Future<bool> isGranted(AppPermissionType type) async {
    final result = await check(type);
    return result.isGranted;
  }

  /// Open the OS app settings page.
  static Future<void> openSettings() => openAppSettings();

  // ── Platform Resolution ──────────────────────────────────────────────────────

  /// Returns the list of [Permission] objects that implement [type]
  /// on the current platform/OS version. Empty = not applicable.
  static Future<List<Permission>> _resolve(AppPermissionType type) async {
    if (Platform.isIOS) return _resolveIOS(type);
    if (Platform.isAndroid) return _resolveAndroid(type);
    return [];
  }

  static List<Permission> _resolveIOS(AppPermissionType type) {
    return switch (type) {
      AppPermissionType.camera             => [Permission.camera],
      AppPermissionType.photoLibrary       => [Permission.photos],
      AppPermissionType.photoLibraryAdd    => [Permission.photosAddOnly],
      AppPermissionType.microphone         => [Permission.microphone],
      AppPermissionType.locationWhenInUse  => [Permission.locationWhenInUse],
      AppPermissionType.locationAlways     => [Permission.locationAlways],
      AppPermissionType.notifications      => [Permission.notification],
      AppPermissionType.contacts           => [Permission.contacts],
      AppPermissionType.calendarRead       => [Permission.calendarFullAccess],
      AppPermissionType.calendarWrite      => [Permission.calendarWriteOnly],
      AppPermissionType.bluetooth          => [Permission.bluetooth],
      AppPermissionType.speechRecognition  => [Permission.speech],
      AppPermissionType.activityRecognition=> [Permission.sensors],
      AppPermissionType.appTracking        => [Permission.appTrackingTransparency],
      // Android-only or not applicable on iOS
      AppPermissionType.storage            => [],
      AppPermissionType.phone              => [],
      AppPermissionType.sms                => [],
      AppPermissionType.nearbyWifi         => [],
      AppPermissionType.manageExternalStorage => [],
      AppPermissionType.bluetoothScan      => [],   // handled under bluetooth
    };
  }

  static Future<List<Permission>> _resolveAndroid(AppPermissionType type) async {
    final sdk = await _getAndroidSdk();

    return switch (type) {
      AppPermissionType.camera             => [Permission.camera],

      AppPermissionType.photoLibrary       =>
        sdk >= 33
          ? [Permission.photos, Permission.videos]
          : [Permission.storage],

      AppPermissionType.microphone         => [Permission.microphone],

      AppPermissionType.locationWhenInUse  => [Permission.locationWhenInUse],
      AppPermissionType.locationAlways     => [Permission.locationAlways],

      AppPermissionType.notifications      =>
        sdk >= 33 ? [Permission.notification] : [],

      AppPermissionType.contacts           => [Permission.contacts],

      AppPermissionType.storage            =>
        sdk >= 33 ? [] : [Permission.storage],  // Scoped storage: not needed on 13+

      AppPermissionType.calendarRead       => [Permission.calendarFullAccess],
      AppPermissionType.calendarWrite      => [Permission.calendarWriteOnly],

      AppPermissionType.bluetooth          =>
        sdk >= 31
          ? [Permission.bluetoothScan, Permission.bluetoothConnect]
          : [Permission.bluetooth],

      AppPermissionType.phone              => [Permission.phone],
      AppPermissionType.sms                => [Permission.sms],

      AppPermissionType.activityRecognition=>
        sdk >= 29 ? [Permission.activityRecognition] : [],

      AppPermissionType.nearbyWifi         =>
        sdk >= 31 ? [Permission.nearbyWifiDevices] : [],

      AppPermissionType.manageExternalStorage =>
        sdk >= 30 ? [Permission.manageExternalStorage] : [Permission.storage],

      // iOS-only
      AppPermissionType.photoLibraryAdd    => [Permission.photos], // add = same as read on Android
      AppPermissionType.speechRecognition  => [],
      AppPermissionType.appTracking        => [],
      AppPermissionType.bluetoothScan      => sdk >= 31 ? [Permission.bluetoothScan] : [],
    };
  }

  static Future<int> _getAndroidSdk() async {
    if (_androidSdkVersion != null) return _androidSdkVersion!;
    try {
      final info = await _deviceInfo.androidInfo;
      _androidSdkVersion = info.version.sdkInt;
      return _androidSdkVersion!;
    } catch (_) {
      return 30; // safe fallback
    }
  }

  // ── Status Helpers ───────────────────────────────────────────────────────────

  /// When multiple permissions are requested for one type, combine them.
  /// All must be granted for the type to be "granted".
  static PermissionStatus _combineStatuses(List<PermissionStatus> statuses) {
    if (statuses.isEmpty) return PermissionStatus.denied;
    if (statuses.every((s) => s.isGranted)) return PermissionStatus.granted;
    if (statuses.any((s) => s.isPermanentlyDenied)) return PermissionStatus.permanentlyDenied;
    if (statuses.any((s) => s.isRestricted)) return PermissionStatus.restricted;
    if (statuses.any((s) => s.isLimited)) return PermissionStatus.limited;
    return PermissionStatus.denied;
  }

  static AppPermissionStatus _mapStatus(PermissionStatus s) {
    if (s.isGranted)            return AppPermissionStatus.granted;
    if (s.isLimited)            return AppPermissionStatus.limited;
    if (s.isPermanentlyDenied)  return AppPermissionStatus.permanentlyDenied;
    if (s.isRestricted)         return AppPermissionStatus.restricted;
    return AppPermissionStatus.denied;
  }

  // ── Meta ────────────────────────────────────────────────────────────────────

  // Global registry for context-specific overrides: key is "type:location:useCase"
  static final Map<String, AppPermissionMeta> _registry = {};

  /// Global/static resolver callback for dynamic permission metadata lookups.
  /// If provided, it runs after registry check and can return a custom [AppPermissionMeta].
  static AppPermissionMeta? Function(
    AppPermissionType type, {
    String? location,
    String? useCase,
  })? resolver;

  /// Register a custom permission metadata override for a specific location and usecase.
  /// Wildcards ('*') can be used for location or useCase to apply generally.
  static void registerOverride({
    required AppPermissionType type,
    String? location,
    String? useCase,
    required AppPermissionMeta meta,
  }) {
    final key = _registryKey(type, location, useCase);
    _registry[key] = meta;
  }

  static String _registryKey(AppPermissionType type, String? location, String? useCase) {
    final loc = location ?? '*';
    final uc = useCase ?? '*';
    return '${type.name}:$loc:$uc';
  }

  /// Looks up registered metadata overrides, handling wildcards.
  static AppPermissionMeta? _lookupRegistry(AppPermissionType type, String? location, String? useCase) {
    if (location == null && useCase == null) return null;
    
    // 1. Try exact match: type:location:useCase
    final exactKey = _registryKey(type, location, useCase);
    if (_registry.containsKey(exactKey)) return _registry[exactKey];

    // 2. Try type:location:*
    if (useCase != null) {
      final locOnlyKey = _registryKey(type, location, '*');
      if (_registry.containsKey(locOnlyKey)) return _registry[locOnlyKey];
    }

    // 3. Try type:*:useCase
    if (location != null) {
      final ucOnlyKey = _registryKey(type, '*', useCase);
      if (_registry.containsKey(ucOnlyKey)) return _registry[ucOnlyKey];
    }

    return null;
  }

  /// Resolves the final [AppPermissionMeta] dynamically.
  /// Combines the base metadata, registry/resolver overrides, and replaces placeholders in the strings.
  static AppPermissionMeta resolveMeta(
    AppPermissionType type, {
    String? location,
    String? useCase,
    Map<String, String>? variables,
    AppPermissionMeta? metaOverride,
  }) {
    // 1. Base metadata
    AppPermissionMeta meta = _meta(type);

    // 2. Registry lookup
    final registryMeta = _lookupRegistry(type, location, useCase);
    if (registryMeta != null) {
      meta = registryMeta;
    }

    // 3. Global resolver callback lookup
    if (resolver != null) {
      final resolved = resolver!(type, location: location, useCase: useCase);
      if (resolved != null) {
        meta = resolved;
      }
    }

    // 4. Direct override
    if (metaOverride != null) {
      meta = metaOverride;
    }

    // 5. Dynamic placeholder replacement (template parsing)
    final Map<String, String> replacements = {
      'location': location ?? 'app',
      'usecase': useCase ?? 'perform operations',
      if (variables != null) ...variables,
    };

    String title = meta.title;
    String rationale = meta.rationale;
    String deniedMessage = meta.deniedMessage;

    replacements.forEach((key, value) {
      final placeholder = '{$key}';
      title = title.replaceAll(placeholder, value);
      rationale = rationale.replaceAll(placeholder, value);
      deniedMessage = deniedMessage.replaceAll(placeholder, value);
    });

    return meta.copyWith(
      title: title,
      rationale: rationale,
      deniedMessage: deniedMessage,
    );
  }

  static AppPermissionMeta _meta(AppPermissionType type) {
    return switch (type) {
      AppPermissionType.camera => const AppPermissionMeta(
        title: 'Camera',
        rationale: 'We need camera access to let you take photos and scan documents directly in the app.',
        deniedMessage: 'Camera access is required. Please enable it in Settings → Privacy → Camera.',
        icon: Icons.camera_alt_rounded,
        color: Color(0xFF2563EB),
      ),
      AppPermissionType.photoLibrary => const AppPermissionMeta(
        title: 'Photo Library',
        rationale: 'We need access to your photos to let you select and upload images.',
        deniedMessage: 'Photo access is required. Enable it in Settings → Privacy → Photos.',
        icon: Icons.photo_library_rounded,
        color: Color(0xFF7C3AED),
      ),
      AppPermissionType.photoLibraryAdd => const AppPermissionMeta(
        title: 'Save to Photos',
        rationale: 'We need permission to save images directly to your photo library.',
        deniedMessage: 'Photo library write access is required. Enable it in Settings → Privacy → Photos.',
        icon: Icons.add_photo_alternate_rounded,
        color: Color(0xFF7C3AED),
      ),
      AppPermissionType.microphone => const AppPermissionMeta(
        title: 'Microphone',
        rationale: 'Microphone access is needed to record audio and enable voice features.',
        deniedMessage: 'Microphone access is required. Enable it in Settings → Privacy → Microphone.',
        icon: Icons.mic_rounded,
        color: Color(0xFFDC2626),
      ),
      AppPermissionType.locationWhenInUse => const AppPermissionMeta(
        title: 'Location',
        rationale: 'Your location helps us show nearby services and provide accurate results.',
        deniedMessage: 'Location access is required. Enable it in Settings → Privacy → Location Services.',
        icon: Icons.location_on_rounded,
        color: Color(0xFF16A34A),
      ),
      AppPermissionType.locationAlways => const AppPermissionMeta(
        title: 'Background Location',
        rationale: 'Always-on location allows us to send relevant alerts even when the app is closed.',
        deniedMessage: 'Background location is required. Enable "Always" in Settings → Privacy → Location Services.',
        icon: Icons.my_location_rounded,
        color: Color(0xFF15803D),
      ),
      AppPermissionType.notifications => const AppPermissionMeta(
        title: 'Notifications',
        rationale: 'Enable notifications to receive order updates, delivery alerts, and important messages.',
        deniedMessage: 'Notifications are disabled. Enable them in Settings → Notifications.',
        icon: Icons.notifications_rounded,
        color: Color(0xFFD97706),
      ),
      AppPermissionType.contacts => const AppPermissionMeta(
        title: 'Contacts',
        rationale: 'Contact access lets you quickly share or invite friends already in your phonebook.',
        deniedMessage: 'Contacts access is required. Enable it in Settings → Privacy → Contacts.',
        icon: Icons.contacts_rounded,
        color: Color(0xFF0891B2),
      ),
      AppPermissionType.storage => const AppPermissionMeta(
        title: 'Storage',
        rationale: 'Storage access lets the app read and save files on your device.',
        deniedMessage: 'Storage access is required. Enable it in Settings → Privacy → Files & Media.',
        icon: Icons.folder_rounded,
        color: Color(0xFF65A30D),
      ),
      AppPermissionType.calendarRead => const AppPermissionMeta(
        title: 'Calendar (Read)',
        rationale: 'Calendar read access lets us check your schedule to avoid conflicts.',
        deniedMessage: 'Calendar access is required. Enable it in Settings → Privacy → Calendars.',
        icon: Icons.calendar_today_rounded,
        color: Color(0xFFEC4899),
      ),
      AppPermissionType.calendarWrite => const AppPermissionMeta(
        title: 'Calendar (Write)',
        rationale: 'Calendar write access lets us add bookings and reminders to your calendar.',
        deniedMessage: 'Calendar write access is required. Enable it in Settings → Privacy → Calendars.',
        icon: Icons.edit_calendar_rounded,
        color: Color(0xFFEC4899),
      ),
      AppPermissionType.bluetooth => const AppPermissionMeta(
        title: 'Bluetooth',
        rationale: 'Bluetooth access is needed to connect to nearby devices and accessories.',
        deniedMessage: 'Bluetooth access is required. Enable it in Settings → Privacy → Bluetooth.',
        icon: Icons.bluetooth_rounded,
        color: Color(0xFF1D4ED8),
      ),
      AppPermissionType.bluetoothScan => const AppPermissionMeta(
        title: 'Nearby Devices',
        rationale: 'Bluetooth scan permission lets us find nearby devices.',
        deniedMessage: 'Nearby devices access is required. Enable Bluetooth in Settings.',
        icon: Icons.bluetooth_searching_rounded,
        color: Color(0xFF1D4ED8),
      ),
      AppPermissionType.phone => const AppPermissionMeta(
        title: 'Phone',
        rationale: 'Phone access lets you call support or contacts directly from the app.',
        deniedMessage: 'Phone access is required. Enable it in Settings → Apps → Permissions → Phone.',
        icon: Icons.phone_rounded,
        color: Color(0xFF16A34A),
      ),
      AppPermissionType.sms => const AppPermissionMeta(
        title: 'SMS',
        rationale: 'SMS access lets us auto-read OTP verification codes sent to your phone.',
        deniedMessage: 'SMS access is required. Enable it in Settings → Apps → Permissions → SMS.',
        icon: Icons.sms_rounded,
        color: Color(0xFF7C3AED),
      ),
      AppPermissionType.speechRecognition => const AppPermissionMeta(
        title: 'Speech Recognition',
        rationale: 'Speech recognition lets you use voice commands and voice-to-text features.',
        deniedMessage: 'Speech recognition access is required. Enable it in Settings → Privacy → Speech Recognition.',
        icon: Icons.record_voice_over_rounded,
        color: Color(0xFF0891B2),
      ),
      AppPermissionType.activityRecognition => const AppPermissionMeta(
        title: 'Physical Activity',
        rationale: 'Activity access lets us track steps and fitness data for health features.',
        deniedMessage: 'Activity recognition access is required. Enable it in Settings → Privacy → Motion & Fitness.',
        icon: Icons.directions_run_rounded,
        color: Color(0xFF16A34A),
      ),
      AppPermissionType.appTracking => const AppPermissionMeta(
        title: 'Personalized Ads',
        rationale: 'Allow tracking to see ads that are more relevant to your interests. You can change this at any time.',
        deniedMessage: 'Tracking is disabled. You can change this in Settings → Privacy → Tracking.',
        icon: Icons.ads_click_rounded,
        color: Color(0xFF64748B),
      ),
      AppPermissionType.nearbyWifi => const AppPermissionMeta(
        title: 'Nearby Wi-Fi Devices',
        rationale: 'Wi-Fi scan access is needed to discover and connect to nearby devices.',
        deniedMessage: 'Nearby Wi-Fi access is required. Enable it in Settings → Apps → Permissions.',
        icon: Icons.wifi_tethering_rounded,
        color: Color(0xFF0891B2),
      ),
      AppPermissionType.manageExternalStorage => const AppPermissionMeta(
        title: 'Manage All Files',
        rationale: 'Full file management access lets you import and export any file on your device.',
        deniedMessage: 'File management access requires granting "All Files Access" in Settings → Privacy.',
        icon: Icons.folder_open_rounded,
        color: Color(0xFFD97706),
      ),
    };
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────────

  /// Returns true if the user wants to proceed with granting permission.
  static Future<bool> _showRationaleDialog(
    BuildContext context,
    AppPermissionType type,
    AppPermissionMeta meta, {
    Widget Function(BuildContext context, AppPermissionMeta meta, VoidCallback onAllow, VoidCallback onCancel)? rationaleDialogBuilder,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => rationaleDialogBuilder != null
          ? rationaleDialogBuilder(
              ctx,
              meta,
              () => Navigator.pop(ctx, true),
              () => Navigator.pop(ctx, false),
            )
          : _PermissionRationaleDialog(meta: meta, type: type),
    );
    return result ?? false;
  }

  /// Batched rationale for multiple permissions.
  static Future<bool> _showBatchedRationaleDialog(
    BuildContext context,
    List<AppPermissionType> types,
    List<AppPermissionMeta> metas, {
    Widget Function(BuildContext context, List<AppPermissionType> types, List<AppPermissionMeta> metas, VoidCallback onContinue, VoidCallback onCancel)? batchedRationaleDialogBuilder,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => batchedRationaleDialogBuilder != null
          ? batchedRationaleDialogBuilder(
              ctx,
              types,
              metas,
              () => Navigator.pop(ctx, true),
              () => Navigator.pop(ctx, false),
            )
          : _BatchPermissionDialog(types: types, metas: metas),
    );
    return result ?? false;
  }

  /// Settings redirect shown when permission is permanently denied.
  static Future<void> _showSettingsDialog(
    BuildContext context,
    AppPermissionType type,
    AppPermissionMeta meta, {
    Widget Function(BuildContext context, AppPermissionMeta meta, VoidCallback onOpenSettings, VoidCallback onCancel)? settingsDialogBuilder,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => settingsDialogBuilder != null
          ? settingsDialogBuilder(
              ctx,
              meta,
              () async {
                Navigator.pop(ctx);
                await openAppSettings();
              },
              () => Navigator.pop(ctx),
            )
          : _PermissionSettingsDialog(meta: meta),
    );
  }
}

// ─── Rationale Dialog ─────────────────────────────────────────────────────────

class _PermissionRationaleDialog extends StatelessWidget {
  final AppPermissionMeta meta;
  final AppPermissionType type;

  const _PermissionRationaleDialog({required this.meta, required this.type});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon circle
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: meta.color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(meta.icon, color: meta.color, size: 30),
            )
                .animate()
                .scale(begin: const Offset(0.6, 0.6), duration: 300.ms, curve: Curves.easeOutBack),

            const SizedBox(height: AppSpacing.md),

            Text(
              meta.title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.sm),

            Text(
              meta.rationale,
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.lg),

            Row(
              children: [
                Expanded(
                  child: AppButton.outlined(
                    label: 'Not Now',
                    onPressed: () => Navigator.pop(context, false),
                    size: AppButtonSize.md,
                    isFullWidth: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppButton.filled(
                    label: 'Allow',
                    onPressed: () => Navigator.pop(context, true),
                    backgroundColor: meta.color,
                    size: AppButtonSize.md,
                    isFullWidth: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Batch Rationale Dialog ───────────────────────────────────────────────────

class _BatchPermissionDialog extends StatelessWidget {
  final List<AppPermissionType> types;
  final List<AppPermissionMeta> metas;

  const _BatchPermissionDialog({required this.types, required this.metas});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Permissions Required',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'This feature needs the following permissions to work correctly:',
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),

            ...metas.asMap().entries.map((e) {
              final i = e.key;
              final m = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: m.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(m.icon, color: m.color, size: 18),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          Text(m.rationale, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                )
                    .animate(delay: Duration(milliseconds: 60 * i))
                    .fadeIn(duration: 200.ms)
                    .slideX(begin: 0.05),
              );
            }),

            const SizedBox(height: AppSpacing.lg),

            Row(
              children: [
                Expanded(
                  child: AppButton.outlined(
                    label: 'Cancel',
                    onPressed: () => Navigator.pop(context, false),
                    size: AppButtonSize.md,
                    isFullWidth: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppButton.filled(
                    label: 'Continue',
                    onPressed: () => Navigator.pop(context, true),
                    size: AppButtonSize.md,
                    isFullWidth: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Settings Redirect Dialog ─────────────────────────────────────────────────

class _PermissionSettingsDialog extends StatelessWidget {
  final AppPermissionMeta meta;
  const _PermissionSettingsDialog({required this.meta});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: cs.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_rounded, color: cs.error, size: 26),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '${meta.title} Blocked',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              meta.deniedMessage,
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton.filled(
              icon: const Icon(Icons.settings_rounded, size: 18),
              label: 'Open Settings',
              onPressed: () async {
                Navigator.pop(context);
                await openAppSettings();
              },
              size: AppButtonSize.md,
              isFullWidth: true,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton.text(
              label: 'Not Now',
              onPressed: () => Navigator.pop(context),
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── AppPermissionTile ────────────────────────────────────────────────────────
/// Ready-made UI widget showing a permission with its current status + request button.
/// Drop this into any settings or onboarding screen.
class AppPermissionTile extends StatefulWidget {
  final AppPermissionType type;
  final VoidCallback? onGranted;
  final String? location;
  final String? useCase;
  final Map<String, String>? variables;
  final AppPermissionMeta? metaOverride;
  final Widget Function(BuildContext context, AppPermissionMeta meta, VoidCallback onAllow, VoidCallback onCancel)? rationaleDialogBuilder;
  final Widget Function(BuildContext context, AppPermissionMeta meta, VoidCallback onOpenSettings, VoidCallback onCancel)? settingsDialogBuilder;

  const AppPermissionTile({
    super.key,
    required this.type,
    this.onGranted,
    this.location,
    this.useCase,
    this.variables,
    this.metaOverride,
    this.rationaleDialogBuilder,
    this.settingsDialogBuilder,
  });

  @override
  State<AppPermissionTile> createState() => _AppPermissionTileState();
}

class _AppPermissionTileState extends State<AppPermissionTile> {
  AppPermissionStatus? _status;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final result = await AppPermissionManager.check(
      widget.type,
      location: widget.location,
      useCase: widget.useCase,
      variables: widget.variables,
      metaOverride: widget.metaOverride,
    );
    if (mounted) setState(() => _status = result.status);
  }

  Future<void> _request() async {
    setState(() => _loading = true);
    final result = await AppPermissionManager.request(
      context,
      widget.type,
      location: widget.location,
      useCase: widget.useCase,
      variables: widget.variables,
      metaOverride: widget.metaOverride,
      rationaleDialogBuilder: widget.rationaleDialogBuilder,
      settingsDialogBuilder: widget.settingsDialogBuilder,
    );
    if (mounted) {
      setState(() {
        _status = result.status;
        _loading = false;
      });
      if (result.isGranted) widget.onGranted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final meta = AppPermissionManager.resolveMeta(
      widget.type,
      location: widget.location,
      useCase: widget.useCase,
      variables: widget.variables,
      metaOverride: widget.metaOverride,
    );
    final status = _status;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case AppPermissionStatus.granted:
        statusColor = const Color(0xFF16A34A);
        statusLabel = 'Granted';
        statusIcon = Icons.check_circle_rounded;
      case AppPermissionStatus.limited:
        statusColor = const Color(0xFFD97706);
        statusLabel = 'Limited';
        statusIcon = Icons.info_rounded;
      case AppPermissionStatus.denied:
        statusColor = cs.error;
        statusLabel = 'Denied';
        statusIcon = Icons.cancel_rounded;
      case AppPermissionStatus.permanentlyDenied:
        statusColor = cs.error;
        statusLabel = 'Blocked';
        statusIcon = Icons.block_rounded;
      case AppPermissionStatus.restricted:
        statusColor = cs.onSurfaceVariant;
        statusLabel = 'Restricted';
        statusIcon = Icons.lock_rounded;
      case AppPermissionStatus.notApplicable:
        statusColor = cs.onSurfaceVariant;
        statusLabel = 'N/A';
        statusIcon = Icons.remove_circle_outline_rounded;
      case null:
        statusColor = cs.onSurfaceVariant;
        statusLabel = 'Checking…';
        statusIcon = Icons.hourglass_empty_rounded;
    }

    final isGranted = status == AppPermissionStatus.granted || status == AppPermissionStatus.limited;
    final isNA = status == AppPermissionStatus.notApplicable;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isGranted
            ? const Color(0xFF16A34A).withOpacity(0.06)
            : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isGranted
              ? const Color(0xFF16A34A).withOpacity(0.3)
              : cs.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          // Permission icon
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: meta.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(meta.icon, color: meta.color, size: 20),
          ),
          const SizedBox(width: 12),
          // Labels
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meta.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(statusLabel, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          // Action
          if (!isGranted && !isNA)
            _loading
                ? SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: meta.color),
                  )
                : AppButton(
                    variant: AppButtonVariant.text,
                    label: status == AppPermissionStatus.permanentlyDenied ? 'Settings' : 'Allow',
                    onPressed: status == AppPermissionStatus.permanentlyDenied
                        ? () async {
                            await AppPermissionManager.openSettings();
                            await _checkStatus();
                          }
                        : _request,
                    foregroundColor: meta.color,
                    isFullWidth: false,
                    size: AppButtonSize.sm,
                  ),
        ],
      ),
    );
  }
}
