// ─── NavigationShowcasePage ───────────────────────────────────────────────────
// Live demo of AppNavigationWorkspace — the enterprise navigation shell.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:enterprise_kit/core/navigation/index.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';
import 'package:enterprise_kit/core/toast/app_toast.dart';
import 'package:enterprise_kit/shared/widgets/buttons/app_back_button.dart';

// ── Demo navigation tree ──────────────────────────────────────────────────────

const _kAdminPerm = 'admin';
const _kDevOpsPerm = 'devops';

final _demoRoots = <AppNavigationNode>[
  const AppNavigationNode.group(
    id: 'infrastructure',
    label: 'Infrastructure',
    icon: Iconsax.cpu,
    accentColor: Color(0xFF0891B2),
    children: [
      AppNavigationNode.leaf(
        id: 'clusters',
        label: 'Clusters',
        description: 'Kubernetes cluster management',
        icon: Iconsax.hierarchy,
        route: '/infra/clusters',
        accentColor: Color(0xFF0891B2),
      ),
      AppNavigationNode.group(
        id: 'databases',
        label: 'Databases',
        icon: Iconsax.archive,
        accentColor: Color(0xFF7C3AED),
        children: [
          AppNavigationNode.leaf(
            id: 'db-postgres',
            label: 'PostgreSQL',
            description: 'Relational databases',
            icon: Iconsax.row_vertical,
            route: '/infra/databases/postgres',
            badge: '3',
          ),
          AppNavigationNode.leaf(
            id: 'db-mongo',
            label: 'MongoDB',
            description: 'Document stores',
            icon: Iconsax.code,
            route: '/infra/databases/mongo',
          ),
          AppNavigationNode.leaf(
            id: 'db-redis',
            label: 'Redis',
            description: 'In-memory cache',
            icon: Iconsax.cpu,
            route: '/infra/databases/redis',
          ),
          AppNavigationNode.leaf(
            id: 'db-backups',
            label: 'Backups',
            description: 'Scheduled backup policies',
            icon: Iconsax.cloud_change,
            route: '/infra/databases/backups',
            permissions: AppNavigationPermissions({_kDevOpsPerm}),
          ),
        ],
      ),
      AppNavigationNode.leaf(
        id: 'storage',
        label: 'Object Storage',
        description: 'S3-compatible buckets',
        icon: Iconsax.folder,
        route: '/infra/storage',
      ),
      AppNavigationNode.leaf(
        id: 'networking',
        label: 'Networking',
        description: 'VPCs, subnets, load balancers',
        icon: Iconsax.routing,
        route: '/infra/networking',
        accentColor: Color(0xFF16A34A),
      ),
      AppNavigationNode.leaf(
        id: 'monitoring',
        label: 'Monitoring',
        description: 'Alerts, dashboards, SLOs',
        icon: Iconsax.activity,
        route: '/infra/monitoring',
        badge: '!',
        accentColor: Color(0xFFDC2626),
      ),
    ],
  ),

  const AppNavigationNode.group(
    id: 'applications',
    label: 'Applications',
    icon: Iconsax.element_4,
    accentColor: Color(0xFF7C3AED),
    children: [
      AppNavigationNode.leaf(
        id: 'app-mobile',
        label: 'Mobile Apps',
        description: 'iOS & Android deployments',
        icon: Iconsax.mobile,
        route: '/apps/mobile',
      ),
      AppNavigationNode.leaf(
        id: 'app-web',
        label: 'Web Apps',
        description: 'Frontend & PWA deployments',
        icon: Iconsax.monitor,
        route: '/apps/web',
      ),
      AppNavigationNode.leaf(
        id: 'app-apis',
        label: 'APIs & Backends',
        description: 'REST, gRPC, GraphQL services',
        icon: Iconsax.link,
        route: '/apps/apis',
      ),
      AppNavigationNode.leaf(
        id: 'app-admin',
        label: 'Admin Panels',
        description: 'Internal tooling',
        icon: Iconsax.security_user,
        route: '/apps/admin',
        permissions: AppNavigationPermissions({_kAdminPerm}),
        badge: 'ADMIN',
        accentColor: Color(0xFFDC2626),
      ),
    ],
  ),

  const AppNavigationNode.group(
    id: 'services',
    label: 'Platform Services',
    icon: Iconsax.setting,
    accentColor: Color(0xFF16A34A),
    children: [
      AppNavigationNode.leaf(
        id: 'svc-auth',
        label: 'Authentication',
        description: 'OAuth2, JWT, SSO providers',
        icon: Iconsax.lock,
        route: '/services/auth',
      ),
      AppNavigationNode.leaf(
        id: 'svc-notif',
        label: 'Notifications',
        description: 'Push, email, SMS delivery',
        icon: Iconsax.notification,
        route: '/services/notifications',
      ),
      AppNavigationNode.leaf(
        id: 'svc-payments',
        label: 'Payments',
        description: 'Razorpay, Stripe integrations',
        icon: Iconsax.wallet_3,
        route: '/services/payments',
        permissions: AppNavigationPermissions({_kAdminPerm}),
      ),
      AppNavigationNode.leaf(
        id: 'svc-files',
        label: 'File Storage',
        description: 'Uploads, CDN, image transforms',
        icon: Iconsax.document_upload,
        route: '/services/files',
      ),
    ],
  ),

  const AppNavigationNode.group(
    id: 'security',
    label: 'Security',
    icon: Iconsax.shield,
    accentColor: Color(0xFFDC2626),
    permissions: AppNavigationPermissions({_kAdminPerm}),
    children: [
      AppNavigationNode.leaf(
        id: 'sec-roles',
        label: 'Roles & Permissions',
        description: 'RBAC management',
        icon: Iconsax.profile_2user,
        route: '/security/roles',
      ),
      AppNavigationNode.leaf(
        id: 'sec-audit',
        label: 'Audit Logs',
        description: 'Full activity trail',
        icon: Iconsax.document_text,
        route: '/security/audit',
      ),
    ],
  ),

  const AppNavigationNode.group(
    id: 'analytics',
    label: 'Analytics',
    icon: Iconsax.chart,
    accentColor: Color(0xFFD97706),
    children: [
      AppNavigationNode.leaf(
        id: 'ana-dashboards',
        label: 'Dashboards',
        description: 'Real-time KPI views',
        icon: Iconsax.category,
        route: '/analytics/dashboards',
      ),
      AppNavigationNode.leaf(
        id: 'ana-reports',
        label: 'Reports',
        description: 'Scheduled & ad-hoc reports',
        icon: Iconsax.chart_2,
        route: '/analytics/reports',
      ),
    ],
  ),
];

final _demoBottomNodes = <AppNavigationNode>[
  const AppNavigationNode.leaf(
    id: 'settings',
    label: 'Settings',
    icon: Iconsax.candle_2,
    route: '/settings',
  ),
  const AppNavigationNode.leaf(
    id: 'help',
    label: 'Help & Support',
    icon: Iconsax.info_circle,
    route: '/help',
  ),
  const AppNavigationNode.leaf(
    id: 'docs',
    label: 'Documentation',
    icon: Iconsax.book,
    externalUrl: 'https://docs.anandians.dev',
    accentColor: Color(0xFF0891B2),
  ),
];

// ── Page ──────────────────────────────────────────────────────────────────────

class NavigationShowcasePage extends StatefulWidget {
  const NavigationShowcasePage({super.key});

  @override
  State<NavigationShowcasePage> createState() => _NavigationShowcasePageState();
}

class _NavigationShowcasePageState extends State<NavigationShowcasePage> {
  // Use a local controller so the showcase is self-contained
  final _ctrl = AppNavigationController();
  bool _hasAdminPerm = false;
  bool _hasDevOpsPerm = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _ctrl
        .initialize(
          roots: _demoRoots,
          userPermissions: {},
          initialSelectedId: 'clusters',
        )
        .then((_) {
          _ctrl.expand('infrastructure');
          if (mounted) setState(() => _initialized = true);
        });
    _ctrl.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.removeListener(_rebuild);
    _ctrl.dispose();
    super.dispose();
  }

  void _updatePermissions() {
    _ctrl.setPermissions({
      if (_hasAdminPerm) _kAdminPerm,
      if (_hasDevOpsPerm) _kDevOpsPerm,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Demo controls — shown as a slim banner at the top ─────────────
            _ControlsBar(
              hasAdmin: _hasAdminPerm,
              hasDevOps: _hasDevOpsPerm,
              onAdminChanged: (v) => setState(() {
                _hasAdminPerm = v;
                _updatePermissions();
              }),
              onDevOpsChanged: (v) => setState(() {
                _hasDevOpsPerm = v;
                _updatePermissions();
              }),
            ),

            // ── Workspace (not a Scaffold itself) ─────────────────────────────
            Expanded(
              child: AppNavigationWorkspace(
                controller: _ctrl,
                environment: const AppNavigationEnvironment(
                  appName: 'Anandians Infra',
                  environmentLabel: 'PRODUCTION',
                  tenantName: 'Tenant: Eastman',
                ),
                user: AppNavigationUser(
                  name: 'Akshit Singh',
                  email: 'akshit@anandians.dev',
                  role: 'Workspace Owner',
                  onTap: () =>
                      AppToastController.instance.info('Profile tapped'),
                ),
                bottomNodes: _demoBottomNodes,
                onNodeTap: (node) {
                  AppToastController.instance.info(
                    node.route ?? node.externalUrl ?? node.id,
                    title: node.label,
                  );
                },
                child: _ContentArea(controller: _ctrl),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Controls bar ──────────────────────────────────────────────────────────────

class _ControlsBar extends StatelessWidget {
  final bool hasAdmin;
  final bool hasDevOps;
  final ValueChanged<bool> onAdminChanged;
  final ValueChanged<bool> onDevOpsChanged;

  const _ControlsBar({
    required this.hasAdmin,
    required this.hasDevOps,
    required this.onAdminChanged,
    required this.onDevOpsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      height: 40,
      padding: const EdgeInsets.only(right: AppSpacing.md),
      color: cs.primaryContainer.withOpacity(0.4),
      child: Row(
        children: [
          const AppBackButton(),
          Icon(Iconsax.candle_2, size: 13, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            'Permissions:',
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          _PermChip(
            label: 'admin',
            active: hasAdmin,
            onChanged: onAdminChanged,
            color: const Color(0xFFDC2626),
          ),
          const SizedBox(width: 6),
          _PermChip(
            label: 'devops',
            active: hasDevOps,
            onChanged: onDevOpsChanged,
            color: const Color(0xFF7C3AED),
          ),
          const Spacer(),
          Text(
            'Long-press any node to ⭐',
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _PermChip extends StatelessWidget {
  final String label;
  final bool active;
  final ValueChanged<bool> onChanged;
  final Color color;

  const _PermChip({
    required this.label,
    required this.active,
    required this.onChanged,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!active),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: active ? color : color.withOpacity(0.3),
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? Iconsax.tick_circle : Iconsax.record,
              size: 10,
              color: active ? color : color.withOpacity(0.5),
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: active ? color : color.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Content area ──────────────────────────────────────────────────────────────

class _ContentArea extends StatelessWidget {
  final AppNavigationController controller;
  const _ContentArea({required this.controller});

  @override
  Widget build(BuildContext context) {
    final id = controller.selectedId;
    if (id == null) return _WelcomePage();

    AppNavigationNode? node;
    for (final root in controller.roots) {
      node = root.findById(id);
      if (node != null) break;
    }

    if (node == null) return _WelcomePage();
    return _NodePage(node: node, controller: controller);
  }
}

// ── Welcome ───────────────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.flash, size: 56, color: cs.primary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Anandians Infra Platform',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Select a section from the navigation.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Node page ─────────────────────────────────────────────────────────────────

class _NodePage extends StatelessWidget {
  final AppNavigationNode node;
  final AppNavigationController controller;
  const _NodePage({required this.node, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = node.accentColor ?? cs.primary;
    final isFav = controller.isFavourite(node.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page header ───────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  node.icon ?? Iconsax.document_text,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.label,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (node.description != null)
                      Text(
                        node.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                icon: Icon(
                  isFav ? Iconsax.star : Iconsax.star_1,
                  size: 18,
                  color: isFav ? const Color(0xFFD97706) : null,
                ),
                tooltip: isFav ? 'Remove favourite' : 'Add favourite',
                onPressed: () => controller.toggleFavourite(node.id),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Info card ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Node Info',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _InfoRow('ID', node.id),
                _InfoRow('Route', node.route ?? '—'),
                _InfoRow('Type', node.type.name),
                _InfoRow(
                  'Access',
                  node.permissions.required.isEmpty
                      ? 'Public'
                      : node.permissions.required.join(', '),
                ),
                if (node.badge != null) _InfoRow('Badge', node.badge!),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Content placeholder ───────────────────────────────────────
          Container(
            height: 300,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.04),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: color.withOpacity(0.12)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  node.icon ?? Iconsax.monitor,
                  size: 40,
                  color: color.withOpacity(0.25),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  node.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color.withOpacity(0.35),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Your page widget goes here',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
