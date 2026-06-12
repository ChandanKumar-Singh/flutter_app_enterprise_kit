// ─── AppWizardFlow ────────────────────────────────────────────────────────────
// Multi-step progressive disclosure wizard.
//
// Used for: onboarding, KYC, checkout, multi-part forms, guided setup.
//
// Features:
//   • Animated step transitions (slide + fade)
//   • Per-step validation guard (can block Next)
//   • Skip support per step
//   • Progress indicator (linear + step dots)
//   • Back navigation (optionally disabled per step)
//   • Completion callback
//   • AppWizardController for external control (Riverpod-compatible)
//
// Usage:
//   AppWizard(
//     steps: [
//       AppWizardStep(
//         title: 'Personal Info',
//         subtitle: 'Tell us about yourself',
//         icon: Icons.person_rounded,
//         canSkip: false,
//         validate: () => _nameController.text.isNotEmpty,
//         builder: (ctx, controller) => PersonalInfoForm(),
//       ),
//       AppWizardStep(
//         title: 'Verification',
//         builder: (ctx, controller) => OtpVerificationStep(),
//       ),
//     ],
//     onCompleted: () => router.go('/home'),
//   )
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';

// ── Step model ────────────────────────────────────────────────────────────────

class AppWizardStep {
  final String title;
  final String? subtitle;
  final IconData? icon;

  /// Return true to allow advancing to the next step.
  final bool Function()? validate;

  /// If true, a "Skip" button is shown.
  final bool canSkip;

  /// If false, the back button is hidden for this step.
  final bool canGoBack;

  /// Custom label for the "Next" button on this step.
  final String? nextLabel;

  final Widget Function(BuildContext context, AppWizardController controller)
      builder;

  const AppWizardStep({
    required this.title,
    this.subtitle,
    this.icon,
    this.validate,
    this.canSkip = false,
    this.canGoBack = true,
    this.nextLabel,
    required this.builder,
  });
}

// ── Controller ────────────────────────────────────────────────────────────────

class AppWizardController extends ChangeNotifier {
  AppWizardController({required int stepCount})
      : _stepCount = stepCount,
        _currentIndex = 0;

  final int _stepCount;
  int _currentIndex;
  final _skippedSteps = <int>{};

  int get currentIndex => _currentIndex;
  int get stepCount => _stepCount;
  bool get isFirst => _currentIndex == 0;
  bool get isLast => _currentIndex == _stepCount - 1;
  double get progress => _stepCount == 0 ? 0 : (_currentIndex + 1) / _stepCount;
  Set<int> get skippedSteps => Set.unmodifiable(_skippedSteps);

  bool wasSkipped(int index) => _skippedSteps.contains(index);

  void next() {
    if (_currentIndex < _stepCount - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void previous() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  void skipCurrent() {
    _skippedSteps.add(_currentIndex);
    next();
  }

  void jumpTo(int index) {
    assert(index >= 0 && index < _stepCount);
    _currentIndex = index;
    notifyListeners();
  }
}

// ── Wizard widget ─────────────────────────────────────────────────────────────

class AppWizard extends StatefulWidget {
  final List<AppWizardStep> steps;
  final VoidCallback? onCompleted;
  final VoidCallback? onCancelled;

  /// Called when user taps Next — before advancing. Return false to block.
  final Future<bool> Function(int stepIndex)? onStepValidate;

  /// Show or hide the linear progress bar at the top.
  final bool showProgressBar;

  /// Show or hide step counter chips below the title.
  final bool showStepIndicator;

  /// Padding around step content.
  final EdgeInsetsGeometry contentPadding;

  const AppWizard({
    super.key,
    required this.steps,
    this.onCompleted,
    this.onCancelled,
    this.onStepValidate,
    this.showProgressBar = true,
    this.showStepIndicator = true,
    this.contentPadding = const EdgeInsets.all(AppSpacing.xl),
  });

  @override
  State<AppWizard> createState() => _AppWizardState();
}

class _AppWizardState extends State<AppWizard>
    with SingleTickerProviderStateMixin {
  late final AppWizardController _controller;
  late final AnimationController _animCtrl;
  int _prevIndex = 0;
  bool _forward = true;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _controller = AppWizardController(stepCount: widget.steps.length);
    _controller.addListener(_onStepChanged);
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  void _onStepChanged() {
    _forward = _controller.currentIndex > _prevIndex;
    _prevIndex = _controller.currentIndex;
    _animCtrl.forward(from: 0);
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onStepChanged);
    _controller.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    final step = widget.steps[_controller.currentIndex];
    // Local validate
    if (step.validate != null && !step.validate!()) {
      HapticFeedback.lightImpact();
      return;
    }
    // External async validate
    if (widget.onStepValidate != null) {
      setState(() => _isValidating = true);
      final allowed = await widget.onStepValidate!(_controller.currentIndex);
      setState(() => _isValidating = false);
      if (!allowed) return;
    }

    if (_controller.isLast) {
      widget.onCompleted?.call();
    } else {
      HapticFeedback.selectionClick();
      _controller.next();
    }
  }

  void _handleBack() {
    if (_controller.isFirst) {
      widget.onCancelled?.call();
    } else {
      HapticFeedback.selectionClick();
      _controller.previous();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final step = widget.steps[_controller.currentIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Progress bar ──────────────────────────────────────────────────
        if (widget.showProgressBar)
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            tween: Tween(begin: 0, end: _controller.progress),
            builder: (_, value, __) => LinearProgressIndicator(
              value: value,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(cs.primary),
              minHeight: 3,
            ),
          ),

        // ── Header ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step dots
              if (widget.showStepIndicator)
                _StepDots(
                  count: widget.steps.length,
                  current: _controller.currentIndex,
                  color: cs.primary,
                ),
              const SizedBox(height: AppSpacing.md),
              // Icon
              if (step.icon != null) ...[
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(step.icon, color: cs.primary, size: 28),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              // Title
              Text(
                step.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (step.subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  step.subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),

        // ── Step content (animated) ───────────────────────────────────────
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) {
              final slide = Tween<Offset>(
                begin: Offset(_forward ? 0.08 : -0.08, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(_controller.currentIndex),
              child: SingleChildScrollView(
                padding: widget.contentPadding,
                child: step.builder(context, _controller),
              ),
            ),
          ),
        ),

        // ── Footer buttons ────────────────────────────────────────────────
        _WizardFooter(
          controller: _controller,
          step: step,
          isValidating: _isValidating,
          onNext: _handleNext,
          onBack: _handleBack,
          onSkip: () {
            HapticFeedback.selectionClick();
            _controller.skipCurrent();
          },
        ),
      ],
    );
  }
}

// ── Step dots ─────────────────────────────────────────────────────────────────

class _StepDots extends StatelessWidget {
  final int count;
  final int current;
  final Color color;

  const _StepDots({
    required this.count,
    required this.current,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == current;
        final isDone = i < current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: isActive ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: isDone
                ? color.withOpacity(0.4)
                : isActive
                    ? color
                    : color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: isDone
              ? null
              : null,
        );
      }),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _WizardFooter extends StatelessWidget {
  final AppWizardController controller;
  final AppWizardStep step;
  final bool isValidating;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  const _WizardFooter({
    required this.controller,
    required this.step,
    required this.isValidating,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLast = controller.isLast;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xl + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: cs.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Back
          if (step.canGoBack && !controller.isFirst)
            OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: const Icon(Icons.arrow_back_rounded),
            ),
          if (step.canGoBack && !controller.isFirst)
            const SizedBox(width: AppSpacing.md),

          // Skip
          if (step.canSkip)
            TextButton(
              onPressed: onSkip,
              child: const Text('Skip'),
            ),
          if (step.canSkip) const SizedBox(width: AppSpacing.md),

          const Spacer(),

          // Next / Finish
          FilledButton(
            onPressed: isValidating ? null : onNext,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: isValidating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        step.nextLabel ?? (isLast ? 'Finish' : 'Next'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (!isLast) ...[
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ── AppWizardPage ─────────────────────────────────────────────────────────────
// Full Scaffold wrapper for wizard used as a standalone page.

class AppWizardPage extends StatelessWidget {
  final String? title;
  final List<AppWizardStep> steps;
  final VoidCallback? onCompleted;
  final VoidCallback? onCancelled;
  final Future<bool> Function(int stepIndex)? onStepValidate;
  final bool showProgressBar;

  const AppWizardPage({
    super.key,
    this.title,
    required this.steps,
    this.onCompleted,
    this.onCancelled,
    this.onStepValidate,
    this.showProgressBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title != null
          ? AppBar(
              title: Text(title!),
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: onCancelled ?? () => Navigator.of(context).maybePop(),
              ),
            )
          : null,
      body: AppWizard(
        steps: steps,
        onCompleted: onCompleted,
        onCancelled: onCancelled ?? () => Navigator.of(context).maybePop(),
        onStepValidate: onStepValidate,
        showProgressBar: showProgressBar,
      ),
    );
  }
}
