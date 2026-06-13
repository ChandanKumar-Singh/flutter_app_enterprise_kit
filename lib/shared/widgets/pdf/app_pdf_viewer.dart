import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';
import 'package:enterprise_kit/shared/widgets/states/app_state_widget.dart';

enum AppPdfSource { network, asset, file, memory }

class AppPdfViewer extends StatefulWidget {
  final AppPdfSource source;
  final String? url;
  final String? assetPath;
  final String? filePath;
  final Uint8List? bytes;
  final String? title;
  final bool showAppBar;
  final bool showToolbar;
  final bool enableSearch;
  final bool enableBookmark;
  final bool canScroll;
  final int? initialPage;
  final void Function(int page, int totalPages)? onPageChanged;
  final void Function(PdfDocumentLoadedDetails)? onDocumentLoaded;
  final void Function(PdfDocumentLoadFailedDetails)? onDocumentLoadFailed;

  const AppPdfViewer({
    super.key,
    required this.source,
    this.url,
    this.assetPath,
    this.filePath,
    this.bytes,
    this.title,
    this.showAppBar = false,
    this.showToolbar = true,
    this.enableSearch = true,
    this.enableBookmark = false,
    this.canScroll = true,
    this.initialPage,
    this.onPageChanged,
    this.onDocumentLoaded,
    this.onDocumentLoadFailed,
  });

  // ── Factories ──────────────────────────────────────────────────────────────
  factory AppPdfViewer.network(
    String url, {
    String? title,
    bool showAppBar = false,
    bool showToolbar = true,
    bool enableSearch = true,
  }) => AppPdfViewer(
    source: AppPdfSource.network, url: url,
    title: title, showAppBar: showAppBar,
    showToolbar: showToolbar, enableSearch: enableSearch,
  );

  factory AppPdfViewer.asset(
    String assetPath, {
    String? title,
    bool showAppBar = false,
  }) => AppPdfViewer(
    source: AppPdfSource.asset, assetPath: assetPath,
    title: title, showAppBar: showAppBar,
  );

  factory AppPdfViewer.memory(
    Uint8List bytes, {
    String? title,
    bool showAppBar = false,
  }) => AppPdfViewer(
    source: AppPdfSource.memory, bytes: bytes,
    title: title, showAppBar: showAppBar,
  );

  // Open in full screen from a route
  static Future<void> openFullScreen(
    BuildContext context, {
    required AppPdfSource source,
    String? url,
    String? assetPath,
    Uint8List? bytes,
    String? title,
  }) {
    return Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AppPdfViewer(
        source: source, url: url, assetPath: assetPath, bytes: bytes,
        title: title, showAppBar: true, showToolbar: true,
        enableSearch: true, enableBookmark: true,
      ),
    ));
  }

  @override
  State<AppPdfViewer> createState() => _AppPdfViewerState();
}

class _AppPdfViewerState extends State<AppPdfViewer> {
  final PdfViewerController _controller = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfKey = GlobalKey();

  bool _isLoading = true;
  bool _hasError = false;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _showSearch = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget viewer = _buildViewer();

    if (widget.showToolbar && _totalPages > 0) {
      viewer = Column(
        children: [
          _buildToolbar(),
          Expanded(child: viewer),
        ],
      );
    }

    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title ?? 'PDF Viewer'),
          actions: [
            if (widget.enableSearch)
              IconButton(
                icon: Icon(_showSearch ? Iconsax.search_normal : Iconsax.search_normal),
                onPressed: () => setState(() => _showSearch = !_showSearch),
              ),
            if (_totalPages > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(child: Text('$_currentPage / $_totalPages',
                    style: const TextStyle(fontSize: 13))),
              ),
          ],
        ),
        body: viewer,
      );
    }

    return viewer;
  }

  Widget _buildViewer() {
    if (_hasError) {
      return AppStateWidget.error(
        message: 'Could not load PDF',
        onRetry: () => setState(() { _hasError = false; _isLoading = true; }),
      );
    }

    Widget pdf = _buildPdf();

    if (_isLoading) {
      return Stack(children: [
        pdf,
        const Center(child: CircularProgressIndicator()),
      ]);
    }

    return pdf;
  }

  Widget _buildPdf() {
    final initialPage = widget.initialPage != null
        ? widget.initialPage! - 1 : 0;

    return switch (widget.source) {
      AppPdfSource.network => SfPdfViewer.network(
          widget.url ?? '',
          key: _pdfKey,
          controller: _controller,
          initialPageNumber: initialPage,
          canShowScrollHead: widget.canScroll,
          canShowPaginationDialog: true,
          onDocumentLoaded: _onLoaded,
          onDocumentLoadFailed: _onLoadFailed,
          onPageChanged: _onPageChanged,
        ),
      AppPdfSource.asset => SfPdfViewer.asset(
          widget.assetPath ?? '',
          key: _pdfKey,
          controller: _controller,
          initialPageNumber: initialPage,
          onDocumentLoaded: _onLoaded,
          onDocumentLoadFailed: _onLoadFailed,
          onPageChanged: _onPageChanged,
        ),
      AppPdfSource.memory => SfPdfViewer.memory(
          widget.bytes ?? Uint8List(0),
          key: _pdfKey,
          controller: _controller,
          initialPageNumber: initialPage,
          onDocumentLoaded: _onLoaded,
          onDocumentLoadFailed: _onLoadFailed,
          onPageChanged: _onPageChanged,
        ),
      AppPdfSource.file => SfPdfViewer.network(
          'file://${widget.filePath ?? ''}',
          key: _pdfKey,
          controller: _controller,
          onDocumentLoaded: _onLoaded,
          onDocumentLoadFailed: _onLoadFailed,
          onPageChanged: _onPageChanged,
        ),
    };
  }

  Widget _buildToolbar() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 48,
      color: colors.surfaceVariant,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Iconsax.arrow_left_1),
            onPressed: _currentPage > 1 ? () => _controller.jumpToPage(1) : null,
            tooltip: 'First page',
          ),
          IconButton(
            icon: const Icon(Iconsax.arrow_left_2),
            onPressed: _currentPage > 1 ? _controller.previousPage : null,
            tooltip: 'Previous',
          ),
          Expanded(
            child: Text('$_currentPage / $_totalPages',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          IconButton(
            icon: const Icon(Iconsax.arrow_right_3),
            onPressed: _currentPage < _totalPages
                ? _controller.nextPage : null,
            tooltip: 'Next',
          ),
          IconButton(
            icon: const Icon(Iconsax.arrow_right_2),
            onPressed: _currentPage < _totalPages
                ? () => _controller.jumpToPage(_totalPages) : null,
            tooltip: 'Last page',
          ),
          if (widget.enableSearch)
            IconButton(
              icon: const Icon(Iconsax.search_normal),
              tooltip: 'Search',
              onPressed: () => _pdfKey.currentState?.openBookmarkView(),
            ),
        ],
      ),
    );
  }

  void _onLoaded(PdfDocumentLoadedDetails details) {
    setState(() {
      _isLoading = false;
      _totalPages = details.document.pages.count;
    });
    widget.onDocumentLoaded?.call(details);
  }

  void _onLoadFailed(PdfDocumentLoadFailedDetails details) {
    setState(() { _isLoading = false; _hasError = true; });
    widget.onDocumentLoadFailed?.call(details);
  }

  void _onPageChanged(PdfPageChangedDetails details) {
    setState(() => _currentPage = details.newPageNumber);
    widget.onPageChanged?.call(details.newPageNumber, _totalPages);
  }
}
