// ─── AppNotificationController ────────────────────────────────────────────────
// ChangeNotifier that owns all notification center state.
// Designed as a singleton (AppNotificationController.instance) for global use,
// but can also be instantiated locally for isolated contexts (e.g. showcase).
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../config/app_notification_config.dart';
import '../models/app_notification_model.dart';

class AppNotificationController extends ChangeNotifier {
  // ── Singleton ──────────────────────────────────────────────────────────────
  AppNotificationController({AppNotificationConfig config = AppNotificationConfig.enterprise})
      : _config = config;

  static final AppNotificationController instance = AppNotificationController();

  // ── Config ─────────────────────────────────────────────────────────────────
  AppNotificationConfig _config;
  AppNotificationConfig get config => _config;

  void configure(AppNotificationConfig config) {
    _config = config;
    notifyListeners();
  }

  // ── Raw notifications store ────────────────────────────────────────────────
  final List<AppNotification> _all = [];

  // ── Filter state ───────────────────────────────────────────────────────────
  AppNotificationCategory _activeCategory = AppNotificationCategory.all;
  AppNotificationSort     _sort           = AppNotificationSort.newest;
  AppNotificationGroupBy  _groupBy        = AppNotificationGroupBy.date;
  String                  _searchQuery    = '';

  // ── Bulk selection ─────────────────────────────────────────────────────────
  final Set<String> _selectedIds = {};
  bool _isBulkMode = false;

  // ── Collapsed groups ───────────────────────────────────────────────────────
  final Set<String> _collapsedGroups = {};

  // ── Recent searches ────────────────────────────────────────────────────────
  final List<String> _recentSearches = [];

  // ── Channel/category preferences ──────────────────────────────────────────
  final Map<AppNotificationChannel, bool> _channelPrefs = {
    for (final c in AppNotificationChannel.values) c: true,
  };
  final Map<AppNotificationCategory, bool> _categoryPrefs = {
    for (final c in AppNotificationCategory.values) c: true,
  };

  // ── Public getters — filter state ─────────────────────────────────────────
  AppNotificationCategory get activeCategory => _activeCategory;
  AppNotificationSort     get sort           => _sort;
  AppNotificationGroupBy  get groupBy        => _groupBy;
  String                  get searchQuery    => _searchQuery;
  bool                    get hasSearch      => _searchQuery.isNotEmpty;

  // ── Public getters — bulk ─────────────────────────────────────────────────
  bool          get isBulkMode => _isBulkMode;
  Set<String>   get selectedIds => UnmodifiableSetView(_selectedIds);
  int           get selectedCount => _selectedIds.length;

  // ── Public getters — badge counts ─────────────────────────────────────────
  int get totalUnread => _all.where((n) => !n.isRead && !n.isArchived).length;
  int get totalCount  => _all.where((n) => !n.isArchived).length;

  // ── Filtered + sorted view ─────────────────────────────────────────────────

  List<AppNotification> get filteredNotifications {
    var list = _all.where((n) => !n.isArchived).toList();

    // Category filter
    list = _applyCategory(list, _activeCategory);

    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((n) =>
        n.title.toLowerCase().contains(q) ||
        (n.body?.toLowerCase().contains(q) ?? false) ||
        (n.sender?.name.toLowerCase().contains(q) ?? false) ||
        kCategoryLabel[n.category]!.toLowerCase().contains(q)
      ).toList();
    }

    // Sort
    switch (_sort) {
      case AppNotificationSort.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case AppNotificationSort.oldest:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case AppNotificationSort.priority:
        list.sort((a, b) => b.priority.index.compareTo(a.priority.index));
      case AppNotificationSort.unreadFirst:
        list.sort((a, b) {
          if (a.isRead == b.isRead) return b.createdAt.compareTo(a.createdAt);
          return a.isRead ? 1 : -1;
        });
    }

    // Pinned always first
    final pinned   = list.where((n) => n.isPinned).toList();
    final unpinned = list.where((n) => !n.isPinned).toList();
    return [...pinned, ...unpinned];
  }

  // ── Grouped view ───────────────────────────────────────────────────────────

  List<AppNotificationGroup> get groups {
    if (_config.defaultGroupBy == AppNotificationGroupBy.none ||
        !_config.enableGrouping) {
      return [AppNotificationGroup(label: '', items: filteredNotifications)];
    }
    return _buildGroups(filteredNotifications, _groupBy);
  }

  List<AppNotificationGroup> _buildGroups(
    List<AppNotification> items, AppNotificationGroupBy by,
  ) {
    final Map<String, List<AppNotification>> buckets = {};
    for (final n in items) {
      final key = _groupKey(n, by);
      buckets.putIfAbsent(key, () => []).add(n);
    }

    return buckets.entries.map((e) {
      final collapsed = _collapsedGroups.contains(e.key);
      var groupItems = e.value;

      // Smart grouping: collapse ≥ threshold same groupKey notifications
      if (_config.enableSmartGrouping && e.value.length >= _config.smartGroupThreshold) {
        final byGroupKey = <String, List<AppNotification>>{};
        for (final n in e.value) {
          if (n.groupKey != null) {
            byGroupKey.putIfAbsent(n.groupKey!, () => []).add(n);
          }
        }
        // Replace collapsed runs with a representative item
        final seen = <String>{};
        groupItems = e.value.where((n) {
          if (n.groupKey == null) return true;
          if ((byGroupKey[n.groupKey]?.length ?? 0) >= _config.smartGroupThreshold) {
            if (seen.contains(n.groupKey)) return false;
            seen.add(n.groupKey!);
          }
          return true;
        }).toList();
      }

      return AppNotificationGroup(
        label: e.key,
        items: groupItems,
        isCollapsed: collapsed,
      );
    }).toList();
  }

  String _groupKey(AppNotification n, AppNotificationGroupBy by) {
    switch (by) {
      case AppNotificationGroupBy.date:
        return _dateLabel(n.createdAt);
      case AppNotificationGroupBy.category:
        return kCategoryLabel[n.category] ?? 'Other';
      case AppNotificationGroupBy.sender:
        return n.sender?.name ?? 'System';
      case AppNotificationGroupBy.priority:
        return _priorityLabel(n.priority);
      case AppNotificationGroupBy.none:
        return '';
    }
  }

  static String _dateLabel(DateTime dt) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d     = DateTime(dt.year, dt.month, dt.day);
    final diff  = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7)  return 'This Week';
    if (diff < 30) return 'This Month';
    return 'Older';
  }

  static String _priorityLabel(AppNotificationPriority p) => switch (p) {
    AppNotificationPriority.critical => '🔴  Critical',
    AppNotificationPriority.high     => '🟠  High',
    AppNotificationPriority.normal   => '🟡  Normal',
    AppNotificationPriority.low      => '⚪  Low',
  };

  // ── Archived view ──────────────────────────────────────────────────────────

  List<AppNotification> get archived => _all.where((n) => n.isArchived).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  // ── Smart group summary (for digest mode) ─────────────────────────────────

  /// Returns count map for each group key inside a section. Used in digest.
  Map<String, int> digestFor(String sectionLabel) {
    final items = groups
        .where((g) => g.label == sectionLabel)
        .expand((g) => g.items);
    final counts = <String, int>{};
    for (final n in items) {
      final key = kCategoryLabel[n.category] ?? 'Other';
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  // ── Category counts ────────────────────────────────────────────────────────

  int countFor(AppNotificationCategory cat) =>
      _applyCategory(_all.where((n) => !n.isArchived).toList(), cat).length;

  int unreadFor(AppNotificationCategory cat) =>
      _applyCategory(_all.where((n) => !n.isArchived && !n.isRead).toList(), cat).length;

  List<AppNotification> _applyCategory(
    List<AppNotification> list, AppNotificationCategory cat,
  ) => switch (cat) {
    AppNotificationCategory.all       => list,
    AppNotificationCategory.unread    => list.where((n) => !n.isRead).toList(),
    AppNotificationCategory.important => list.where((n) => n.priority.index >= AppNotificationPriority.high.index).toList(),
    AppNotificationCategory.starred   => list.where((n) => n.isStarred).toList(),
    AppNotificationCategory.archived  => list.where((n) => n.isArchived).toList(),
    AppNotificationCategory.mentions  => list.where((n) => n.type == AppNotificationType.mention).toList(),
    AppNotificationCategory.system    => list.where((n) => [AppNotificationType.systemUpdate, AppNotificationType.maintenance, AppNotificationType.announcement].contains(n.type)).toList(),
    AppNotificationCategory.security  => list.where((n) => n.type == AppNotificationType.security || n.category == AppNotificationCategory.security).toList(),
    AppNotificationCategory.finance   => list.where((n) => [AppNotificationType.payment, AppNotificationType.transaction].contains(n.type) || n.category == AppNotificationCategory.finance).toList(),
    AppNotificationCategory.tasks     => list.where((n) => [AppNotificationType.approval, AppNotificationType.assignment, AppNotificationType.reminder].contains(n.type)).toList(),
    AppNotificationCategory.messages  => list.where((n) => [AppNotificationType.chat, AppNotificationType.comment, AppNotificationType.mention].contains(n.type)).toList(),
    AppNotificationCategory.updates   => list.where((n) => [AppNotificationType.systemUpdate, AppNotificationType.announcement].contains(n.type)).toList(),
  };

  // ── Mutations ─────────────────────────────────────────────────────────────

  void addAll(List<AppNotification> notifications) {
    _all.insertAll(0, notifications);
    notifyListeners();
  }

  void add(AppNotification notification) {
    _all.insert(0, notification);
    notifyListeners();
  }

  void markRead(String id) => _update(id, (n) => n.copyWith(isRead: true, readAt: DateTime.now()));
  void markUnread(String id) => _update(id, (n) => n.copyWith(isRead: false));

  void markAllRead() {
    for (int i = 0; i < _all.length; i++) {
      if (!_all[i].isRead) _all[i] = _all[i].copyWith(isRead: true, readAt: DateTime.now());
    }
    notifyListeners();
  }

  void archive(String id)   => _update(id, (n) => n.copyWith(isArchived: true));
  void unarchive(String id) => _update(id, (n) => n.copyWith(isArchived: false));
  void pin(String id)       => _update(id, (n) => n.copyWith(isPinned: true));
  void unpin(String id)     => _update(id, (n) => n.copyWith(isPinned: false));
  void togglePin(String id) {
    final idx = _all.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    _all[idx] = _all[idx].copyWith(isPinned: !_all[idx].isPinned);
    notifyListeners();
  }

  void toggleStar(String id) {
    final idx = _all.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    _all[idx] = _all[idx].copyWith(isStarred: !_all[idx].isStarred);
    notifyListeners();
  }

  void delete(String id) {
    _all.removeWhere((n) => n.id == id);
    _selectedIds.remove(id);
    notifyListeners();
  }

  void _update(String id, AppNotification Function(AppNotification) fn) {
    final idx = _all.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    _all[idx] = fn(_all[idx]);
    notifyListeners();
  }

  AppNotification? findById(String id) =>
      _all.where((n) => n.id == id).firstOrNull;

  // ── Bulk ──────────────────────────────────────────────────────────────────

  void enterBulkMode() { _isBulkMode = true; notifyListeners(); }

  void exitBulkMode() {
    _isBulkMode = false;
    _selectedIds.clear();
    notifyListeners();
  }

  void toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void selectAll() {
    _selectedIds.addAll(filteredNotifications.map((n) => n.id));
    notifyListeners();
  }

  void clearSelection() { _selectedIds.clear(); notifyListeners(); }

  void bulkMarkRead()  { for (final id in _selectedIds.toList()) markRead(id);  exitBulkMode(); }
  void bulkArchive()   { for (final id in _selectedIds.toList()) archive(id);   exitBulkMode(); }
  void bulkDelete()    { for (final id in _selectedIds.toList()) delete(id);    exitBulkMode(); }
  void bulkPin()       { for (final id in _selectedIds.toList()) pin(id);       exitBulkMode(); }

  // ── Filter / sort / group ─────────────────────────────────────────────────

  void setCategory(AppNotificationCategory cat) {
    if (_activeCategory == cat) return;
    _activeCategory = cat;
    notifyListeners();
  }

  void setSort(AppNotificationSort s) {
    if (_sort == s) return;
    _sort = s;
    notifyListeners();
  }

  void setGroupBy(AppNotificationGroupBy g) {
    if (_groupBy == g) return;
    _groupBy = g;
    notifyListeners();
  }

  void setSearch(String q) {
    if (_searchQuery == q) return;
    _searchQuery = q;
    notifyListeners();
  }

  void clearSearch() => setSearch('');

  void submitSearch(String q) {
    if (q.isEmpty) return;
    _recentSearches
      ..remove(q)
      ..insert(0, q);
    if (_recentSearches.length > _config.maxRecentSearches) {
      _recentSearches.removeLast();
    }
    setSearch(q);
  }

  void clearRecentSearches() { _recentSearches.clear(); notifyListeners(); }

  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  // ── Group collapse ────────────────────────────────────────────────────────

  void toggleGroupCollapse(String label) {
    if (_collapsedGroups.contains(label)) {
      _collapsedGroups.remove(label);
    } else {
      _collapsedGroups.add(label);
    }
    notifyListeners();
  }

  bool isGroupCollapsed(String label) => _collapsedGroups.contains(label);

  // ── Preferences ───────────────────────────────────────────────────────────

  bool channelEnabled(AppNotificationChannel c) => _channelPrefs[c] ?? true;
  bool categoryEnabled(AppNotificationCategory c) => _categoryPrefs[c] ?? true;

  void toggleChannel(AppNotificationChannel c) {
    _channelPrefs[c] = !(_channelPrefs[c] ?? true);
    notifyListeners();
  }

  void toggleCategoryPref(AppNotificationCategory c) {
    _categoryPrefs[c] = !(_categoryPrefs[c] ?? true);
    notifyListeners();
  }
}
