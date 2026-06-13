import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:dio/dio.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';
import 'package:enterprise_kit/shared/widgets/buttons/app_button.dart';

class NetworkShowcasePage extends StatefulWidget {
  const NetworkShowcasePage({super.key});
  @override State<NetworkShowcasePage> createState() => _NetworkShowcasePageState();
}

class _NetworkShowcasePageState extends State<NetworkShowcasePage> {
  bool _isLoading = false;
  String? _result;
  String? _error;

  Future<void> _fetchPosts() async {
    setState(() { _isLoading = true; _result = null; _error = null; });
    try {
      final dio = Dio(BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'));
      final response = await dio.get<Map<String, dynamic>>('/posts/1');
      setState(() { _result = response.data.toString(); });
    } on DioException catch (e) {
      setState(() { _error = 'DioException: ${e.type} — ${e.message}'; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Network')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _label(context, 'API Client'),
          Text(
            'Base URL: https://jsonplaceholder.typicode.com\n'
            'Interceptors: Auth, Retry, Cache, Connectivity, Logging, Error, Metrics',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton.filled(
            label: _isLoading ? 'Fetching...' : 'GET /posts/1',
            onPressed: _isLoading ? null : _fetchPosts,
            isLoading: _isLoading,
            icon: const Icon(Iconsax.document_download, size: 18),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_result != null)
            _ResponseBox(title: 'Response ✓', content: _result!, isError: false),
          if (_error != null)
            _ResponseBox(title: 'Error ✗', content: _error!, isError: true),

          const SizedBox(height: AppSpacing.xl),
          _label(context, 'Interceptor Stack'),
          ...[
            ('Auth',         'Injects Bearer token from SecureStorage into every request'),
            ('Retry',        'Retries 3× on 5xx / network errors with exponential backoff'),
            ('Cache',        'Caches GET responses by URL with configurable TTL headers'),
            ('Connectivity', 'Throws NoConnectionException when device is offline'),
            ('Logging',      'Logs request/response in dev mode (PrettyPrinter)'),
            ('Error',        'Normalises all Dio errors to typed NetworkException'),
            ('Metrics',      'Records latency per endpoint for performance dashboards'),
          ].map((e) => ListTile(
            dense: true,
            leading: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.flash, size: 16, color: Theme.of(context).colorScheme.primary),
            ),
            title: Text(e.$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            subtitle: Text(e.$2, style: const TextStyle(fontSize: 11)),
          )),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
  );
}

class _ResponseBox extends StatelessWidget {
  final String title, content;
  final bool isError;
  const _ResponseBox({required this.title, required this.content, required this.isError});

  @override
  Widget build(BuildContext context) {
    final color = isError ? Colors.red : Colors.green;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          SelectableText(content,
              style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: color.shade800)),
        ],
      ),
    );
  }
}
