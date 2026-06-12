// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:enterprise_kit/core/permissions/app_permission_manager.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';
import 'package:enterprise_kit/shared/widgets/buttons/app_button.dart';
import 'package:enterprise_kit/shared/widgets/sheets/app_sheet.dart';

// ─── Enums & Models ───────────────────────────────────────────────────────────

enum AppMediaSource {
  camera('Camera', Icons.camera_alt_rounded),
  gallery('Gallery', Icons.photo_library_rounded),
  file('Files', Icons.folder_open_rounded);

  final String label;
  final IconData icon;
  const AppMediaSource(this.label, this.icon);
}

/// Unified file payload returned by AppMediaPicker.
class AppMediaFile {
  final String path;
  final String name;
  final int sizeInBytes;
  final String extension;
  final List<int>? bytes;
  final bool isImage;
  final bool isVideo;

  const AppMediaFile({
    required this.path,
    required this.name,
    required this.sizeInBytes,
    required this.extension,
    this.bytes,
    this.isImage = false,
    this.isVideo = false,
  });

  double get sizeInMb => sizeInBytes / (1024 * 1024);

  @override
  String toString() =>
      'AppMediaFile($name, ${sizeInMb.toStringAsFixed(2)} MB, .$extension)';
}

// ─── Picker Config ────────────────────────────────────────────────────────────

class AppMediaPickerConfig {
  final List<AppMediaSource> sources;
  final int limit;
  final List<String>? allowedExtensions;
  final double? maxSizeInMb;
  final ImageQuality imageQuality;
  final bool allowMultiple;
  final String? title;
  final String? subtitle;

  // New configuration options from giant app research
  final CameraDevice preferredCameraDevice;
  final String? dialogTitle;
  final String? initialDirectory;
  final FileType type;
  final void Function(FilePickerStatus)? onFileLoading;
  final int compressionQuality;
  final bool withData;
  final bool withReadStream;
  final bool lockParentWindow;
  final bool readSequential;
  final bool cancelUploadOnWindowBlur;

  const AppMediaPickerConfig({
    this.sources = const [AppMediaSource.gallery],
    this.limit = 1,
    this.allowedExtensions,
    this.maxSizeInMb,
    this.imageQuality = ImageQuality.medium,
    this.allowMultiple = false,
    this.title,
    this.subtitle,
    this.preferredCameraDevice = CameraDevice.rear,
    this.dialogTitle,
    this.initialDirectory,
    this.type = FileType.any,
    this.onFileLoading,
    this.compressionQuality = 0,
    this.withData = false,
    this.withReadStream = false,
    this.lockParentWindow = false,
    this.readSequential = false,
    this.cancelUploadOnWindowBlur = true,
  });
}

// ─── AppMediaPicker ───────────────────────────────────────────────────────────
/// Universal smart media picker — Zomato/Telegram/Instagram-grade UX.
///
/// - Single source → launches directly (no bottom sheet)
/// - Multiple sources → shows glassmorphic source selector sheet
/// - Permission denied → shows settings redirect dialog
/// - Validates size + extension constraints before returning
class AppMediaPicker {
  AppMediaPicker._();

  static final _picker = ImagePicker();

  /// Primary entry point. Call from any widget's callback.
  static Future<List<AppMediaFile>> pick(
    BuildContext context, {
    List<AppMediaSource> sources = const [AppMediaSource.gallery],
    int limit = 1,
    List<String>? allowedExtensions,
    double? maxSizeInMb,
    ImageQuality imageQuality = ImageQuality.medium,
    String? title,
    String? subtitle,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    void Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = true,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
    bool cancelUploadOnWindowBlur = true,
  }) async {
    final config = AppMediaPickerConfig(
      sources: sources,
      limit: limit,
      allowedExtensions: allowedExtensions,
      maxSizeInMb: maxSizeInMb,
      imageQuality: imageQuality,
      allowMultiple: allowMultiple || limit > 1,
      title: title,
      subtitle: subtitle,
      preferredCameraDevice: preferredCameraDevice,
      dialogTitle: dialogTitle,
      initialDirectory: initialDirectory,
      type: type,
      onFileLoading: onFileLoading,
      compressionQuality: compressionQuality,
      withData: withData,
      withReadStream: withReadStream,
      lockParentWindow: lockParentWindow,
      readSequential: readSequential,
      cancelUploadOnWindowBlur: cancelUploadOnWindowBlur,
    );

    // Single source → skip sheet
    if (sources.length == 1) {
      return _executeSource(context, sources.first, config);
    }

    // Multiple → show selection sheet
    if (!context.mounted) return [];
    final chosen = await _showSourceSheet(context, config);
    if (chosen == null) return [];
    return _executeSource(context, chosen, config);
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  static Future<List<AppMediaFile>> _executeSource(
    BuildContext context,
    AppMediaSource source,
    AppMediaPickerConfig config,
  ) async {
    final hasPermission = await _checkPermission(context, source);
    if (!hasPermission) return [];

    try {
      return switch (source) {
        AppMediaSource.camera   => _pickFromCamera(config),
        AppMediaSource.gallery  => _pickFromGallery(config),
        AppMediaSource.file     => _pickFromFiles(context, config),
      };
    } catch (e) {
      debugPrint('[AppMediaPicker] Error: $e');
      return [];
    }
  }

  static Future<List<AppMediaFile>> _pickFromCamera(AppMediaPickerConfig cfg) async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: cfg.compressionQuality > 0 ? cfg.compressionQuality : cfg.imageQuality.value,
      preferredCameraDevice: cfg.preferredCameraDevice,
    );
    if (file == null) return [];
    return [await _toMediaFile(file)];
  }

  static Future<List<AppMediaFile>> _pickFromGallery(AppMediaPickerConfig cfg) async {
    final int quality = cfg.compressionQuality > 0 ? cfg.compressionQuality : cfg.imageQuality.value;
    if (cfg.allowMultiple) {
      final files = await _picker.pickMultiImage(
        imageQuality: quality,
        limit: cfg.limit,
      );
      final result = await Future.wait(files.map(_toMediaFile));
      return _validate(result, cfg);
    } else {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: quality,
        preferredCameraDevice: cfg.preferredCameraDevice,
      );
      if (file == null) return [];
      final media = await _toMediaFile(file);
      return _validate([media], cfg);
    }
  }

  static Future<List<AppMediaFile>> _pickFromFiles(
    BuildContext context,
    AppMediaPickerConfig cfg,
  ) async {
    final result = await FilePicker.pickFiles(
      allowMultiple: cfg.allowMultiple,
      type: cfg.allowedExtensions != null ? FileType.custom : cfg.type,
      allowedExtensions: cfg.allowedExtensions,
      dialogTitle: cfg.dialogTitle,
      initialDirectory: cfg.initialDirectory,
      onFileLoading: cfg.onFileLoading,
      withData: cfg.withData,
      withReadStream: cfg.withReadStream,
      lockParentWindow: cfg.lockParentWindow,
      readSequential: cfg.readSequential,
    );
    if (result == null) return [];
    final files = result.files.map((f) => AppMediaFile(
      path: f.path ?? '',
      name: f.name,
      sizeInBytes: f.size,
      extension: f.extension ?? '',
      bytes: f.bytes?.toList(),
      isImage: _isImageExt(f.extension ?? ''),
    )).toList();
    return _validate(files, cfg);
  }

  static List<AppMediaFile> _validate(List<AppMediaFile> files, AppMediaPickerConfig cfg) {
    final valid = <AppMediaFile>[];
    for (final f in files) {
      if (cfg.maxSizeInMb != null && f.sizeInMb > cfg.maxSizeInMb!) {
        debugPrint('[AppMediaPicker] File ${f.name} (${f.sizeInMb.toStringAsFixed(1)} MB) exceeds limit');
        continue;
      }
      if (cfg.allowedExtensions != null &&
          !cfg.allowedExtensions!.map((e) => e.toLowerCase()).contains(f.extension.toLowerCase())) {
        debugPrint('[AppMediaPicker] File ${f.name} has disallowed extension');
        continue;
      }
      valid.add(f);
    }
    return valid.take(cfg.limit).toList();
  }

  static Future<AppMediaFile> _toMediaFile(XFile file) async {
    final bytes = await file.readAsBytes();
    final name = file.name.isNotEmpty ? file.name : file.path.split('/').last;
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return AppMediaFile(
      path: file.path,
      name: name,
      sizeInBytes: bytes.length,
      extension: ext,
      bytes: bytes.toList(),
      isImage: _isImageExt(ext),
      isVideo: _isVideoExt(ext),
    );
  }

  // ── Permissions ──────────────────────────────────────────────────────────
  // Delegates entirely to AppPermissionManager for correct platform/version handling.

  static Future<bool> _checkPermission(BuildContext ctx, AppMediaSource src) async {
    final permType = switch (src) {
      AppMediaSource.camera  => AppPermissionType.camera,
      AppMediaSource.gallery => AppPermissionType.photoLibrary,
      AppMediaSource.file    => null,
    };
    if (permType == null) return true;

    final result = await AppPermissionManager.request(ctx, permType);
    return result.isGranted;
  }

  // ── Source Selector Sheet ─────────────────────────────────────────────────

  static Future<AppMediaSource?> _showSourceSheet(
    BuildContext context,
    AppMediaPickerConfig cfg,
  ) async {
    return AppSheet.show<AppMediaSource>(
      context,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      padding: EdgeInsets.zero,
      child: _SourceSelectorSheet(config: cfg),
    );
  }

  // ── Utils ─────────────────────────────────────────────────────────────────

  static bool _isImageExt(String ext) =>
      ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'].contains(ext.toLowerCase());

  static bool _isVideoExt(String ext) =>
      ['mp4', 'mov', 'avi', 'mkv', 'webm', 'm4v'].contains(ext.toLowerCase());
}

// ─── ImageQuality Extension ───────────────────────────────────────────────────
enum ImageQuality {
  low(40),
  medium(70),
  high(90),
  original(100);

  final int value;
  const ImageQuality(this.value);
}

// ─── Source Selector Sheet ────────────────────────────────────────────────────
class _SourceSelectorSheet extends StatelessWidget {
  final AppMediaPickerConfig config;
  const _SourceSelectorSheet({required this.config});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Grab handle
                  Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          config.title ?? 'Select Source',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (config.subtitle != null)
                          Text(
                            config.subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Source buttons
                  ...config.sources.asMap().entries.map((e) {
                    final src = e.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SourceTile(source: src)
                          .animate(delay: Duration(milliseconds: 50 * e.key))
                          .fadeIn(duration: 250.ms)
                          .slideY(begin: 0.1, duration: 250.ms),
                    );
                  }),

                  const SizedBox(height: 4),

                  // Cancel
                  AppButton.text(
                    label: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                    size: AppButtonSize.md,
                    isFullWidth: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SourceTile extends StatefulWidget {
  final AppMediaSource source;
  const _SourceTile({required this.source});

  @override
  State<_SourceTile> createState() => _SourceTileState();
}

class _SourceTileState extends State<_SourceTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static const _sourceColors = {
    AppMediaSource.camera:  Color(0xFFDC2626),
    AppMediaSource.gallery: Color(0xFF7C3AED),
    AppMediaSource.file:    Color(0xFF2563EB),
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _sourceColors[widget.source] ?? cs.primary;

    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) => _ctrl.forward(),
      onTapCancel: () => _ctrl.forward(),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context, widget.source);
      },
      child: ScaleTransition(
        scale: _ctrl,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.source.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.source.label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      _subtitle(widget.source),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(AppMediaSource src) => switch (src) {
    AppMediaSource.camera   => 'Take a new photo or video',
    AppMediaSource.gallery  => 'Choose from your photos',
    AppMediaSource.file     => 'Browse device storage',
  };
}

// ─── AppMediaFilePreview ──────────────────────────────────────────────────────
/// Thumbnail preview for a picked AppMediaFile.
class AppMediaFilePreview extends StatelessWidget {
  final AppMediaFile file;
  final VoidCallback? onRemove;
  final double size;

  const AppMediaFilePreview({
    super.key,
    required this.file,
    this.onRemove,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: cs.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: file.isImage && file.path.isNotEmpty
              ? Image.file(File(file.path), fit: BoxFit.cover)
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        file.isVideo ? Icons.video_file_rounded : Icons.insert_drive_file_rounded,
                        size: 28,
                        color: cs.primary,
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '.${file.extension.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),

        // Size badge
        Positioned(
          bottom: 4, left: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${file.sizeInMb.toStringAsFixed(1)}M',
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
            ),
          ),
        ),

        // Remove button
        if (onRemove != null)
          Positioned(
            top: -6, right: -6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: cs.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.surface, width: 1.5),
                ),
                child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── AppMediaPickerField ──────────────────────────────────────────────────────
/// Drop-in form field widget that wraps AppMediaPicker with thumbnail grid.
class AppMediaPickerField extends StatefulWidget {
  final List<AppMediaSource> sources;
  final int limit;
  final List<String>? allowedExtensions;
  final double? maxSizeInMb;
  final String label;
  final String? hint;
  final ValueChanged<List<AppMediaFile>>? onChanged;

  const AppMediaPickerField({
    super.key,
    this.sources = const [AppMediaSource.gallery, AppMediaSource.camera],
    this.limit = 5,
    this.allowedExtensions,
    this.maxSizeInMb,
    this.label = 'Attachments',
    this.hint,
    this.onChanged,
  });

  @override
  State<AppMediaPickerField> createState() => _AppMediaPickerFieldState();
}

class _AppMediaPickerFieldState extends State<AppMediaPickerField> {
  final _files = <AppMediaFile>[];

  Future<void> _pick() async {
    final remaining = widget.limit - _files.length;
    if (remaining <= 0) return;

    final results = await AppMediaPicker.pick(
      context,
      sources: widget.sources,
      limit: remaining,
      allowedExtensions: widget.allowedExtensions,
      maxSizeInMb: widget.maxSizeInMb,
    );
    if (results.isNotEmpty) {
      setState(() => _files.addAll(results));
      widget.onChanged?.call(_files);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(
                widget.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              if (widget.limit > 1) ...[
                const SizedBox(width: 6),
                Text(
                  '${_files.length}/${widget.limit}',
                  style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),

        // Thumbnails + add button
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ..._files.asMap().entries.map((e) => AppMediaFilePreview(
              file: e.value,
              onRemove: () {
                setState(() => _files.removeAt(e.key));
                widget.onChanged?.call(_files);
              },
            ).animate().scale(begin: const Offset(0.7, 0.7), duration: 250.ms, curve: Curves.elasticOut).fadeIn()),
            if (_files.length < widget.limit)
              GestureDetector(
                onTap: _pick,
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: cs.primary.withOpacity(0.3), width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, size: 26, color: cs.primary),
                      Text(
                        'Add',
                        style: TextStyle(fontSize: 11, color: cs.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        if (widget.hint != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.hint!,
            style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
