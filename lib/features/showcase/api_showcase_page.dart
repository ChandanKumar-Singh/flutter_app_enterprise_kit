// ignore_for_file: use_build_context_synchronously
// ─── ApiShowcasePage ──────────────────────────────────────────────────────────
// Real-world demonstration of AppApiClientService:
//   • Live GET / POST / PUT / PATCH / DELETE against JSONPlaceholder
//   • Toggle: auth, cache, retry, custom timeout
//   • Config panel: change base URL, add header, clear cache
//   • Error panel: 404, 500, timeout simulation
//   • Live request log with timing + cache-hit indicator
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

import 'package:enterprise_kit/core/network/api_client_service.dart';
import 'package:enterprise_kit/core/network/app_api_request.dart';
import 'package:enterprise_kit/core/network/app_api_client_config.dart';
import 'package:enterprise_kit/core/network/mock_api_client_service.dart';
import 'package:enterprise_kit/core/network/app_api_service_registry.dart';
import 'package:enterprise_kit/core/network/i_api_client_service.dart';

// ─── Simple model ─────────────────────────────────────────────────────────────

class _Post {
  final int id;
  final int userId;
  final String title;
  final String body;

  const _Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  factory _Post.fromJson(Map<String, dynamic> j) => _Post(
    id: j['id'] as int,
    userId: j['userId'] as int,
    title: j['title'] as String,
    body: j['body'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'body': body,
  };
}

// ─── Log entry ────────────────────────────────────────────────────────────────

enum _LogStatus { pending, success, cached, error }

class _LogEntry {
  final DateTime time;
  final String method;
  final String path;
  _LogStatus status;
  String? detail;
  int? statusCode;
  int? elapsedMs;

  _LogEntry({
    required this.method,
    required this.path,
    this.status = _LogStatus.pending,
  }) : time = DateTime.now();
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class ApiShowcasePage extends StatefulWidget {
  const ApiShowcasePage({super.key});

  @override
  State<ApiShowcasePage> createState() => _ApiShowcasePageState();
}

class _ApiShowcasePageState extends State<ApiShowcasePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // Controls
  bool _isAuth = false; // JSONPlaceholder has no real auth, default off
  bool _canCache = true;
  bool _canRetry = true;
  int _retryCount = 2;
  int _cacheMinutes = 2;

  // Log
  final _log = <_LogEntry>[];

  // Results
  List<_Post> _posts = [];
  _Post? _singlePost;
  _Post? _createdPost;
  String? _deleteResult;
  bool _loading = false;
  String? _lastError;

  // Config tab
  final _urlCtrl = TextEditingController(
    text: 'https://jsonplaceholder.typicode.com',
  );
  final _headerKeyCtrl = TextEditingController();
  final _headerValCtrl = TextEditingController();

  final _svc = AppApiClientService.instance;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 6, vsync: this);
    // Point the shared service at JSONPlaceholder for this demo.
    _svc.updateBaseUrl('https://jsonplaceholder.typicode.com');
  }

  @override
  void dispose() {
    _tabs.dispose();
    _urlCtrl.dispose();
    _headerKeyCtrl.dispose();
    _headerValCtrl.dispose();
    super.dispose();
  }

  // ─── Request helpers ──────────────────────────────────────────────────────

  Future<void> _fetchPosts() async {
    setState(() {
      _loading = true;
      _lastError = null;
    });
    final entry = _logEntry('GET', 'posts');

    final result = await _svc.request<List<_Post>>(
      AppApiRequest(
        path: 'posts',
        method: ApiMethod.get,
        queryParams: {'_limit': '10'},
        isAuth: _isAuth,
        canCache: _canCache,
        cacheKey: 'posts_list',
        cacheDuration: Duration(minutes: _cacheMinutes),
        canRetry: _canRetry,
        retryCount: _retryCount,
        fromJson: (json) => (json as List)
            .map((e) => _Post.fromJson(e as Map<String, dynamic>))
            .toList(),
        tag: 'fetchPosts',
      ),
    );

    result.when(
      success: (s) {
        _posts = s.data;
        _updateLog(
          entry,
          _LogStatus.success,
          detail: '${s.data.length} posts',
          code: s.statusCode,
          ms: s.elapsedMs,
          cached: s.fromCache,
        );
      },
      failure: (f) {
        _lastError = f.message;
        _updateLog(
          entry,
          _LogStatus.error,
          detail: f.message,
          code: f.statusCode,
        );
      },
    );
    setState(() => _loading = false);
  }

  Future<void> _fetchSinglePost(int id) async {
    setState(() {
      _loading = true;
      _lastError = null;
    });
    final entry = _logEntry('GET', 'posts/$id');

    final result = await _svc.get<_Post>(
      'posts/$id',
      isAuth: _isAuth,
      canCache: _canCache,
      cacheDuration: Duration(minutes: _cacheMinutes),
      canRetry: _canRetry,
      fromJson: (json) => _Post.fromJson(json as Map<String, dynamic>),
      tag: 'fetchPost#$id',
    );

    result.when(
      success: (s) {
        _singlePost = s.data;
        _updateLog(
          entry,
          _LogStatus.success,
          detail: '"${s.data.title}"',
          code: s.statusCode,
          ms: s.elapsedMs,
          cached: s.fromCache,
        );
      },
      failure: (f) {
        _lastError = f.message;
        _updateLog(
          entry,
          _LogStatus.error,
          detail: f.message,
          code: f.statusCode,
        );
      },
    );
    setState(() => _loading = false);
  }

  Future<void> _createPost() async {
    setState(() {
      _loading = true;
      _lastError = null;
    });
    final entry = _logEntry('POST', 'posts');

    final result = await _svc.post<_Post>(
      'posts',
      body: {
        'userId': 1,
        'title': 'Enterprise Flutter post',
        'body': 'Created via AppApiClientService at ${DateTime.now()}',
      },
      isAuth: _isAuth,
      canRetry: false,
      fromJson: (json) => _Post.fromJson(json as Map<String, dynamic>),
      tag: 'createPost',
    );

    result.when(
      success: (s) {
        _createdPost = s.data;
        _updateLog(
          entry,
          _LogStatus.success,
          detail: 'id=${s.data.id}',
          code: s.statusCode,
          ms: s.elapsedMs,
        );
      },
      failure: (f) {
        _lastError = f.message;
        _updateLog(
          entry,
          _LogStatus.error,
          detail: f.message,
          code: f.statusCode,
        );
      },
    );
    setState(() => _loading = false);
  }

  Future<void> _updatePost() async {
    setState(() {
      _loading = true;
      _lastError = null;
    });
    final entry = _logEntry('PUT', 'posts/1');

    final result = await _svc.put<_Post>(
      'posts/1',
      body: {
        'id': 1,
        'userId': 1,
        'title': 'Updated via PUT',
        'body': 'Full replacement at ${DateTime.now()}',
      },
      isAuth: _isAuth,
      canRetry: _canRetry,
      fromJson: (json) => _Post.fromJson(json as Map<String, dynamic>),
      tag: 'updatePost',
    );

    result.when(
      success: (s) {
        _updateLog(
          entry,
          _LogStatus.success,
          detail: '"${s.data.title}"',
          code: s.statusCode,
          ms: s.elapsedMs,
        );
      },
      failure: (f) {
        _lastError = f.message;
        _updateLog(
          entry,
          _LogStatus.error,
          detail: f.message,
          code: f.statusCode,
        );
      },
    );
    setState(() => _loading = false);
  }

  Future<void> _patchPost() async {
    setState(() {
      _loading = true;
      _lastError = null;
    });
    final entry = _logEntry('PATCH', 'posts/1');

    final result = await _svc.patch<_Post>(
      'posts/1',
      body: {'title': 'Patched title ${DateTime.now().second}s'},
      isAuth: _isAuth,
      canRetry: _canRetry,
      fromJson: (json) => _Post.fromJson(json as Map<String, dynamic>),
      tag: 'patchPost',
    );

    result.when(
      success: (s) => _updateLog(
        entry,
        _LogStatus.success,
        detail: '"${s.data.title}"',
        code: s.statusCode,
        ms: s.elapsedMs,
      ),
      failure: (f) {
        _lastError = f.message;
        _updateLog(
          entry,
          _LogStatus.error,
          detail: f.message,
          code: f.statusCode,
        );
      },
    );
    setState(() => _loading = false);
  }

  Future<void> _deletePost(int id) async {
    setState(() {
      _loading = true;
      _lastError = null;
    });
    final entry = _logEntry('DELETE', 'posts/$id');

    final result = await _svc.delete<Map<String, dynamic>>(
      'posts/$id',
      isAuth: _isAuth,
      canRetry: false,
      fromJson: (json) => (json as Map<String, dynamic>?) ?? {},
      tag: 'deletePost#$id',
    );

    result.when(
      success: (s) {
        _deleteResult = 'Post $id deleted (${s.statusCode})';
        _updateLog(
          entry,
          _LogStatus.success,
          detail: _deleteResult!,
          code: s.statusCode,
          ms: s.elapsedMs,
        );
      },
      failure: (f) {
        _lastError = f.message;
        _updateLog(
          entry,
          _LogStatus.error,
          detail: f.message,
          code: f.statusCode,
        );
      },
    );
    setState(() => _loading = false);
  }

  Future<void> _triggerError(int code) async {
    setState(() {
      _loading = true;
      _lastError = null;
    });
    final entry = _logEntry('GET', 'https://httpstat.us/$code');

    // Point a temporary request directly to httpstat.us
    final tmpClient = AppApiClientService.instance;
    final savedUrl = tmpClient.baseUrl;
    tmpClient.updateBaseUrl('https://httpstat.us');

    final result = await tmpClient.request<Map<String, dynamic>>(
      AppApiRequest(
        path: '$code',
        method: ApiMethod.get,
        isAuth: false,
        canCache: false,
        canRetry: false,
        fromJson: (json) =>
            (json is Map<String, dynamic>) ? json : {'raw': json.toString()},
        tag: 'errorDemo/$code',
      ),
    );

    // Restore
    tmpClient.updateBaseUrl(savedUrl);

    result.when(
      success: (s) => _updateLog(
        entry,
        _LogStatus.success,
        detail: 'Unexpected success: ${s.statusCode}',
        code: s.statusCode,
      ),
      failure: (f) {
        _lastError = '${f.error.label}: ${f.message}';
        _updateLog(
          entry,
          _LogStatus.error,
          detail: '${f.error.label} — ${f.message}',
          code: f.statusCode,
        );
      },
    );
    setState(() => _loading = false);
  }

  // ─── Log helpers ──────────────────────────────────────────────────────────

  _LogEntry _logEntry(String method, String path) {
    final e = _LogEntry(method: method, path: path);
    setState(() => _log.insert(0, e));
    return e;
  }

  void _updateLog(
    _LogEntry entry,
    _LogStatus status, {
    String? detail,
    int? code,
    int? ms,
    bool cached = false,
  }) {
    entry.status = cached ? _LogStatus.cached : status;
    entry.detail = detail;
    entry.statusCode = code;
    entry.elapsedMs = ms;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF8FAFF);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor:        isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor:        isDark ? Colors.white : const Color(0xFF0F172A),
        elevation:              0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Iconsax.code_circle, size: 18, color: Color(0xFF6366F1)),
            ),
            const SizedBox(width: 10),
            const Text('API Client', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10B981),
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        bottom: _ApiAppBarBottom(
          tabBar: TabBar(
            controller:       _tabs,
            isScrollable:     true,
            tabAlignment:     TabAlignment.start,
            labelStyle:       const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            indicatorSize:    TabBarIndicatorSize.label,
            indicatorColor:   const Color(0xFF6366F1),
            labelColor:       const Color(0xFF6366F1),
            unselectedLabelColor: isDark ? Colors.white54 : Colors.black45,
            tabs: const [
              Tab(text: 'GET'),
              Tab(text: 'WRITE'),
              Tab(text: 'ERRORS'),
              Tab(text: 'CONFIG'),
              Tab(text: 'LOG'),
            Tab(text: 'CLIENTS'),
            ],
          ),
          controlBar: _ControlBar(
            isAuth:       _isAuth,
            canCache:     _canCache,
            canRetry:     _canRetry,
            retryCount:   _retryCount,
            cacheMinutes: _cacheMinutes,
            loading:      _loading,
            onAuthToggle:  (v) => setState(() => _isAuth       = v),
            onCacheToggle: (v) => setState(() => _canCache      = v),
            onRetryToggle: (v) => setState(() => _canRetry      = v),
            onRetryCount:  (v) => setState(() => _retryCount    = v),
            onCacheMins:   (v) => setState(() => _cacheMinutes  = v),
          ),
          errorBanner: _lastError != null
              ? _ErrorBanner(message: _lastError!, onDismiss: () => setState(() => _lastError = null))
              : null,
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _GetTab(
            posts:      _posts,
            singlePost: _singlePost,
            loading:    _loading,
            onFetchAll: _fetchPosts,
            onFetchOne: _fetchSinglePost,
            onClear:    () => setState(() { _posts = []; _singlePost = null; }),
          ),
          _WriteTab(
            created:      _createdPost,
            deleteResult: _deleteResult,
            loading:      _loading,
            onCreate:     _createPost,
            onUpdate:     _updatePost,
            onPatch:      _patchPost,
            onDelete:     () => _deletePost(1),
          ),
          _ErrorTab(
            loading:  _loading,
            onTrigger: _triggerError,
          ),
          _ConfigTab(
            urlCtrl:       _urlCtrl,
            headerKeyCtrl: _headerKeyCtrl,
            headerValCtrl: _headerValCtrl,
            onApplyUrl: () {
              _svc.updateBaseUrl(_urlCtrl.text.trim());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Base URL updated: ${_urlCtrl.text.trim()}'),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            },
            onAddHeader: () {
              final k = _headerKeyCtrl.text.trim();
              final v = _headerValCtrl.text.trim();
              if (k.isNotEmpty && v.isNotEmpty) {
                _svc.updateHeaders({k: v});
                _headerKeyCtrl.clear();
                _headerValCtrl.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Header added: $k: $v')),
                );
              }
            },
            onClearCache: () {
              _svc.clearCache();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared'),
                  backgroundColor: Color(0xFFF59E0B),
                ),
              );
            },
            onResetUrl: () {
              _urlCtrl.text = 'https://jsonplaceholder.typicode.com';
              _svc.updateBaseUrl('https://jsonplaceholder.typicode.com');
            },
          ),
          _LogTab(entries: _log),
          const _ClientsTab(),
        ],
      ),
    );
  }
}

// ─── Control bar ─────────────────────────────────────────────────────────────

class _ControlBar extends StatelessWidget {
  final bool isAuth, canCache, canRetry, loading;
  final int retryCount, cacheMinutes;
  final ValueChanged<bool> onAuthToggle, onCacheToggle, onRetryToggle;
  final ValueChanged<int> onRetryCount, onCacheMins;

  const _ControlBar({
    required this.isAuth,
    required this.canCache,
    required this.canRetry,
    required this.retryCount,
    required this.cacheMinutes,
    required this.loading,
    required this.onAuthToggle,
    required this.onCacheToggle,
    required this.onRetryToggle,
    required this.onRetryCount,
    required this.onCacheMins,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final border = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.06);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ToggleChip(
              label: 'Auth',
              icon: Iconsax.shield_tick,
              active: isAuth,
              activeColor: const Color(0xFF8B5CF6),
              onToggle: onAuthToggle,
            ),
            const SizedBox(width: 8),
            _ToggleChip(
              label: 'Cache ${cacheMinutes}m',
              icon: Iconsax.archive,
              active: canCache,
              activeColor: const Color(0xFF10B981),
              onToggle: onCacheToggle,
            ),
            const SizedBox(width: 8),
            _ToggleChip(
              label: 'Retry ×$retryCount',
              icon: Iconsax.refresh,
              active: canRetry,
              activeColor: const Color(0xFFF59E0B),
              onToggle: onRetryToggle,
            ),
            const SizedBox(width: 12),
            if (loading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF6366F1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final ValueChanged<bool> onToggle;

  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(!active),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? activeColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? activeColor.withOpacity(0.4)
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: active ? activeColor : Colors.grey),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active ? activeColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFDC2626).withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Iconsax.warning_2, size: 16, color: Color(0xFFDC2626)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(
              Iconsax.close_circle,
              size: 16,
              color: Color(0xFFDC2626),
            ),
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ─── GET tab ──────────────────────────────────────────────────────────────────

class _GetTab extends StatefulWidget {
  final List<_Post> posts;
  final _Post? singlePost;
  final bool loading;
  final VoidCallback onFetchAll;
  final ValueChanged<int> onFetchOne;
  final VoidCallback onClear;

  const _GetTab({
    required this.posts,
    required this.singlePost,
    required this.loading,
    required this.onFetchAll,
    required this.onFetchOne,
    required this.onClear,
  });

  @override
  State<_GetTab> createState() => _GetTabState();
}

class _GetTabState extends State<_GetTab> {
  final _idCtrl = TextEditingController(text: '1');

  @override
  void dispose() {
    _idCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Fetch list ──────────────────────────────────────────────────────
        _SectionCard(
          title: 'GET /posts',
          subtitle: 'Fetch 10 posts (limit query param). Cache-aware.',
          color: const Color(0xFF3B82F6),
          icon: Iconsax.document_text,
          actions: [
            _ApiButton(
              label: 'Fetch Posts',
              icon: Iconsax.refresh,
              color: const Color(0xFF3B82F6),
              loading: widget.loading,
              onTap: widget.onFetchAll,
            ),
            const SizedBox(width: 8),
            _ApiButton(
              label: 'Clear',
              icon: Iconsax.trash,
              color: Colors.grey,
              loading: false,
              onTap: widget.onClear,
            ),
          ],
          child: widget.posts.isEmpty
              ? const _EmptyHint(
                  'Tap "Fetch Posts" to load from JSONPlaceholder',
                )
              : Column(
                  children: widget.posts.map((p) => _PostTile(p)).toList(),
                ),
        ),
        const SizedBox(height: 16),

        // ── Fetch single ────────────────────────────────────────────────────
        _SectionCard(
          title: 'GET /posts/:id',
          subtitle: 'Fetch a single post by ID.',
          color: const Color(0xFF8B5CF6),
          icon: Iconsax.document,
          actions: [
            SizedBox(
              width: 60,
              child: TextFormField(
                controller: _idCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onTapOutside: (event) => FocusScope.of(context).unfocus(),
                decoration: InputDecoration(
                  hintText: 'ID',
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ApiButton(
              label: 'Fetch',
              icon: Iconsax.search_normal,
              color: const Color(0xFF8B5CF6),
              loading: widget.loading,
              onTap: () => widget.onFetchOne(int.tryParse(_idCtrl.text) ?? 1),
            ),
          ],
          child: widget.singlePost == null
              ? const _EmptyHint('Enter a post ID and tap Fetch')
              : _PostCard(widget.singlePost!),
        ),
      ],
    );
  }
}

// ─── WRITE tab ────────────────────────────────────────────────────────────────

class _WriteTab extends StatelessWidget {
  final _Post? created;
  final String? deleteResult;
  final bool loading;
  final VoidCallback onCreate, onUpdate, onPatch, onDelete;

  const _WriteTab({
    required this.created,
    required this.deleteResult,
    required this.loading,
    required this.onCreate,
    required this.onUpdate,
    required this.onPatch,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          title: 'POST /posts',
          subtitle:
              'Create a new post. Returns the created object with a server-assigned ID.',
          color: const Color(0xFF10B981),
          icon: Iconsax.add_circle,
          actions: [
            _ApiButton(
              label: 'Create Post',
              icon: Iconsax.send_1,
              color: const Color(0xFF10B981),
              loading: loading,
              onTap: onCreate,
            ),
          ],
          child: created == null
              ? const _EmptyHint('Tap Create Post to POST to JSONPlaceholder')
              : _PostCard(created!),
        ),
        const SizedBox(height: 16),

        _SectionCard(
          title: 'PUT /posts/1',
          subtitle: 'Full replacement of post #1.',
          color: const Color(0xFFF59E0B),
          icon: Iconsax.refresh_circle,
          actions: [
            _ApiButton(
              label: 'PUT Update',
              icon: Iconsax.edit,
              color: const Color(0xFFF59E0B),
              loading: loading,
              onTap: onUpdate,
            ),
          ],
        ),
        const SizedBox(height: 16),

        _SectionCard(
          title: 'PATCH /posts/1',
          subtitle: 'Partial update — only title field.',
          color: const Color(0xFFEC4899),
          icon: Iconsax.edit_2,
          actions: [
            _ApiButton(
              label: 'PATCH Update',
              icon: Iconsax.edit_2,
              color: const Color(0xFFEC4899),
              loading: loading,
              onTap: onPatch,
            ),
          ],
        ),
        const SizedBox(height: 16),

        _SectionCard(
          title: 'DELETE /posts/1',
          subtitle: 'Delete post #1. JSONPlaceholder returns {} with 200.',
          color: const Color(0xFFDC2626),
          icon: Iconsax.trash,
          actions: [
            _ApiButton(
              label: 'DELETE',
              icon: Iconsax.trash,
              color: const Color(0xFFDC2626),
              loading: loading,
              onTap: onDelete,
            ),
          ],
          child: deleteResult == null
              ? null
              : _ResultChip(deleteResult!, Colors.green),
        ),
      ],
    );
  }
}

// ─── ERRORS tab ───────────────────────────────────────────────────────────────

class _ErrorTab extends StatelessWidget {
  final bool loading;
  final ValueChanged<int> onTrigger;

  const _ErrorTab({required this.loading, required this.onTrigger});

  @override
  Widget build(BuildContext context) {
    const errors = [
      (404, '404 Not Found', 'Resource does not exist.', Color(0xFFF59E0B)),
      (
        401,
        '401 Unauthorized',
        'No valid token → AppApiError.unauthorized.',
        Color(0xFF8B5CF6),
      ),
      (
        403,
        '403 Forbidden',
        'Token valid but no permission.',
        Color(0xFFEF4444),
      ),
      (422, '422 Unprocessable', 'Validation failed.', Color(0xFFEC4899)),
      (
        500,
        '500 Server Error',
        'Internal server error — retried.',
        Color(0xFFDC2626),
      ),
      (
        503,
        '503 Service Unavail',
        'Unavailable — triggers retry.',
        Color(0xFFDC2626),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _InfoCard(
          'Error handling is automatic. Each failure maps to an AppApiError enum. '
          'Tap a button to simulate the error and see how the service handles it. '
          'Results appear in the LOG tab.',
        ),
        const SizedBox(height: 16),
        ...errors.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SectionCard(
              title: e.$2,
              subtitle: e.$3,
              color: e.$4,
              icon: Iconsax.warning_2,
              actions: [
                _ApiButton(
                  label: 'Trigger ${e.$1}',
                  icon: Iconsax.danger,
                  color: e.$4,
                  loading: loading,
                  onTap: () => onTrigger(e.$1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── CONFIG tab ───────────────────────────────────────────────────────────────

class _ConfigTab extends StatelessWidget {
  final TextEditingController urlCtrl, headerKeyCtrl, headerValCtrl;
  final VoidCallback onApplyUrl, onAddHeader, onClearCache, onResetUrl;

  const _ConfigTab({
    required this.urlCtrl,
    required this.headerKeyCtrl,
    required this.headerValCtrl,
    required this.onApplyUrl,
    required this.onAddHeader,
    required this.onClearCache,
    required this.onResetUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0F172A) : Colors.white;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _InfoCard(
          'All changes are applied to the live AppApiClientService singleton '
          'and affect subsequent requests. These methods mirror updateBaseUrl(), '
          'updateHeaders(), clearCache() etc. on the service.',
        ),
        const SizedBox(height: 16),

        // ── Base URL ────────────────────────────────────────────────────────
        _Card(
          color: cardBg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardHeader('Base URL', Iconsax.link, Color(0xFF3B82F6)),
              const SizedBox(height: 12),
              TextFormField(
                controller: urlCtrl,
                onTapOutside: (event) => FocusScope.of(context).unfocus(),
                decoration: InputDecoration(
                  hintText: 'https://api.example.com',
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _ApiButton(
                    label: 'Apply',
                    icon: Iconsax.tick_circle,
                    color: const Color(0xFF3B82F6),
                    loading: false,
                    onTap: onApplyUrl,
                  ),
                  const SizedBox(width: 8),
                  _ApiButton(
                    label: 'Reset',
                    icon: Iconsax.refresh,
                    color: Colors.grey,
                    loading: false,
                    onTap: onResetUrl,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Add header ──────────────────────────────────────────────────────
        _Card(
          color: cardBg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardHeader(
                'Add Default Header',
                Iconsax.document_code,
                Color(0xFF10B981),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: headerKeyCtrl,
                      onTapOutside: (event) => FocusScope.of(context).unfocus(),
                      decoration: const InputDecoration(
                        hintText: 'X-Tenant-ID',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: headerValCtrl,
                      onTapOutside: (event) => FocusScope.of(context).unfocus(),
                      decoration: const InputDecoration(
                        hintText: 'value',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ApiButton(
                    label: 'Add',
                    icon: Iconsax.add,
                    color: const Color(0xFF10B981),
                    loading: false,
                    onTap: onAddHeader,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Cache management ─────────────────────────────────────────────────
        _Card(
          color: cardBg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardHeader(
                'Cache Management',
                Iconsax.archive,
                Color(0xFFF59E0B),
              ),
              const SizedBox(height: 12),
              _ApiButton(
                label: 'Clear All Cache',
                icon: Iconsax.trash,
                color: const Color(0xFFF59E0B),
                loading: false,
                onTap: onClearCache,
              ),
              const SizedBox(height: 8),
              const Text(
                'Cache is in-memory. Entries expire automatically after their TTL.\n'
                'clearCache() wipes all entries. clearCacheKey(k) removes one.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Method reference ─────────────────────────────────────────────────
        _Card(
          color: cardBg,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardHeader('Service Methods', Iconsax.code, Color(0xFF8B5CF6)),
              SizedBox(height: 12),
              _MethodRef('updateBaseUrl(url)', 'Change API base URL'),
              _MethodRef('updateHeaders(map)', 'Merge default headers'),
              _MethodRef('removeHeader(key)', 'Remove a default header'),
              _MethodRef(
                'updateTimeout(...)',
                'Override connect/receive/send timeouts',
              ),
              _MethodRef('setAuthToken(token)', 'Inject bearer token'),
              _MethodRef('clearAuthToken()', 'Remove bearer token'),
              _MethodRef('clearCache()', 'Wipe entire response cache'),
              _MethodRef('clearCacheKey(key)', 'Wipe one cache entry'),
              _MethodRef('request<T>(req)', 'Universal request method'),
              _MethodRef(
                'get / post / put / patch / delete / upload',
                'Convenience wrappers',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── LOG tab ──────────────────────────────────────────────────────────────────

class _LogTab extends StatelessWidget {
  final List<_LogEntry> entries;

  const _LogTab({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.document_text, size: 40, color: Colors.grey),
            SizedBox(height: 12),
            Text('No requests yet', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: entries.length,
      itemBuilder: (_, i) => _LogTile(entries[i]),
    );
  }
}

class _LogTile extends StatelessWidget {
  final _LogEntry entry;
  const _LogTile(this.entry);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color color;
    IconData icon;
    switch (entry.status) {
      case _LogStatus.success:
        color = const Color(0xFF10B981);
        icon = Iconsax.tick_circle;
      case _LogStatus.cached:
        color = const Color(0xFF3B82F6);
        icon = Iconsax.archive;
      case _LogStatus.error:
        color = const Color(0xFFDC2626);
        icon = Iconsax.close_circle;
      case _LogStatus.pending:
        color = const Color(0xFFF59E0B);
        icon = Iconsax.timer;
    }

    final methodColor = _methodColor(entry.method);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: methodColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        entry.method,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: methodColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        entry.path,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (entry.statusCode != null)
                      Text(
                        '${entry.statusCode}',
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                if (entry.detail != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    entry.detail!,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      _fmt(entry.time),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    if (entry.elapsedMs != null && entry.elapsedMs! > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${entry.elapsedMs}ms',
                        style: TextStyle(
                          fontSize: 10,
                          color: entry.elapsedMs! < 300
                              ? const Color(0xFF10B981)
                              : entry.elapsedMs! < 1000
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFDC2626),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (entry.status == _LogStatus.cached) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'CACHE HIT',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _methodColor(String m) => switch (m) {
    'GET' => const Color(0xFF3B82F6),
    'POST' => const Color(0xFF10B981),
    'PUT' => const Color(0xFFF59E0B),
    'PATCH' => const Color(0xFFEC4899),
    'DELETE' => const Color(0xFFDC2626),
    _ => Colors.grey,
  };

  String _fmt(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}:'
      '${t.second.toString().padLeft(2, '0')}';
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title, subtitle;
  final Color color;
  final IconData icon;
  final List<Widget> actions;
  final Widget? child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.actions,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
          if (child != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            child!,
          ],
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Color color;
  final Widget child;
  const _Card({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _CardHeader(this.title, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 6),
      Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    ],
  );
}

class _ApiButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback onTap;

  const _ApiButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: loading ? color.withOpacity(0.4) : color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: loading
              ? null
              : [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostTile extends StatelessWidget {
  final _Post post;
  const _PostTile(this.post);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${post.id}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3B82F6),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              post.title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final _Post post;
  const _PostCard(this.post);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Badge('id: ${post.id}', const Color(0xFF3B82F6)),
            const SizedBox(width: 6),
            _Badge('user: ${post.userId}', const Color(0xFF8B5CF6)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          post.title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          post.body,
          style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: color,
        fontFamily: 'monospace',
      ),
    ),
  );
}

class _ResultChip extends StatelessWidget {
  final String text;
  final Color color;
  const _ResultChip(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
    ),
  );
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      color: Colors.grey,
      fontStyle: FontStyle.italic,
    ),
  );
}

class _InfoCard extends StatelessWidget {
  final String text;
  const _InfoCard(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Iconsax.info_circle, size: 14, color: Color(0xFF6366F1)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : const Color(0xFF374151),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodRef extends StatelessWidget {
  final String method, desc;
  const _MethodRef(this.method, this.desc);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              method,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                color: Color(0xFF8B5CF6),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              desc,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AppBar Bottom Widget ───────────────────────────────────────────────────

class _ApiAppBarBottom extends StatelessWidget implements PreferredSizeWidget {
  final TabBar tabBar;
  final Widget controlBar;
  final Widget? errorBanner;

  const _ApiAppBarBottom({
    required this.tabBar,
    required this.controlBar,
    this.errorBanner,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tabBar,
        controlBar,
        if (errorBanner != null) errorBanner!,
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        tabBar.preferredSize.height +
            46.0 + // _ControlBar estimated height
            (errorBanner != null ? 36.0 : 0.0), // _ErrorBanner estimated height
      );
}

// ─── CLIENTS tab ─────────────────────────────────────────────────────────────
// Live demo of 3 independent client instances all running simultaneously.

class _ClientsTab extends StatefulWidget {
  const _ClientsTab();

  @override
  State<_ClientsTab> createState() => _ClientsTabState();
}

class _ClientsTabState extends State<_ClientsTab> {
  // Three independent clients — fully separate Dio instances + caches
  late final AppApiClientService _showcaseClient;
  late final AppApiClientService _dataEnvelopeClient;
  late final MockApiClientService _mockClient;

  String? _showcaseResult;
  String? _envelopeResult;
  String? _mockResult;
  bool _loadingShowcase = false;
  bool _loadingEnvelope = false;
  bool _loadingMock     = false;

  @override
  void initState() {
    super.initState();

    // Client 1: JSONPlaceholder — no auth, ready to use
    _showcaseClient = AppApiClientService(
      config: AppApiClientConfig.jsonPlaceholder(),
    );

    // Client 2: Simulate a backend that wraps all responses in { "data": <payload> }
    // We point it at JSONPlaceholder but apply a passthrough transformer since
    // JSONPlaceholder doesn't actually wrap — this shows HOW you'd configure it.
    _dataEnvelopeClient = AppApiClientService(
      config: AppApiClientConfig.withDataEnvelope(
        baseUrl: 'https://jsonplaceholder.typicode.com',
        label: 'data-envelope-demo',
      ),
    );

    // Client 3: Pure mock — no network, instant responses
    _mockClient = MockApiClientService(
      delay: const Duration(milliseconds: 300),
    )
      ..stub('users/1',    {'id': 1, 'name': 'Alice Wonderland', 'role': 'admin'})
      ..stub('users/2',    {'id': 2, 'name': 'Bob Builder', 'role': 'editor'})
      ..stubList('products', [
        {'id': 1, 'name': 'Enterprise Kit', 'price': 299.0},
        {'id': 2, 'name': 'Flutter Pro',    'price': 149.0},
      ])
      ..stubError('secret', AppApiError.forbidden, message: 'Admin only');

    // Also register in the global registry so the whole app can use them
    AppApiServiceRegistry.registerAll({
      AppApiServiceRegistry.kShowcase: _showcaseClient,
      AppApiServiceRegistry.kMock:     _mockClient,
    });
  }

  @override
  void dispose() {
    // Note: AppApiServiceRegistry retains references — don't unregister
    // unless you're tearing down the whole app.
    super.dispose();
  }

  Future<void> _callShowcase() async {
    setState(() { _loadingShowcase = true; _showcaseResult = null; });
    final result = await _showcaseClient.get<Map<String, dynamic>>(
      'posts/5',
      isAuth:   false,
      canCache: true,
      fromJson: (json) => json as Map<String, dynamic>,
      tag:      'showcase/posts/5',
    );
    setState(() {
      _loadingShowcase = false;
      _showcaseResult = result.when(
        success: (s) => '✓ [${s.statusCode}${s.fromCache ? ' CACHE' : ''}]\n'
                        '"${s.data['title']}"',
        failure: (f) => '✗ ${f.error.label}: ${f.message}',
      );
    });
  }

  Future<void> _callEnvelopeClient() async {
    setState(() { _loadingEnvelope = true; _envelopeResult = null; });
    // With responseTransformer: AppApiTransformers.dataKey, if the response were
    // { "data": {...} } the transformer unwraps it automatically before fromJson.
    // JSONPlaceholder returns raw objects, so transformer returns them as-is.
    final result = await _dataEnvelopeClient.get<Map<String, dynamic>>(
      'users/1',
      isAuth:   false,
      fromJson: (json) => json as Map<String, dynamic>,
      tag:      'envelope/users/1',
    );
    setState(() {
      _loadingEnvelope = false;
      _envelopeResult = result.when(
        success: (s) => '✓ [${s.statusCode}] transformer: dataKey\n'
                        'name=${s.data['name']}, email=${s.data['email']}',
        failure: (f) => '✗ ${f.error.label}: ${f.message}',
      );
    });
  }

  Future<void> _callMock() async {
    setState(() { _loadingMock = true; _mockResult = null; });
    final result = await _mockClient.get<Map<String, dynamic>>(
      'users/1',
      fromJson: (json) => json as Map<String, dynamic>,
    );
    setState(() {
      _loadingMock = false;
      _mockResult = result.when(
        success: (s) => '✓ INSTANT (no network)\n'
                        'name=${s.data['name']}, role=${s.data['role']}',
        failure: (f) => '✗ ${f.error.label}: ${f.message}',
      );
    });
  }

  Future<void> _callMockForbidden() async {
    setState(() { _loadingMock = true; _mockResult = null; });
    final result = await _mockClient.get<dynamic>('secret');
    setState(() {
      _loadingMock = false;
      _mockResult = result.when(
        success: (s) => '✓ ${s.data}',
        failure: (f) => '✗ ${f.error.label} [${f.statusCode}]: ${f.message}',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0F172A) : Colors.white;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _InfoCard(
          'Three fully independent client instances — separate Dio engines, '
          'separate caches, separate configs. They all implement IApiClientService '
          'so they\'re swappable anywhere in the app.',
        ),
        const SizedBox(height: 16),

        // ── Registry status ──────────────────────────────────────────────────
        _Card(
          color: cardBg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardHeader('Registry', Iconsax.archive_book, const Color(0xFF6366F1)),
              const SizedBox(height: 10),
              Text(
                'Registered keys: ${AppApiServiceRegistry.registeredKeys.join(', ')}',
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Client 1: Showcase (real network) ─────────────────────────────────
        _ClientDemoCard(
          label:       'AppApiClientService',
          sublabel:    'config: AppApiClientConfig.jsonPlaceholder()',
          description: 'Real network · GET posts/5 · cache enabled · no auth',
          color:       const Color(0xFF3B82F6),
          icon:        Iconsax.global,
          loading:     _loadingShowcase,
          result:      _showcaseResult,
          codeSnippet:
              'final client = AppApiClientService(\n'
              '  config: AppApiClientConfig.jsonPlaceholder(),\n'
              ');\n'
              'await client.get<Map>(\'posts/5\', canCache: true);',
          actions: [
            _ApiButton(
              label:   'Call GET posts/5',
              icon:    Iconsax.send_2,
              color:   const Color(0xFF3B82F6),
              loading: _loadingShowcase,
              onTap:   _callShowcase,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Client 2: Data-envelope backend ──────────────────────────────────
        _ClientDemoCard(
          label:       'AppApiClientService',
          sublabel:    'config: AppApiClientConfig.withDataEnvelope(...)',
          description: 'responseTransformer unwraps { "data": <payload> } automatically '
                       'before fromJson runs — zero change in calling code.',
          color:       const Color(0xFF10B981),
          icon:        Iconsax.code_1,
          loading:     _loadingEnvelope,
          result:      _envelopeResult,
          codeSnippet:
              'final client = AppApiClientService(\n'
              '  config: AppApiClientConfig.withDataEnvelope(\n'
              '    baseUrl: \'https://api.myapp.com\',\n'
              '  ),\n'
              ');\n'
              '// response { "data": {...} } → unwrapped automatically',
          actions: [
            _ApiButton(
              label:   'Call GET users/1',
              icon:    Iconsax.send_2,
              color:   const Color(0xFF10B981),
              loading: _loadingEnvelope,
              onTap:   _callEnvelopeClient,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Client 3: Mock ────────────────────────────────────────────────────
        _ClientDemoCard(
          label:       'MockApiClientService',
          sublabel:    'implements IApiClientService',
          description: 'No network. Instant stub responses. Same interface — '
                       'drop-in for tests, CI, offline demos.',
          color:       const Color(0xFF8B5CF6),
          icon:        Iconsax.cpu,
          loading:     _loadingMock,
          result:      _mockResult,
          codeSnippet:
              'final mock = MockApiClientService()\n'
              '  ..stub(\'users/1\', {\'name\': \'Alice\'})\n'
              '  ..stubError(\'secret\', AppApiError.forbidden);\n'
              '\n'
              '// Identical call-site — only the client changes\n'
              'await mock.get<Map>(\'users/1\', fromJson: ...);',
          actions: [
            _ApiButton(
              label:   'Get user (stub)',
              icon:    Iconsax.user,
              color:   const Color(0xFF8B5CF6),
              loading: _loadingMock,
              onTap:   _callMock,
            ),
            const SizedBox(width: 8),
            _ApiButton(
              label:   'Forbidden stub',
              icon:    Iconsax.lock,
              color:   const Color(0xFFDC2626),
              loading: _loadingMock,
              onTap:   _callMockForbidden,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Architecture diagram ──────────────────────────────────────────────
        _Card(
          color: cardBg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardHeader('Architecture', Iconsax.hierarchy, const Color(0xFFF59E0B)),
              const SizedBox(height: 12),
              _ArchRow('IApiClientService',        '← interface',          const Color(0xFF6366F1)),
              _ArchRow('  AppApiClientService',    '← implements + wraps ApiClient (Dio)', const Color(0xFF3B82F6)),
              _ArchRow('    MyBackendService',     '← extends AppApiClientService', const Color(0xFF10B981)),
              _ArchRow('  MockApiClientService',   '← implements (no network)',     const Color(0xFF8B5CF6)),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              _ArchRow('AppApiClientConfig',       '← per-client config + responseTransformer', const Color(0xFFF59E0B)),
              _ArchRow('AppApiServiceRegistry',    '← named key-value store for instances',     const Color(0xFFEC4899)),
              const SizedBox(height: 8),
              const Text(
                'Use extend when: same Dio mechanics, different base URL / interceptors.\n'
                'Use implement when: completely different transport (mock, GraphQL, gRPC, local DB).',
                style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClientDemoCard extends StatelessWidget {
  final String label, sublabel, description, codeSnippet;
  final Color color;
  final IconData icon;
  final bool loading;
  final String? result;
  final List<Widget> actions;

  const _ClientDemoCard({
    required this.label,
    required this.sublabel,
    required this.description,
    required this.codeSnippet,
    required this.color,
    required this.icon,
    required this.loading,
    required this.result,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
                    Text(sublabel,
                        style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace'),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description,
              style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.4)),
          const SizedBox(height: 10),

          // Code snippet
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withOpacity(0.4)
                  : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.15)),
            ),
            child: Text(
              codeSnippet,
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: isDark ? Colors.white70 : const Color(0xFF374151),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 10),

          Wrap(spacing: 8, runSpacing: 8, children: actions),

          if (result != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: result!.startsWith('✓')
                    ? const Color(0xFF10B981).withOpacity(0.08)
                    : const Color(0xFFDC2626).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: result!.startsWith('✓')
                      ? const Color(0xFF10B981).withOpacity(0.3)
                      : const Color(0xFFDC2626).withOpacity(0.3),
                ),
              ),
              child: Text(
                result!,
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: result!.startsWith('✓')
                      ? const Color(0xFF10B981)
                      : const Color(0xFFDC2626),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ArchRow extends StatelessWidget {
  final String name, desc;
  final Color color;
  const _ArchRow(this.name, this.desc, this.color);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Text(name,
                style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: color)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(desc,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
}
