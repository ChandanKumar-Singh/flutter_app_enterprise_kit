import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ─── Source Types ──────────────────────────────────────────────────────────────
enum AppImageSource { network, asset, svg, svgNetwork, file, memory }

// ─── Fit / Shape ──────────────────────────────────────────────────────────────
enum AppImageShape { none, circle, rounded, rectangle }

class AppImage extends StatelessWidget {
  final AppImageSource source;
  final String? url;
  final String? assetPath;
  final File? file;
  final Uint8List? bytes;
  final double? width;
  final double? height;
  final BoxFit fit;
  final AppImageShape shape;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? errorColor;
  final Widget? placeholder;
  final Widget? errorWidget;
  final String? heroTag;
  final VoidCallback? onTap;
  final bool enableFullScreen;

  const AppImage({
    super.key,
    required this.source,
    this.url,
    this.assetPath,
    this.file,
    this.bytes,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.shape = AppImageShape.none,
    this.borderRadius = 8,
    this.backgroundColor,
    this.errorColor,
    this.placeholder,
    this.errorWidget,
    this.heroTag,
    this.onTap,
    this.enableFullScreen = false,
  });

  // ── Factory constructors ───────────────────────────────────────────────────

  factory AppImage.network(
    String url, {
    Key? key,
    double? width, double? height,
    BoxFit fit = BoxFit.cover,
    AppImageShape shape = AppImageShape.none,
    double borderRadius = 8,
    String? heroTag,
    bool enableFullScreen = false,
    Widget? placeholder,
    Widget? errorWidget,
  }) => AppImage(key: key, source: AppImageSource.network, url: url,
      width: width, height: height, fit: fit, shape: shape,
      borderRadius: borderRadius, heroTag: heroTag,
      enableFullScreen: enableFullScreen, placeholder: placeholder,
      errorWidget: errorWidget);

  factory AppImage.asset(
    String assetPath, {
    Key? key,
    double? width, double? height,
    BoxFit fit = BoxFit.cover,
    AppImageShape shape = AppImageShape.none,
    double borderRadius = 8,
  }) => AppImage(key: key, source: AppImageSource.asset, assetPath: assetPath,
      width: width, height: height, fit: fit, shape: shape,
      borderRadius: borderRadius);

  factory AppImage.svg(
    String assetPath, {
    Key? key,
    double? width, double? height,
    Color? color,
  }) => AppImage(key: key, source: AppImageSource.svg, assetPath: assetPath,
      width: width, height: height, errorColor: color);

  factory AppImage.svgNetwork(
    String url, {
    Key? key,
    double? width, double? height,
    Color? color,
  }) => AppImage(key: key, source: AppImageSource.svgNetwork, url: url,
      width: width, height: height, errorColor: color);

  factory AppImage.file(
    File file, {
    Key? key,
    double? width, double? height,
    BoxFit fit = BoxFit.cover,
    AppImageShape shape = AppImageShape.none,
    double borderRadius = 8,
  }) => AppImage(key: key, source: AppImageSource.file, file: file,
      width: width, height: height, fit: fit, shape: shape,
      borderRadius: borderRadius);

  factory AppImage.memory(
    Uint8List bytes, {
    Key? key,
    double? width, double? height,
    BoxFit fit = BoxFit.cover,
    AppImageShape shape = AppImageShape.none,
    double borderRadius = 8,
  }) => AppImage(key: key, source: AppImageSource.memory, bytes: bytes,
      width: width, height: height, fit: fit, shape: shape,
      borderRadius: borderRadius);

  // Note: Use AppAvatar widget directly for avatar use cases.

  @override
  Widget build(BuildContext context) {
    Widget image = _buildImage(context);
    image = _applyShape(image);
    if (heroTag != null) image = Hero(tag: heroTag!, child: image);
    if (enableFullScreen || onTap != null) {
      image = GestureDetector(
        onTap: onTap ?? (enableFullScreen ? () => _openFullScreen(context) : null),
        child: image,
      );
    }
    return image;
  }

  Widget _buildImage(BuildContext context) {
    return switch (source) {
      AppImageSource.network => _buildNetworkImage(),
      AppImageSource.asset => _buildAssetImage(),
      AppImageSource.svg => _buildSvgAsset(),
      AppImageSource.svgNetwork => _buildSvgNetwork(),
      AppImageSource.file => _buildFileImage(),
      AppImageSource.memory => _buildMemoryImage(),
    };
  }

  Widget _buildNetworkImage() {
    return CachedNetworkImage(
      imageUrl: url ?? '',
      width: width,
      height: height,
      fit: fit,
      placeholder: (ctx, _) => placeholder ?? _buildPlaceholder(),
      errorWidget: (ctx, _, __) => errorWidget ?? _buildError(),
    );
  }

  Widget _buildAssetImage() {
    return Image.asset(
      assetPath ?? '',
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => errorWidget ?? _buildError(),
    );
  }

  Widget _buildSvgAsset() {
    return SvgPicture.asset(
      assetPath ?? '',
      width: width,
      height: height,
      colorFilter: errorColor != null
          ? ColorFilter.mode(errorColor!, BlendMode.srcIn) : null,
    );
  }

  Widget _buildSvgNetwork() {
    return SvgPicture.network(
      url ?? '',
      width: width,
      height: height,
      placeholderBuilder: (_) => placeholder ?? _buildPlaceholder(),
    );
  }

  Widget _buildFileImage() {
    if (file == null) return _buildError();
    return Image.file(
      file!,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => errorWidget ?? _buildError(),
    );
  }

  Widget _buildMemoryImage() {
    if (bytes == null) return _buildError();
    return Image.memory(
      bytes!,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => errorWidget ?? _buildError(),
    );
  }

  Widget _applyShape(Widget image) {
    return switch (shape) {
      AppImageShape.circle => ClipOval(child: image),
      AppImageShape.rounded => ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: image),
      AppImageShape.rectangle => ClipRect(child: image),
      AppImageShape.none => image,
    };
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? Colors.grey.shade200,
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildError() {
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? Colors.grey.shade100,
      child: Center(
        child: Icon(Iconsax.gallery_slash,
            color: errorColor ?? Colors.grey.shade400,
            size: (width != null && height != null)
                ? (width! < height! ? width! * 0.4 : height! * 0.4) : 32),
      ),
    );
  }

  void _openFullScreen(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _FullScreenImageViewer(
        source: source,
        url: url,
        assetPath: assetPath,
        file: file,
        bytes: bytes,
        heroTag: heroTag,
      ),
    ));
  }
}

// ─── Full Screen Viewer ────────────────────────────────────────────────────────
class _FullScreenImageViewer extends StatelessWidget {
  final AppImageSource source;
  final String? url, assetPath;
  final File? file;
  final Uint8List? bytes;
  final String? heroTag;

  const _FullScreenImageViewer({
    required this.source, this.url, this.assetPath,
    this.file, this.bytes, this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider? provider;
    switch (source) {
      case AppImageSource.network:
        if (url != null) provider = NetworkImage(url!);
      case AppImageSource.asset:
        if (assetPath != null) provider = AssetImage(assetPath!);
      case AppImageSource.file:
        if (file != null) provider = FileImage(file!);
      case AppImageSource.memory:
        if (bytes != null) provider = MemoryImage(bytes!);
      default:
        break;
    }

    final Widget image = provider != null
        ? InteractiveViewer(
            child: Hero(
              tag: heroTag ?? url ?? assetPath ?? 'full_image',
              child: Image(image: provider, fit: BoxFit.contain),
            ),
          )
        : const Center(child: Icon(Iconsax.gallery_slash));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.close_circle, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(child: image),
    );
  }
}

// ─── Avatar Widget ─────────────────────────────────────────────────────────────
class AppAvatar extends StatelessWidget {
  final String? url;
  final double size;
  final String? fallbackText;
  final Color? backgroundColor;

  const AppAvatar({
    super.key,
    this.url,
    required this.size,
    this.fallbackText,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? colors.primaryContainer;

    return SizedBox(
      width: size,
      height: size,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: bg,
        backgroundImage: url != null ? CachedNetworkImageProvider(url!) : null,
        child: url == null && fallbackText != null
            ? Text(
                fallbackText!.isNotEmpty
                    ? fallbackText!.substring(0, fallbackText!.length > 2 ? 2 : fallbackText!.length).toUpperCase()
                    : '?',
                style: TextStyle(
                    color: colors.onPrimaryContainer,
                    fontSize: size * 0.35,
                    fontWeight: FontWeight.bold),
              )
            : null,
      ),
    );
  }
}

