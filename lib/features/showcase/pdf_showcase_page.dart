import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';
import 'package:enterprise_kit/shared/widgets/buttons/app_button.dart';
import 'package:enterprise_kit/shared/widgets/pdf/app_pdf_viewer.dart';

class PdfShowcasePage extends StatelessWidget {
  const PdfShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Viewer')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'PDF Viewer powered by Syncfusion — supports network, asset, memory sources with toolbar, search, and full-screen viewing.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),

          AppButton.filled(
            label: 'Open PDF Full Screen',
            onPressed: () => AppPdfViewer.openFullScreen(
              context,
              source: AppPdfSource.network,
              url: 'https://www.w3.org/WAI/WCAG21/Techniques/pdf/PDF17.pdf',
              title: 'Sample PDF',
            ),
            icon: const Icon(Iconsax.document_text, size: 18),
          ),
          const SizedBox(height: AppSpacing.md),

          AppButton.outlined(
            label: 'Embedded PDF Viewer',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Embedded')),
                body: AppPdfViewer.network(
                  'https://www.w3.org/WAI/WCAG21/Techniques/pdf/PDF17.pdf',
                  title: 'Sample PDF',
                  showToolbar: true,
                ),
              )),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          _label(context, 'Features'),
          ...[
            'Network, Asset, File, Memory sources',
            'Full-screen viewer with AppBar',
            'Embedded viewer with custom toolbar',
            'Page navigation (first/prev/next/last)',
            'Page counter',
            'Built-in search via Syncfusion',
            'Loading and error states',
            'Callback: onPageChanged, onDocumentLoaded, onDocumentLoadFailed',
          ].map((f) => ListTile(
            dense: true,
            leading: const Icon(Iconsax.tick_circle, color: Colors.green, size: 18),
            title: Text(f, style: const TextStyle(fontSize: 13)),
          )),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
  );
}
