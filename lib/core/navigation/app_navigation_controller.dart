// ─── AppNavigationController ──────────────────────────────────────────────────
// ChangeNotifier that owns all navigation state:
//   • Selected node (drives route + highlight)
//   • Expanded groups (accordion tree state)
//   • Drawer mode: expanded (280px) vs collapsed (72px)
//   • Favourites — persisted in SharedPreferences
//   • Recents — last N visited leaves, persisted
//   • User permissions — drives node visibility
//   • Search query + results
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_navigation_node.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const _kFavouritesKey = 'app_nav_favourites';
const _kRecentsKey    = 'app_nav_recents';
const _kExpandedKey   = 'app_nav_expanded';
const _kDrawerOpenKey = 'app_nav_drawer_open';
const _kMaxRecents    = 8;

// ── Controller ────────────────────────────────────────────────────────────────

class AppNavigationController extends ChangeNotifier {
  // ── Singleton ──────────────────────────────────────────────────────────────

  AppNavigationController();
  static final AppNavigationController instance = AppNavigationController();

  // ── Internal state ─────────────────────────────────────────────────────────

  /// Root nodes of the navigation tree (full, unfiltered).
  List<AppNavigationNode> _roots = [];

  /// Permissions the current user holds.
  Set<String> _userPermissions = {};

  /// Which group node IDs are currently expanded.
  final Set<String> _expandedIds = {};

  /// Currently selected (highlighted) node ID.
  String? _selectedId;

  /// Whether the drawer is in expanded (true = 280px) or icon (false = 72px) mode.
  bool _drawerExpanded = true;

  /// Favourite node IDs (persisted).
  final List<String> _favouriteIds = [];

  /// Recent node IDs, most-recent first (persisted).
  final List<String> _recentIds = [];

  /// Current search query.
  String _searchQuery = '';

  bool _initialized = false;
  SharedPreferences? _prefs;

  // ── Public getters ─────────────────────────────────────────────────────────

  List<AppNavigationNode> get roots => _filteredRoots();

  Set<String> get expandedIds      => Set.unmodifiable(_expandedIds);
  String?     get selectedId        => _selectedId;
  bool        get drawerExpanded    => _drawerExpanded;
  List<String> get favouriteIds     => List.unmodifiable(_favouriteIds);
  List<String> get recentIds        => List.unmodifiable(_recentIds);
  String      get searchQuery       => _searchQuery;
  bool        get hasSearch         => _searchQuery.isNotEmpty;

  // ── Derived — favourite/recent nodes ──────────────────────────────────────

  List<AppNavigationNode> get favouriteNodes {
    final all = _allLeaves();
    return _favouriteIds
        .map((id) => all.where((n) => n.id == id).firstOrNull)
        .whereType<AppNavigationNode>()
        .toList();
  }

  List<AppNavigationNode> get recentNodes {
    final all = _allLeaves();
    return _recentIds
        .map((id) => all.where((n) => n.id == id).firstOrNull)
        .whereType<AppNavigationNode>()
        .toList();
  }

  // ── Derived — search results ───────────────────────────────────────────────

  List<AppNavigationNode> get searchResults {
    if (_searchQuery.isEmpty) return [];
    final q = _searchQuery.toLowerCase();
    return _allLeaves().where((n) {
      return n.label.toLowerCase().contains(q) ||
          (n.description?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  // ── Derived — breadcrumb for selected node ────────────────────────────────

  List<AppNavigationNode> get breadcrumb {
    if (_selectedId == null) return [];
    for (final root in _roots) {
      final path = root.pathTo(_selectedId!);
      if (path.isNotEmpty) return path;
    }
    return [];
  }

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> initialize({
    required List<AppNavigationNode> roots,
    Set<String> userPermissions = const {},
    String? initialSelectedId,
  }) async {
    _roots = roots;
    _userPermissions = userPermissions;

    _prefs = await SharedPreferences.getInstance();
    _loadPersistedState();

    if (initialSelectedId != null) {
      _selectedId = initialSelectedId;
      _autoExpand(initialSelectedId);
    }

    _initialized = true;
    notifyListeners();
  }

  void _loadPersistedState() {
    final prefs = _prefs;
    if (prefs == null) return;

    // Favourites
    final favJson = prefs.getString(_kFavouritesKey);
    if (favJson != null) {
      _favouriteIds
        ..clear()
        ..addAll((jsonDecode(favJson) as List).cast<String>());
    }

    // Recents
    final recJson = prefs.getString(_kRecentsKey);
    if (recJson != null) {
      _recentIds
        ..clear()
        ..addAll((jsonDecode(recJson) as List).cast<String>());
    }

    // Expanded groups
    final expJson = prefs.getString(_kExpandedKey);
    if (expJson != null) {
      _expandedIds.addAll((jsonDecode(expJson) as List).cast<String>());
    }

    // Drawer state
    _drawerExpanded = prefs.getBool(_kDrawerOpenKey) ?? true;
  }

  // ── Tree mutation ─────────────────────────────────────────────────────────

  /// Replace the navigation tree at runtime (e.g. after permission change).
  void setRoots(List<AppNavigationNode> roots) {
    _roots = roots;
    notifyListeners();
  }

  /// Update user permissions and re-filter the tree.
  void setPermissions(Set<String> permissions) {
    _userPermissions = permissions;
    notifyListeners();
  }

  // ── Selection ─────────────────────────────────────────────────────────────

  /// Select a node by ID. Records it to recents.
  void select(String id) {
    if (_selectedId == id) return;
    _selectedId = id;
    _autoExpand(id);
    _recordRecent(id);
    notifyListeners();
  }

  /// Select node by route string (called by router on navigation).
  void selectByRoute(String route) {
    final node = _allLeaves().where((n) => n.route == route).firstOrNull;
    if (node != null) select(node.id);
  }

  // ── Expand / collapse ─────────────────────────────────────────────────────

  void toggleExpanded(String id) {
    if (_expandedIds.contains(id)) {
      _expandedIds.remove(id);
    } else {
      _expandedIds.add(id);
    }
    _persistExpanded();
    notifyListeners();
  }

  void expand(String id) {
    _expandedIds.add(id);
    _persistExpanded();
    notifyListeners();
  }

  void collapse(String id) {
    _expandedIds.remove(id);
    _persistExpanded();
    notifyListeners();
  }

  bool isExpanded(String id) => _expandedIds.contains(id);

  /// Expand all ancestors of [targetId] so the node is visible.
  void _autoExpand(String targetId) {
    for (final root in _roots) {
      final path = root.pathTo(targetId);
      if (path.length > 1) {
        for (final node in path.sublist(0, path.length - 1)) {
          _expandedIds.add(node.id);
        }
      }
    }
  }

  // ── Drawer mode ───────────────────────────────────────────────────────────

  void toggleDrawer() {
    _drawerExpanded = !_drawerExpanded;
    _prefs?.setBool(_kDrawerOpenKey, _drawerExpanded);
    notifyListeners();
  }

  void setDrawerExpanded(bool value) {
    if (_drawerExpanded == value) return;
    _drawerExpanded = value;
    _prefs?.setBool(_kDrawerOpenKey, value);
    notifyListeners();
  }

  // ── Favourites ────────────────────────────────────────────────────────────

  bool isFavourite(String id) => _favouriteIds.contains(id);

  void toggleFavourite(String id) {
    if (_favouriteIds.contains(id)) {
      _favouriteIds.remove(id);
    } else {
      _favouriteIds.insert(0, id);
    }
    _persistFavourites();
    notifyListeners();
  }

  void addFavourite(String id) {
    if (_favouriteIds.contains(id)) return;
    _favouriteIds.insert(0, id);
    _persistFavourites();
    notifyListeners();
  }

  void removeFavourite(String id) {
    _favouriteIds.remove(id);
    _persistFavourites();
    notifyListeners();
  }

  void _persistFavourites() =>
      _prefs?.setString(_kFavouritesKey, jsonEncode(_favouriteIds));

  // ── Recents ───────────────────────────────────────────────────────────────

  void _recordRecent(String id) {
    _recentIds
      ..remove(id)
      ..insert(0, id);
    if (_recentIds.length > _kMaxRecents) {
      _recentIds.removeRange(_kMaxRecents, _recentIds.length);
    }
    _prefs?.setString(_kRecentsKey, jsonEncode(_recentIds));
  }

  void clearRecents() {
    _recentIds.clear();
    _prefs?.remove(_kRecentsKey);
    notifyListeners();
  }

  // ── Search ────────────────────────────────────────────────────────────────

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() => setSearchQuery('');

  // ── Private helpers ───────────────────────────────────────────────────────

  List<AppNavigationNode> _filteredRoots() {
    return _roots
        .map((r) => r.filterForPermissions(_userPermissions))
        .where((r) => r.id != '__denied__')
        .toList();
  }

  List<AppNavigationNode> _allLeaves() {
    return _filteredRoots().expand((r) => r.allLeaves).toList();
  }

  void _persistExpanded() =>
      _prefs?.setString(_kExpandedKey, jsonEncode(_expandedIds.toList()));

  @override
  void dispose() {
    // Singleton — never actually disposed.
    super.dispose();
  }
}
