// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

// ─── Asset Type ───────────────────────────────────────────────────────────────
enum AppAssetType { image, video, pdf, svg, file, unknown }

class AppAssetSource {
  final String url;
  final String? localPath;
  final AppAssetType type;
  final String? caption;
  final String? heroTag;
  final String? thumbnail;

  const AppAssetSource({
    required this.url,
    this.localPath,
    AppAssetType? type,
    this.caption,
    this.heroTag,
    this.thumbnail,
  }) : type = type ?? AppAssetType.unknown;

  factory AppAssetSource.image(String url, {String? caption, String? heroTag}) =>
      AppAssetSource(url: url, type: AppAssetType.image, caption: caption, heroTag: heroTag);

  factory AppAssetSource.video(String url, {String? thumbnail, String? caption}) =>
      AppAssetSource(url: url, type: AppAssetType.video, thumbnail: thumbnail, caption: caption);

  factory AppAssetSource.file(String url, {String? caption}) =>
      AppAssetSource(url: url, type: AppAssetType.file, caption: caption);

  static AppAssetType detectType(String url) {
    final lower = url.toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.svg'].any(lower.endsWith)) {
      return lower.endsWith('.svg') ? AppAssetType.svg : AppAssetType.image;
    }
    if (['.mp4', '.mov', '.avi', '.mkv', '.webm'].any(lower.endsWith)) return AppAssetType.video;
    if (lower.endsWith('.pdf')) return AppAssetType.pdf;
    return AppAssetType.file;
  }
}

// ─── App Asset Viewer ─────────────────────────────────────────────────────────
/// Single asset viewer with full controls
class AppAssetViewer extends StatelessWidget {
  final String url;
  final AppAssetType? type;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final bool enableFullscreen;
  final bool showControls;
  final String? heroTag;
  final String? caption;
  final bool cached;
  final VoidCallback? onTap;

  const AppAssetViewer({
    super.key,
    required this.url,
    this.type,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.enableFullscreen = true,
    this.showControls = false,
    this.heroTag,
    this.caption,
    this.cached = true,
    this.onTap,
  });

  AppAssetType get _effectiveType =>
      type ?? AppAssetSource.detectType(url);

  @override
  Widget build(BuildContext context) {
    Widget content = switch (_effectiveType) {
      AppAssetType.image || AppAssetType.svg => _ImageViewer(
          url: url,
          width: width,
          height: height,
          fit: fit,
          placeholder: placeholder,
          errorWidget: errorWidget,
          borderRadius: borderRadius,
          heroTag: heroTag,
          cached: cached,
        ),
      AppAssetType.video => _VideoViewer(
          url: url,
          width: width,
          height: height,
          thumbnail: null,
        ),
      _ => _FileViewer(url: url, width: width, height: height),
    };

    if (caption != null) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          content,
          const SizedBox(height: 6),
          Text(
            caption!,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      );
    }

    if (enableFullscreen && _effectiveType == AppAssetType.image) {
      return GestureDetector(
        onTap: onTap ?? () => _openFullscreen(context),
        child: content,
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }

    return content;
  }

  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AppAssetFullscreen(
          sources: [AppAssetSource.image(url, caption: caption, heroTag: heroTag)],
          initialIndex: 0,
        ),
      ),
    );
  }
}

// ─── Image Viewer ─────────────────────────────────────────────────────────────
class _ImageViewer extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final String? heroTag;
  final bool cached;

  const _ImageViewer({
    required this.url,
    this.width,
    this.height,
    required this.fit,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.heroTag,
    required this.cached,
  });

  bool get _isNetwork => url.startsWith('http');
  bool get _isAsset => url.startsWith('assets/') || url.startsWith('asset://');

  Widget _buildImage() {
    if (_isNetwork && cached) {
      return CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (ctx, _) =>
            placeholder ??
            Container(
              width: width,
              height: height,
              color: Theme.of(ctx).colorScheme.surfaceVariant,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        errorWidget: (ctx, _, __) =>
            errorWidget ?? _ErrorPlaceholder(width: width, height: height),
      );
    }
    if (_isNetwork) {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) =>
            errorWidget ?? _ErrorPlaceholder(width: width, height: height),
      );
    }
    if (_isAsset) {
      return Image.asset(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) =>
            errorWidget ?? _ErrorPlaceholder(width: width, height: height),
      );
    }
    return Image.file(
      File(url),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) =>
          errorWidget ?? _ErrorPlaceholder(width: width, height: height),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget image = _buildImage();

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    if (heroTag != null) {
      image = Hero(tag: heroTag!, child: image);
    }

    return image.animate().fadeIn(duration: 300.ms);
  }
}

// ─── Video Viewer ─────────────────────────────────────────────────────────────
class _VideoViewer extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final String? thumbnail;

  const _VideoViewer({required this.url, this.width, this.height, this.thumbnail});

  @override
  State<_VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<_VideoViewer> {
  VideoPlayerController? _vCtrl;
  ChewieController? _chewieCtrl;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final url = widget.url;
    _vCtrl = url.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(url))
        : VideoPlayerController.file(File(url));
    await _vCtrl!.initialize();
    _chewieCtrl = ChewieController(
      videoPlayerController: _vCtrl!,
      autoPlay: false,
      looping: false,
      aspectRatio: _vCtrl!.value.aspectRatio,
    );
    if (mounted) setState(() => _initialized = true);
  }

  @override
  void dispose() {
    _chewieCtrl?.dispose();
    _vCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Container(
        width: widget.width,
        height: widget.height ?? 200,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Chewie(controller: _chewieCtrl!),
    );
  }
}

// ─── File Viewer ──────────────────────────────────────────────────────────────
class _FileViewer extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;

  const _FileViewer({required this.url, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ext = url.split('.').last.toUpperCase();

    return Container(
      width: width ?? double.infinity,
      height: height ?? 100,
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_drive_file_outlined, size: 40, color: cs.primary),
          const SizedBox(height: 8),
          Text(ext, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.primary)),
        ],
      ),
    );
  }
}

// ─── Error Placeholder ────────────────────────────────────────────────────────
class _ErrorPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;

  const _ErrorPlaceholder({this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined,
              color: Theme.of(context).colorScheme.error, size: 32),
          const SizedBox(height: 4),
          Text('Failed to load',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Theme.of(context).colorScheme.error)),
        ],
      ),
    );
  }
}

// ─── Fullscreen Gallery Viewer ────────────────────────────────────────────────
class AppAssetFullscreen extends StatefulWidget {
  final List<AppAssetSource> sources;
  final int initialIndex;
  final bool showThumbnails;
  final bool showControls;

  const AppAssetFullscreen({
    super.key,
    required this.sources,
    this.initialIndex = 0,
    this.showThumbnails = true,
    this.showControls = true,
  });

  @override
  State<AppAssetFullscreen> createState() => _AppAssetFullscreenState();
}

class _AppAssetFullscreenState extends State<AppAssetFullscreen> {
  late int _current;
  late PageController _pageCtrl;
  bool _showOverlay = true;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Gallery
          GestureDetector(
            onTap: () => setState(() => _showOverlay = !_showOverlay),
            child: PhotoViewGallery.builder(
              pageController: _pageCtrl,
              itemCount: widget.sources.length,
              onPageChanged: (i) => setState(() => _current = i),
              builder: (ctx, i) {
                final source = widget.sources[i];
                return PhotoViewGalleryPageOptions(
                  imageProvider: source.url.startsWith('http')
                      ? CachedNetworkImageProvider(source.url)
                      : FileImage(File(source.url)) as ImageProvider,
                  heroAttributes: source.heroTag != null
                      ? PhotoViewHeroAttributes(tag: source.heroTag!)
                      : null,
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 3,
                );
              },
              loadingBuilder: (_, __) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),

          // Top overlay
          AnimatedOpacity(
            opacity: _showOverlay ? 1 : 0,
            duration: 200.ms,
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  if (widget.sources.length > 1)
                    Text(
                      '${_current + 1} / ${widget.sources.length}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),

          // Bottom caption + thumbnails
          if (_showOverlay)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Caption
                    if (widget.sources[_current].caption != null)
                      Text(
                        widget.sources[_current].caption!,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    if (widget.showThumbnails && widget.sources.length > 1) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 56,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          shrinkWrap: true,
                          itemCount: widget.sources.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (ctx, i) {
                            final isSelected = i == _current;
                            return GestureDetector(
                              onTap: () => _pageCtrl.animateToPage(
                                i,
                                duration: 300.ms,
                                curve: Curves.easeInOut,
                              ),
                              child: AnimatedContainer(
                                duration: 200.ms,
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? Colors.white : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: CachedNetworkImage(
                                    imageUrl: widget.sources[i].thumbnail ?? widget.sources[i].url,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ).animate().fadeIn(),
        ],
      ),
    );
  }
}

// ─── Cached Image Manager ─────────────────────────────────────────────────────
class AppImageCache {
  static void clearAll() => PaintingBinding.instance.imageCache.clear();
  static void clearUrl(String url) =>
      PaintingBinding.instance.imageCache.evict(NetworkImage(url));
  static int get size => PaintingBinding.instance.imageCache.currentSize;
  static int get sizeBytes => PaintingBinding.instance.imageCache.currentSizeBytes;
  static void setMaxSize(int count) =>
      PaintingBinding.instance.imageCache.maximumSize = count;
  static void setMaxSizeBytes(int bytes) =>
      PaintingBinding.instance.imageCache.maximumSizeBytes = bytes;
}

// ─── Avatar Viewer ────────────────────────────────────────────────────────────
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final String? heroTag;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 40,
    this.borderRadius,
    this.backgroundColor,
    this.heroTag,
  });

  String get _initials {
    if (name == null || name!.isEmpty) return '?';
    final parts = name!.trim().split(' ');
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = borderRadius ?? BorderRadius.circular(size / 2);

    Widget child;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      child = ClipRRect(
        borderRadius: radius,
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _placeholder(cs),
          errorWidget: (_, __, ___) => _placeholder(cs),
        ),
      );
    } else {
      child = _placeholder(cs);
    }

    if (heroTag != null) {
      child = Hero(tag: heroTag!, child: child);
    }

    return child;
  }

  Widget _placeholder(ColorScheme cs) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? cs.primaryContainer,
        borderRadius: borderRadius ?? BorderRadius.circular(size / 2),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: cs.onPrimaryContainer,
        ),
      ),
    );
  }
}
