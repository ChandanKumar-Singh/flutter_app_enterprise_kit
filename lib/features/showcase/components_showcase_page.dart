// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';
import 'package:enterprise_kit/core/toast/app_toast.dart';
import 'package:enterprise_kit/shared/widgets/banners/app_banner.dart';
import 'package:enterprise_kit/shared/widgets/gradients/app_gradient.dart';
import 'package:enterprise_kit/shared/widgets/pagination/app_paginator.dart';
import 'package:enterprise_kit/shared/widgets/pagination/pagination_wrapper.dart';
import 'package:enterprise_kit/shared/widgets/rating/app_rating.dart';
import 'package:enterprise_kit/shared/widgets/table/app_table.dart';
import 'package:enterprise_kit/shared/widgets/tags/app_tag.dart';
import 'package:enterprise_kit/shared/widgets/timeline/app_timeline.dart';

class ComponentsShowcasePage extends StatefulWidget {
  const ComponentsShowcasePage({super.key});

  @override
  State<ComponentsShowcasePage> createState() => _ComponentsShowcasePageState();
}

class _ComponentsShowcasePageState extends State<ComponentsShowcasePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  double _rating = 3.5;

  // Paginator for demo
  late AppPaginatorController<_DemoItem> _paginatorCtrl;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 8, vsync: this);
    _paginatorCtrl = AppPaginatorController(
      fetcher: (page, size) async {
        await Future.delayed(const Duration(milliseconds: 600));
        return List.generate(
          size,
          (i) => _DemoItem(
            id: page * size + i + 1,
            name: 'Item ${page * size + i + 1}',
            category: _categories[i % _categories.length],
            value: (page * size + i + 1) * 12.5,
          ),
        );
      },
      pageSize: 10,
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    _paginatorCtrl.dispose();
    super.dispose();
  }

  static const _categories = ['Alpha', 'Beta', 'Gamma', 'Delta', 'Epsilon'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enterprise Components'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Toasts'),
            Tab(text: 'Banners'),
            Tab(text: 'Gradients'),
            Tab(text: 'Tags'),
            Tab(text: 'Rating'),
            Tab(text: 'Timeline'),
            Tab(text: 'Table'),
            Tab(text: 'Pagination'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ToastShowcase(),
          _BannerShowcase(),
          _GradientShowcase(),
          _TagShowcase(),
          _RatingShowcase(rating: _rating, onChanged: (v) => setState(() => _rating = v)),
          _TimelineShowcase(),
          _TableShowcase(ctrl: _paginatorCtrl),
          _PaginationWrapperShowcase(),
        ],
      ),
    );
  }
}

// ─── Toast Showcase ───────────────────────────────────────────────────────────
class _ToastShowcase extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _SectionTitle('Toast Types'),
        _ShowcaseRow(
          children: [
            _DemoButton(
              'Success',
              icon: Icons.check_circle,
              color: Colors.green,
              onTap: () => AppToastController.instance.success(
                'Operation completed successfully!',
                title: 'Success',
              ),
            ),
            _DemoButton(
              'Error',
              icon: Icons.error,
              color: Colors.red,
              onTap: () => AppToastController.instance.error(
                'Something went wrong. Please try again.',
                title: 'Error',
              ),
            ),
            _DemoButton(
              'Warning',
              icon: Icons.warning,
              color: Colors.orange,
              onTap: () => AppToastController.instance.warning(
                'This action may have side effects.',
                title: 'Warning',
              ),
            ),
            _DemoButton(
              'Info',
              icon: Icons.info,
              color: Colors.blue,
              onTap: () => AppToastController.instance.info(
                'Here is some helpful information.',
                title: 'Info',
              ),
            ),
          ],
        ),
        _SectionTitle('Toast with Action'),
        _DemoButton(
          'With Undo Action',
          icon: Icons.undo,
          onTap: () => AppToastController.instance.show(
            message: 'Item deleted from list.',
            type: AppToastType.warning,
            actionLabel: 'UNDO',
            onAction: () => AppToastController.instance.info('Undo triggered!'),
            position: AppToastPosition.bottom,
          ),
        ),
        _SectionTitle('Toast Positions'),
        _ShowcaseRow(
          children: [
            _DemoButton('Top', icon: Icons.arrow_upward,
              onTap: () => AppToastController.instance.info(
                'Toast from top!', position: AppToastPosition.top)),
            _DemoButton('Center', icon: Icons.center_focus_strong,
              onTap: () => AppToastController.instance.info(
                'Toast at center!', position: AppToastPosition.center)),
            _DemoButton('Bottom', icon: Icons.arrow_downward,
              onTap: () => AppToastController.instance.info(
                'Toast from bottom!', position: AppToastPosition.bottom)),
          ],
        ),
        _SectionTitle('Loading Toast'),
        Builder(builder: (ctx) {
          return _DemoButton(
            'Show Loading',
            icon: Icons.hourglass_empty,
            onTap: () async {
              final id = AppToastController.instance.loading('Processing...');
              await Future.delayed(const Duration(seconds: 2));
              AppToastController.instance.dismiss(id);
              AppToastController.instance.success('Done!');
            },
          );
        }),
      ],
    );
  }
}

// ─── Banner Showcase ──────────────────────────────────────────────────────────
class _BannerShowcase extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _SectionTitle('App-level Banners (add to top of screen)'),
        _ShowcaseRow(
          children: [
            _DemoButton('Info Banner', icon: Icons.info_outline, color: Colors.blue,
              onTap: () => AppBannerController.instance.show(
                message: 'This is an important notification banner.',
                title: 'Information',
                type: AppBannerType.info,
              )),
            _DemoButton('Warning', icon: Icons.warning_amber, color: Colors.orange,
              onTap: () => AppBannerController.instance.show(
                message: 'Your session expires in 5 minutes.',
                type: AppBannerType.warning,
              )),
          ],
        ),
        _DemoButton('Offline Banner (dismissible: false)', icon: Icons.wifi_off,
          onTap: () => AppBannerController.instance.offline()),
        _DemoButton('Dismiss All Banners', icon: Icons.close,
          onTap: () => AppBannerController.instance.dismissAll()),
        _SectionTitle('Inline Banner Widgets'),
        const AppBannerWidget(
          message: 'Your payment method expires soon. Update to avoid interruption.',
          title: 'Action Required',
          type: AppBannerType.warning,
          actions: [AppBannerAction(label: 'Update Now', onTap: _noop)],
        ),
        const SizedBox(height: 8),
        const AppBannerWidget(
          message: 'New features available in this update.',
          type: AppBannerType.announcement,
          dismissible: false,
        ),
        const SizedBox(height: 8),
        const AppBannerWidget(
          message: 'All systems operational.',
          type: AppBannerType.success,
        ),
      ],
    );
  }
}

void _noop() {}

// ─── Gradient Showcase ────────────────────────────────────────────────────────
class _GradientShowcase extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _SectionTitle('Gradient Presets'),
        _GradientCard('Ocean', AppGradients.ocean),
        _GradientCard('Sunset', AppGradients.sunset),
        _GradientCard('Forest', AppGradients.forest),
        _GradientCard('Midnight', AppGradients.midnight),
        _GradientCard('Aurora', AppGradients.aurora),
        _GradientCard('Fire', AppGradients.fire),
        _GradientCard('Lavender', AppGradients.lavender),
        _SectionTitle('Gradient Text'),
        const AppGradientText(
          text: 'Beautiful Gradient Text',
          gradient: AppGradients.aurora,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        const AppGradientText(
          text: 'Enterprise Edition',
          gradient: AppGradients.ocean,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        _SectionTitle('Glassmorphism Cards'),
        Container(
          height: 200,
          decoration: const BoxDecoration(gradient: AppGradients.aurora),
          child: const Center(
            child: AppGlassCard(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, color: Colors.white, size: 32),
                  SizedBox(height: 8),
                  Text('Glassmorphism Card',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  Text('Beautiful frosted effect',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
        _SectionTitle('Frosted Surface'),
        Container(
          height: 200,
          decoration: const BoxDecoration(gradient: AppGradients.midnight),
          child: Center(
            child: AppFrostedSurface(
              blur: 16,
              padding: const EdgeInsets.all(20),
              child: const Text(
                'Frosted Surface\nBeautiful backdrop blur',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        _SectionTitle('Gradient Icons'),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            AppGradientIcon(icon: Icons.star_rounded, gradient: AppGradients.fire, size: 40),
            AppGradientIcon(icon: Icons.favorite_rounded, gradient: AppGradients.sunset, size: 40),
            AppGradientIcon(icon: Icons.bolt_rounded, gradient: AppGradients.aurora, size: 40),
            AppGradientIcon(icon: Icons.diamond_rounded, gradient: AppGradients.lavender, size: 40),
          ],
        ),
      ],
    );
  }
}

class _GradientCard extends StatelessWidget {
  final String label;
  final Gradient gradient;
  const _GradientCard(this.label, this.gradient);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 60,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }
}

// ─── Tag Showcase ─────────────────────────────────────────────────────────────
class _TagShowcase extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _SectionTitle('Tag Statuses'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppTag.success('Success'),
            AppTag.error('Error'),
            AppTag.warning('Warning'),
            AppTag.info('Info'),
            AppTag.pending('Pending'),
            const AppTag(label: 'Default'),
          ],
        ),
        _SectionTitle('Tag Variants'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            AppTag(label: 'Filled', variant: AppTagVariant.filled),
            AppTag(label: 'Outlined', variant: AppTagVariant.outlined),
            AppTag(label: 'Soft', variant: AppTagVariant.soft),
            AppTag(label: 'Text', variant: AppTagVariant.text),
          ],
        ),
        _SectionTitle('Tag Sizes'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            AppTag(label: 'X-Small', size: AppTagSize.xs),
            AppTag(label: 'Small', size: AppTagSize.sm),
            AppTag(label: 'Medium', size: AppTagSize.md),
            AppTag(label: 'Large', size: AppTagSize.lg),
          ],
        ),
        _SectionTitle('Closeable Tags'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppTag(label: 'Flutter', closeable: true, onClose: () {}),
            AppTag(label: 'Dart', closeable: true, status: AppTagStatus.success, onClose: () {}),
            AppTag(label: 'Riverpod', closeable: true, status: AppTagStatus.info, onClose: () {}),
          ],
        ),
        _SectionTitle('Tags with Icons'),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppTag(label: 'New', leadingIcon: Icons.new_releases_rounded, status: AppTagStatus.success),
            AppTag(label: 'Featured', leadingIcon: Icons.star_rounded, status: AppTagStatus.warning),
            AppTag(label: 'Sale', leadingIcon: Icons.local_offer_rounded, status: AppTagStatus.error),
          ],
        ),
        _SectionTitle('Toggleable Tag Group'),
        AppTagGroup(
          tags: const ['Flutter', 'Dart', 'Riverpod', 'GoRouter', 'Dio', 'GetIt', 'Hive'],
          multiSelect: true,
          onChanged: (selected) {},
        ),
        _SectionTitle('Single-Select Tag Group'),
        AppTagGroup(
          tags: const ['All', 'Active', 'Inactive', 'Archived'],
          multiSelect: false,
          variant: AppTagVariant.outlined,
          onChanged: (selected) {},
        ),
      ],
    );
  }
}

// ─── Rating Showcase ──────────────────────────────────────────────────────────
class _RatingShowcase extends StatelessWidget {
  final double rating;
  final void Function(double) onChanged;

  const _RatingShowcase({required this.rating, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _SectionTitle('Interactive Rating'),
        AppRating(value: rating, count: 5, halfAllowed: true, onChanged: onChanged),
        const SizedBox(height: 8),
        Text('Current: ${rating.toStringAsFixed(1)} / 5.0',
            style: Theme.of(context).textTheme.bodyMedium),
        _SectionTitle('Read Only'),
        const AppRating(value: 4.5, readOnly: true),
        _SectionTitle('Different Sizes'),
        ...[ 20.0, 28.0, 36.0, 44.0].map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppRating(value: rating, size: s, readOnly: true),
        )),
        _SectionTitle('No Half Star'),
        AppRating(value: rating.roundToDouble(), halfAllowed: false, onChanged: onChanged),
        _SectionTitle('Compact Display'),
        const AppRatingDisplay(rating: 4.7, totalReviews: 2847, showLabel: true),
        const SizedBox(height: 8),
        const AppRatingDisplay(rating: 3.2, totalReviews: 150),
      ],
    );
  }
}

// ─── Timeline Showcase ────────────────────────────────────────────────────────
class _TimelineShowcase extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _SectionTitle('Order Timeline'),
        AppTimeline(
          items: [
            AppTimelineItem(
              id: '1',
              title: 'Order Placed',
              subtitle: 'Your order has been confirmed.',
              date: 'Jun 10',
              time: '09:30 AM',
              status: AppTimelineStatus.completed,
            ),
            AppTimelineItem(
              id: '2',
              title: 'Payment Received',
              subtitle: 'Payment processed successfully.',
              date: 'Jun 10',
              time: '09:31 AM',
              status: AppTimelineStatus.completed,
            ),
            AppTimelineItem(
              id: '3',
              title: 'Processing',
              subtitle: 'Your order is being prepared.',
              date: 'Jun 11',
              status: AppTimelineStatus.active,
            ),
            AppTimelineItem(
              id: '4',
              title: 'Shipped',
              subtitle: 'Your package is on the way.',
              status: AppTimelineStatus.pending,
            ),
            AppTimelineItem(
              id: '5',
              title: 'Delivered',
              subtitle: 'Package delivered to your doorstep.',
              status: AppTimelineStatus.pending,
            ),
          ],
        ),
        _SectionTitle('Activity Log'),
        AppTimeline(
          items: [
            AppTimelineItem(
              id: 'a1',
              title: 'Security Alert',
              subtitle: 'New login from unknown device.',
              date: '2h ago',
              status: AppTimelineStatus.error,
            ),
            AppTimelineItem(
              id: 'a2',
              title: 'Profile Updated',
              subtitle: 'Email address changed.',
              date: '1d ago',
              status: AppTimelineStatus.completed,
            ),
            AppTimelineItem(
              id: 'a3',
              title: 'Password Changed',
              subtitle: 'Password updated successfully.',
              date: '3d ago',
              status: AppTimelineStatus.warning,
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Table Showcase ───────────────────────────────────────────────────────────
class _TableShowcase extends StatelessWidget {
  final AppPaginatorController<_DemoItem> ctrl;
  const _TableShowcase({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle('Sortable + Selectable Data Table'),
              AppTable<_DemoItem>(
                data: List.generate(15, (i) => _DemoItem(
                  id: i + 1,
                  name: 'Item ${i + 1}',
                  category: _categories[i % _categories.length],
                  value: (i + 1) * 12.5,
                )),
                selectable: true,
                showRowNumbers: true,
                striped: true,
                showPagination: true,
                itemsPerPage: 8,
                onSelectionChanged: (_) {},
                columns: [
                  AppTableColumn<_DemoItem>(
                    key: 'name',
                    label: 'Name',
                    sortable: true,
                    width: 140,
                    sortValue: (item) => item.name,
                    cellBuilder: (ctx, item, _) => Row(
                      children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: Theme.of(ctx).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text('${item.id}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(item.name),
                      ],
                    ),
                  ),
                  AppTableColumn<_DemoItem>(
                    key: 'category',
                    label: 'Category',
                    sortable: true,
                    width: 100,
                    sortValue: (item) => item.category,
                    cellBuilder: (ctx, item, _) => AppTag(
                      label: item.category,
                      size: AppTagSize.xs,
                      status: _tagStatus(item.category),
                    ),
                  ),
                  AppTableColumn<_DemoItem>(
                    key: 'value',
                    label: 'Value',
                    sortable: true,
                    width: 100,
                    alignment: TextAlign.end,
                    sortValue: (item) => item.value,
                    cellBuilder: (ctx, item, _) => Text(
                      '\$${item.value.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(ctx).colorScheme.primary,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static const _categories = ['Alpha', 'Beta', 'Gamma', 'Delta', 'Epsilon'];

  AppTagStatus _tagStatus(String cat) => switch (cat) {
    'Alpha' => AppTagStatus.success,
    'Beta' => AppTagStatus.info,
    'Gamma' => AppTagStatus.warning,
    'Delta' => AppTagStatus.error,
    _ => AppTagStatus.pending,
  };
}

// ─── Demo Data ────────────────────────────────────────────────────────────────
class _DemoItem {
  final int id;
  final String name;
  final String category;
  final double value;

  const _DemoItem({
    required this.id,
    required this.name,
    required this.category,
    required this.value,
  });
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _DemoButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final VoidCallback onTap;

  const _DemoButton(this.label, {this.icon, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: (color ?? cs.primary).withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: (color ?? cs.primary).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: color ?? cs.primary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                  color: color ?? cs.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShowcaseRow extends StatelessWidget {
  final List<Widget> children;
  const _ShowcaseRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: children,
    );
  }
}

// ─── Pagination Wrapper Showcase ──────────────────────────────────────────────
class _PaginationWrapperShowcase extends StatefulWidget {
  @override
  State<_PaginationWrapperShowcase> createState() => _PaginationWrapperShowcaseState();
}

class _PaginationWrapperShowcaseState extends State<_PaginationWrapperShowcase> {
  final PaginationController<String> _controller = PaginationController<String>();
  final TextEditingController _searchCtrl = TextEditingController();
  bool _simulateError = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      final query = _searchCtrl.text.trim().toLowerCase();
      if (query.isEmpty) {
        _controller.clearFilter();
      } else {
        _controller.updateFilteredList(
          (items) => items.where((item) => item.toLowerCase().contains(query)).toList(),
        );
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<List<String>> _fetchData(int page, int pageSize) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network latency
    if (_simulateError && page > 1) {
      throw Exception('Simulated load more network failure');
    }
    return List.generate(
      pageSize,
      (index) => 'Page $page - Product Item #${(page - 1) * pageSize + index + 1}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        // Control Bar
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  labelText: 'Search items locally',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _simulateError,
                        onChanged: (v) => setState(() => _simulateError = v ?? false),
                      ),
                      Text('Simulate Load More Error', style: TextStyle(fontSize: 12, color: colors.onSurface)),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                        tooltip: 'Scroll to top',
                        onPressed: _controller.scrollToTop,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        tooltip: 'Refresh',
                        onPressed: _controller.refresh,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // Pagination List
        Expanded(
          child: PaginationWrapper<String>.builder(
            controller: _controller,
            fetchData: _fetchData,
            pageSize: 10,
            debugMode: true,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            separated: true,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, item) => Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
              elevation: 0,
              color: colors.surfaceContainerLow ?? colors.surfaceVariant.withOpacity(0.15),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: colors.primary.withOpacity(0.1),
                  child: Icon(Icons.shopping_bag_outlined, color: colors.primary, size: 20),
                ),
                title: Text(item, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Enterprise ready catalog item'),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
