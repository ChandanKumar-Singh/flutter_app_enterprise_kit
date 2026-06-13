// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';
import 'package:enterprise_kit/shared/widgets/buttons/app_button.dart';

// ─── Step Model ───────────────────────────────────────────────────────────────
class AppStep {
  final String title;
  final String? subtitle;
  final Widget content;
  final Widget? icon;
  final bool optional;
  final Future<bool> Function()? validator;

  const AppStep({
    required this.title,
    this.subtitle,
    required this.content,
    this.icon,
    this.optional = false,
    this.validator,
  });
}

// ─── Stepper Layout ───────────────────────────────────────────────────────────
enum AppStepperLayout { horizontal, vertical }
enum AppStepperType { linear, nonLinear }

// ─── App Stepper ──────────────────────────────────────────────────────────────
class AppStepper extends StatefulWidget {
  final List<AppStep> steps;
  final AppStepperLayout layout;
  final AppStepperType type;
  final int? initialStep;
  final void Function(int)? onStepChanged;
  final Future<void> Function()? onComplete;
  final String nextLabel;
  final String backLabel;
  final String completeLabel;
  final bool showProgress;
  final bool showStepNumbers;
  final bool animated;
  final EdgeInsetsGeometry? contentPadding;

  const AppStepper({
    super.key,
    required this.steps,
    this.layout = AppStepperLayout.vertical,
    this.type = AppStepperType.linear,
    this.initialStep,
    this.onStepChanged,
    this.onComplete,
    this.nextLabel = 'Next',
    this.backLabel = 'Back',
    this.completeLabel = 'Complete',
    this.showProgress = true,
    this.showStepNumbers = true,
    this.animated = true,
    this.contentPadding,
  });

  @override
  State<AppStepper> createState() => _AppStepperState();
}

class _AppStepperState extends State<AppStepper> {
  late int _currentStep;
  bool _isCompleting = false;
  final Set<int> _completed = {};
  final Set<int> _errored = {};

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep ?? 0;
  }

  bool get _isLastStep => _currentStep == widget.steps.length - 1;

  Future<void> _goNext() async {
    final step = widget.steps[_currentStep];
    if (step.validator != null) {
      final valid = await step.validator!();
      if (!valid) {
        setState(() => _errored.add(_currentStep));
        return;
      }
    }
    _errored.remove(_currentStep);
    _completed.add(_currentStep);
    if (_isLastStep) {
      setState(() => _isCompleting = true);
      await widget.onComplete?.call();
      setState(() => _isCompleting = false);
    } else {
      setState(() => _currentStep++);
      widget.onStepChanged?.call(_currentStep);
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      widget.onStepChanged?.call(_currentStep);
    }
  }

  void _goTo(int step) {
    if (widget.type == AppStepperType.nonLinear ||
        _completed.contains(step) ||
        step == _currentStep) {
      setState(() => _currentStep = step);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        if (widget.showProgress)
          _ProgressBar(
            current: _currentStep,
            total: widget.steps.length,
            completed: _completed.length,
          ),
        const SizedBox(height: AppSpacing.md),
        // Step indicators
        _StepIndicators(
          steps: widget.steps,
          current: _currentStep,
          completed: _completed,
          errored: _errored,
          layout: widget.layout,
          showNumbers: widget.showStepNumbers,
          onStepTap: widget.type == AppStepperType.nonLinear ? _goTo : null,
          cs: cs,
        ),
        const SizedBox(height: AppSpacing.md),
        // Content
        Expanded(
          child: _StepContent(
            key: ValueKey(_currentStep),
            step: widget.steps[_currentStep],
            animated: widget.animated,
            padding: widget.contentPadding,
          ),
        ),
        // Navigation
        _StepNavigation(
          isFirst: _currentStep == 0,
          isLast: _isLastStep,
          isCompleting: _isCompleting,
          nextLabel: _isLastStep ? widget.completeLabel : widget.nextLabel,
          backLabel: widget.backLabel,
          onNext: _goNext,
          onBack: _goBack,
          step: widget.steps[_currentStep],
        ),
      ],
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final int current;
  final int total;
  final int completed;

  const _ProgressBar({required this.current, required this.total, required this.completed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = (current + 1) / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step ${current + 1} of $total',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: cs.primary.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation(cs.primary),
          ),
        ),
      ],
    );
  }
}

class _StepIndicators extends StatelessWidget {
  final List<AppStep> steps;
  final int current;
  final Set<int> completed;
  final Set<int> errored;
  final AppStepperLayout layout;
  final bool showNumbers;
  final void Function(int)? onStepTap;
  final ColorScheme cs;

  const _StepIndicators({
    required this.steps,
    required this.current,
    required this.completed,
    required this.errored,
    required this.layout,
    required this.showNumbers,
    required this.onStepTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: steps.asMap().entries.map((entry) {
        final i = entry.key;
        final step = entry.value;
        final isCompleted = completed.contains(i);
        final isErrored = errored.contains(i);
        final isCurrent = i == current;

        Color nodeColor;
        Widget nodeChild;

        if (isErrored) {
          nodeColor = cs.error;
          nodeChild = const Icon(Iconsax.close_circle, size: 14, color: Colors.white);
        } else if (isCompleted) {
          nodeColor = const Color(0xFF16A34A);
          nodeChild = const Icon(Iconsax.tick_circle, size: 14, color: Colors.white);
        } else if (isCurrent) {
          nodeColor = cs.primary;
          nodeChild = showNumbers
              ? Text('${i + 1}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white))
              : step.icon ?? Icon(Iconsax.record, size: 8, color: cs.onPrimary);
        } else {
          nodeColor = cs.surfaceVariant;
          nodeChild = showNumbers
              ? Text('${i + 1}',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant))
              : Icon(Iconsax.record, size: 8, color: cs.onSurfaceVariant);
        }

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: onStepTap != null ? () => onStepTap!(i) : null,
                      child: AnimatedContainer(
                        duration: 200.ms,
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: nodeColor,
                          shape: BoxShape.circle,
                          border: isCurrent
                              ? Border.all(color: cs.primary.withOpacity(0.3), width: 3)
                              : null,
                        ),
                        child: Center(child: nodeChild),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.title,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isCurrent ? cs.primary : cs.onSurfaceVariant,
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.normal,
                          ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          isCompleted ? const Color(0xFF16A34A) : cs.outlineVariant,
                          i + 1 == current ? cs.primary : cs.outlineVariant,
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StepContent extends StatelessWidget {
  final AppStep step;
  final bool animated;
  final EdgeInsetsGeometry? padding;

  const _StepContent({super.key, required this.step, required this.animated, this.padding});

  @override
  Widget build(BuildContext context) {
    Widget content = SingleChildScrollView(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      child: step.content,
    );

    if (animated) {
      content = content
          .animate()
          .fadeIn(duration: 250.ms)
          .slideX(begin: 0.05, end: 0, duration: 250.ms, curve: Curves.easeOut);
    }

    return content;
  }
}

class _StepNavigation extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final bool isCompleting;
  final String nextLabel;
  final String backLabel;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final AppStep step;

  const _StepNavigation({
    required this.isFirst,
    required this.isLast,
    required this.isCompleting,
    required this.nextLabel,
    required this.backLabel,
    required this.onNext,
    required this.onBack,
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          if (!isFirst)
            Expanded(
              child: AppButton.outlined(
                label: backLabel,
                onPressed: onBack,
                size: AppButtonSize.md,
              ),
            ),
          if (!isFirst) const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: AppButton.filled(
              label: nextLabel,
              onPressed: onNext,
              isLoading: isCompleting,
              size: AppButtonSize.md,
              icon: isLast ? const Icon(Iconsax.tick_circle, size: 18) : null,
            ),
          ),
        ],
      ),
    );
  }
}
