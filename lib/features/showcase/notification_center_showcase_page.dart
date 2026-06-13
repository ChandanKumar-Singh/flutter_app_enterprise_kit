// ─── NotificationCenterShowcasePage ──────────────────────────────────────────
// Live demo of AppNotificationCenter with rich sample data covering
// every card variant, type, category, and priority.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:enterprise_kit/core/notification_center/index.dart';

class NotificationCenterShowcasePage extends StatefulWidget {
  const NotificationCenterShowcasePage({super.key});

  @override
  State<NotificationCenterShowcasePage> createState() =>
      _NotificationCenterShowcasePageState();
}

class _NotificationCenterShowcasePageState
    extends State<NotificationCenterShowcasePage> {
  // Local controller — not the singleton — so showcase is isolated
  final _ctrl = AppNotificationController(config: AppNotificationConfig.enterprise);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Simulate a short load delay, then inject rich demo data
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      _ctrl.addAll(_buildDemoNotifications());
      setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppNotificationCenterPage(
      controller: _ctrl,
      isLoading: _loading,
    );
  }
}

// ── Demo data factory ─────────────────────────────────────────────────────────

List<AppNotification> _buildDemoNotifications() {
  final now = DateTime.now();

  return [
    // ── Today ────────────────────────────────────────────────────────────

    // Action card — approval needed
    AppNotification(
      id: 'n01',
      title: 'Budget approval required',
      body: 'Q3 marketing budget of ₹4,50,000 is pending your approval.',
      type: AppNotificationType.approval,
      category: AppNotificationCategory.tasks,
      priority: AppNotificationPriority.critical,
      cardVariant: AppNotificationCardVariant.action,
      createdAt: now.subtract(const Duration(minutes: 5)),
      isRead: false,
      sender: const AppNotificationSender(id: 's1', name: 'Priya Sharma', role: 'Finance Head'),
      actions: [AppNotificationAction.approve, AppNotificationAction.reject],
    ),

    // Security alert
    AppNotification(
      id: 'n02',
      title: 'New login from unknown device',
      body: 'Chrome on Windows · Bengaluru, Karnataka · 192.168.1.104',
      type: AppNotificationType.security,
      category: AppNotificationCategory.security,
      priority: AppNotificationPriority.critical,
      cardVariant: AppNotificationCardVariant.standard,
      createdAt: now.subtract(const Duration(minutes: 18)),
      isRead: false,
      metadata: {'ip': '192.168.1.104', 'device': 'Chrome / Windows'},
    ),

    // Chat mention
    AppNotification(
      id: 'n03',
      title: 'Akshit mentioned you in #design',
      body: '@you Can you review the new onboarding flow by EOD?',
      type: AppNotificationType.mention,
      category: AppNotificationCategory.messages,
      priority: AppNotificationPriority.high,
      cardVariant: AppNotificationCardVariant.chat,
      createdAt: now.subtract(const Duration(minutes: 32)),
      isRead: false,
      sender: const AppNotificationSender(id: 's2', name: 'Akshit Singh', role: 'Workspace Owner'),
    ),

    // Payment success
    AppNotification(
      id: 'n04',
      title: 'Payment received',
      body: 'HDFC Bank · ₹12,500.00 credited to your account',
      type: AppNotificationType.payment,
      category: AppNotificationCategory.finance,
      priority: AppNotificationPriority.normal,
      cardVariant: AppNotificationCardVariant.standard,
      createdAt: now.subtract(const Duration(hours: 1)),
      isRead: true,
      groupKey: 'payment',
      metadata: {'amount': '₹12,500.00', 'bank': 'HDFC'},
    ),

    // Payment 2 (for smart grouping demo)
    AppNotification(
      id: 'n05',
      title: 'Payment received',
      body: 'ICICI Bank · ₹8,200.00 credited to your account',
      type: AppNotificationType.payment,
      category: AppNotificationCategory.finance,
      priority: AppNotificationPriority.normal,
      cardVariant: AppNotificationCardVariant.standard,
      createdAt: now.subtract(const Duration(hours: 1, minutes: 20)),
      isRead: true,
      groupKey: 'payment',
    ),

    // Payment 3 (completes the smart group)
    AppNotification(
      id: 'n06',
      title: 'Payment received',
      body: 'Axis Bank · ₹6,750.00 credited',
      type: AppNotificationType.payment,
      category: AppNotificationCategory.finance,
      priority: AppNotificationPriority.normal,
      cardVariant: AppNotificationCardVariant.compact,
      createdAt: now.subtract(const Duration(hours: 1, minutes: 45)),
      isRead: true,
      groupKey: 'payment',
    ),

    // Order timeline
    AppNotification(
      id: 'n07',
      title: 'Order #ORD-2024-8821 update',
      body: 'Your order is out for delivery.',
      type: AppNotificationType.info,
      category: AppNotificationCategory.updates,
      priority: AppNotificationPriority.normal,
      cardVariant: AppNotificationCardVariant.timeline,
      createdAt: now.subtract(const Duration(hours: 2)),
      isRead: false,
      isPinned: true,
      timelineSteps: const [
        AppNotificationTimelineStep(label: 'Order placed', isCompleted: true),
        AppNotificationTimelineStep(label: 'Order confirmed', isCompleted: true),
        AppNotificationTimelineStep(label: 'Packed & dispatched', isCompleted: true),
        AppNotificationTimelineStep(label: 'Out for delivery', isCompleted: true),
        AppNotificationTimelineStep(label: 'Delivered', isCompleted: false),
      ],
    ),

    // Rich card with image
    AppNotification(
      id: 'n08',
      title: 'System maintenance scheduled',
      body: 'Planned downtime on Saturday, 15 Jun from 02:00–04:00 IST. Save your work before this window.',
      type: AppNotificationType.maintenance,
      category: AppNotificationCategory.system,
      priority: AppNotificationPriority.high,
      cardVariant: AppNotificationCardVariant.rich,
      createdAt: now.subtract(const Duration(hours: 3)),
      isRead: false,
      actions: [
        const AppNotificationAction(id: 'remind', label: 'Remind me', icon: Iconsax.clock),
        const AppNotificationAction(id: 'dismiss', label: 'Dismiss', style: AppNotificationActionStyle.secondary),
      ],
    ),

    // ── Yesterday ─────────────────────────────────────────────────────────

    AppNotification(
      id: 'n09',
      title: 'New comment on your pull request',
      body: 'Rohan: "The cache invalidation logic needs to handle race conditions."',
      type: AppNotificationType.comment,
      category: AppNotificationCategory.messages,
      priority: AppNotificationPriority.normal,
      cardVariant: AppNotificationCardVariant.chat,
      createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      isRead: true,
      isStarred: true,
      sender: const AppNotificationSender(id: 's3', name: 'Rohan Verma', role: 'Senior Engineer'),
    ),

    AppNotification(
      id: 'n10',
      title: 'Invoice #INV-2024-001 generated',
      body: 'Total: ₹85,000.00 · Due: 30 Jun 2024 · Client: Infosys Ltd',
      type: AppNotificationType.transaction,
      category: AppNotificationCategory.finance,
      priority: AppNotificationPriority.normal,
      cardVariant: AppNotificationCardVariant.standard,
      createdAt: now.subtract(const Duration(days: 1, hours: 5)),
      isRead: true,
      deepLink: '/finance/invoices/INV-2024-001',
      metadata: {'invoice': 'INV-2024-001', 'amount': '₹85,000'},
    ),

    AppNotification(
      id: 'n11',
      title: 'Task assigned to you',
      body: 'Implement dark mode for the dashboard module',
      type: AppNotificationType.assignment,
      category: AppNotificationCategory.tasks,
      priority: AppNotificationPriority.high,
      cardVariant: AppNotificationCardVariant.standard,
      createdAt: now.subtract(const Duration(days: 1, hours: 8)),
      isRead: false,
      sender: const AppNotificationSender(id: 's4', name: 'Nisha Patel', role: 'Product Manager'),
      deepLink: '/tasks/dashboard-dark-mode',
    ),

    // ── This week ─────────────────────────────────────────────────────────

    AppNotification(
      id: 'n12',
      title: 'Enterprise Kit v2.1.0 released',
      body: 'New features: AppNavigationFramework, AppNotificationCenter, AppToast redesign.',
      type: AppNotificationType.systemUpdate,
      category: AppNotificationCategory.updates,
      priority: AppNotificationPriority.normal,
      cardVariant: AppNotificationCardVariant.standard,
      createdAt: now.subtract(const Duration(days: 3)),
      isRead: true,
    ),

    AppNotification(
      id: 'n13',
      title: 'Login from new browser',
      body: 'Safari on macOS · Mumbai, Maharashtra · verified',
      type: AppNotificationType.security,
      category: AppNotificationCategory.security,
      priority: AppNotificationPriority.high,
      cardVariant: AppNotificationCardVariant.standard,
      createdAt: now.subtract(const Duration(days: 4)),
      isRead: true,
    ),

    AppNotification(
      id: 'n14',
      title: 'Monthly report ready',
      body: 'May 2024 performance report is ready to download.',
      type: AppNotificationType.announcement,
      category: AppNotificationCategory.updates,
      priority: AppNotificationPriority.low,
      cardVariant: AppNotificationCardVariant.compact,
      createdAt: now.subtract(const Duration(days: 5)),
      isRead: true,
      actions: [AppNotificationAction.view],
    ),

    AppNotification(
      id: 'n15',
      title: 'Team standup reminder',
      body: 'Daily sync in 15 minutes · Meet link in calendar',
      type: AppNotificationType.reminder,
      category: AppNotificationCategory.tasks,
      priority: AppNotificationPriority.normal,
      cardVariant: AppNotificationCardVariant.compact,
      createdAt: now.subtract(const Duration(days: 6)),
      isRead: true,
    ),
  ];
}
