// ─── AppNavigationNode ────────────────────────────────────────────────────────
// Recursive, data-driven navigation tree node.
//
// Design goals:
//   • Zero hardcoded UI — all menus come from a tree of AppNavigationNodes
//   • Permission-aware — nodes are invisible when the user lacks permissions
//   • Deeply nestable — Infrastructure → Databases → PostgreSQL
//   • Serialisable — IDs stored in SharedPreferences for recents / favourites
//
// Usage:
//   final root = AppNavigationNode.group(
//     id: 'infrastructure',
//     label: 'Infrastructure',
//     icon: Iconsax.cpu,
//     children: [
//       AppNavigationNode.leaf(
//         id: 'databases',
//         label: 'Databases',
//         icon: Iconsax.archive,
//         route: '/infra/databases',
//       ),
//     ],
//   );
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';


// ── Permission set ─────────────────────────────────────────────────────────────

/// An immutable set of permission strings.
/// An empty set means the node is visible to everyone.
class AppNavigationPermissions {
  final Set<String> required;

  const AppNavigationPermissions(this.required);

  /// No permission required — always visible.
  static const none = AppNavigationPermissions({});

  /// Returns true when [userPermissions] satisfies all required permissions.
  bool isGranted(Set<String> userPermissions) {
    if (required.isEmpty) return true;
    return required.every(userPermissions.contains);
  }
}

// ── Node type ─────────────────────────────────────────────────────────────────

enum AppNavigationNodeType {
  /// A non-navigable group header (renders as a section heading).
  group,

  /// A navigable leaf node (has a route).
  leaf,

  /// A visual separator line between sections.
  separator,
}

// ── Node ──────────────────────────────────────────────────────────────────────

@immutable
class AppNavigationNode {
  /// Unique stable identifier used for selection, recents, and favourites.
  final String id;

  /// Display label shown in the drawer.
  final String label;

  /// Optional one-liner description shown in search results.
  final String? description;

  /// Icon shown in collapsed (icon-only) and expanded modes.
  final IconData? icon;

  /// GoRouter path this node navigates to. Null for group nodes.
  final String? route;

  /// Child nodes. Non-empty implies [type] == group.
  final List<AppNavigationNode> children;

  /// Who can see this node. Defaults to [AppNavigationPermissions.none].
  final AppNavigationPermissions permissions;

  final AppNavigationNodeType type;

  /// Optional badge string (e.g. "3", "NEW", "BETA").
  final String? badge;

  /// Accent colour for this node's icon and highlight. Falls back to theme primary.
  final Color? accentColor;

  /// External URL — opens in browser instead of navigating via GoRouter.
  final String? externalUrl;

  const AppNavigationNode({
    required this.id,
    required this.label,
    this.description,
    this.icon,
    this.route,
    this.children = const [],
    this.permissions = AppNavigationPermissions.none,
    this.type = AppNavigationNodeType.leaf,
    this.badge,
    this.accentColor,
    this.externalUrl,
  });

  // ── Named constructors ────────────────────────────────────────────────────

  /// A navigable leaf node.
  const AppNavigationNode.leaf({
    required String id,
    required String label,
    String? description,
    IconData? icon,
    String? route,
    String? externalUrl,
    AppNavigationPermissions permissions = AppNavigationPermissions.none,
    String? badge,
    Color? accentColor,
  }) : this(
          id: id,
          label: label,
          description: description,
          icon: icon,
          route: route,
          externalUrl: externalUrl,
          permissions: permissions,
          type: AppNavigationNodeType.leaf,
          badge: badge,
          accentColor: accentColor,
        );

  /// A non-navigable group/section header with children.
  const AppNavigationNode.group({
    required String id,
    required String label,
    String? description,
    IconData? icon,
    List<AppNavigationNode> children = const [],
    AppNavigationPermissions permissions = AppNavigationPermissions.none,
    Color? accentColor,
  }) : this(
          id: id,
          label: label,
          description: description,
          icon: icon,
          children: children,
          permissions: permissions,
          type: AppNavigationNodeType.group,
          accentColor: accentColor,
        );

  /// A visual separator.
  static const separator = AppNavigationNode(
    id: '__sep__',
    label: '',
    type: AppNavigationNodeType.separator,
  );

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool get isSeparator => type == AppNavigationNodeType.separator;
  bool get isGroup     => type == AppNavigationNodeType.group;
  bool get isLeaf      => type == AppNavigationNodeType.leaf;
  bool get hasChildren => children.isNotEmpty;
  bool get isNavigable => route != null || externalUrl != null;

  /// Recursively filters the tree to only include nodes where
  /// [userPermissions] satisfies each node's required permissions.
  AppNavigationNode filterForPermissions(Set<String> userPermissions) {
    if (!permissions.isGranted(userPermissions)) {
      // Return a sentinel to be filtered out by the parent.
      return const AppNavigationNode(id: '__denied__', label: '');
    }
    if (children.isEmpty) return this;
    final filtered = children
        .map((c) => c.filterForPermissions(userPermissions))
        .where((c) => c.id != '__denied__')
        .toList();
    return AppNavigationNode(
      id: id,
      label: label,
      description: description,
      icon: icon,
      route: route,
      children: filtered,
      permissions: permissions,
      type: type,
      badge: badge,
      accentColor: accentColor,
      externalUrl: externalUrl,
    );
  }

  /// Returns a flat list of all leaf nodes in depth-first order.
  List<AppNavigationNode> get allLeaves {
    if (isLeaf || isSeparator) return isLeaf ? [this] : [];
    return children.expand((c) => c.allLeaves).toList();
  }

  /// Finds the first node (anywhere in the subtree) with [id].
  AppNavigationNode? findById(String targetId) {
    if (id == targetId) return this;
    for (final child in children) {
      final found = child.findById(targetId);
      if (found != null) return found;
    }
    return null;
  }

  /// Returns the ancestor chain from root to [targetId], inclusive.
  List<AppNavigationNode> pathTo(String targetId) {
    if (id == targetId) return [this];
    for (final child in children) {
      final sub = child.pathTo(targetId);
      if (sub.isNotEmpty) return [this, ...sub];
    }
    return [];
  }

  /// Search: returns all leaves whose label/description contain [query].
  List<AppNavigationNode> search(String query) {
    if (query.isEmpty) return [];
    final q = query.toLowerCase();
    return allLeaves.where((n) {
      return n.label.toLowerCase().contains(q) ||
          (n.description?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AppNavigationNode && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AppNavigationNode($id, $type)';
}

// ── Environment context ───────────────────────────────────────────────────────

/// Shown in the drawer header.
class AppNavigationEnvironment {
  final String appName;
  final String? logoAsset;
  final Widget? logoWidget;
  final String? environmentLabel; // "PRODUCTION", "STAGING", "DEV"
  final Color? environmentColor;
  final String? tenantName;
  final String? tenantSubtitle;

  const AppNavigationEnvironment({
    required this.appName,
    this.logoAsset,
    this.logoWidget,
    this.environmentLabel,
    this.environmentColor,
    this.tenantName,
    this.tenantSubtitle,
  });
}

// ── User profile context ──────────────────────────────────────────────────────

class AppNavigationUser {
  final String name;
  final String? email;
  final String? role;
  final String? avatarUrl;
  final Widget? avatarWidget;
  final VoidCallback? onTap;

  const AppNavigationUser({
    required this.name,
    this.email,
    this.role,
    this.avatarUrl,
    this.avatarWidget,
    this.onTap,
  });
}
