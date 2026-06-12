import 'package:flutter/material.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';
import 'package:enterprise_kit/shared/extensions/string_extensions.dart';
import 'package:enterprise_kit/shared/extensions/datetime_extensions.dart';
import 'package:enterprise_kit/shared/formatters/app_formatters.dart';
import 'package:enterprise_kit/shared/helpers/app_helpers.dart';
import 'package:enterprise_kit/shared/widgets/buttons/app_button.dart';
import 'package:enterprise_kit/shared/widgets/dialogs/app_dialog.dart';

class UtilsShowcasePage extends StatelessWidget {
  const UtilsShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: const Text('Utilities')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _label(context, 'String Extensions'),
          _row('isEmail', 'user@test.com'.isEmail.toString()),
          _row('capitalize', 'hello world'.capitalize),
          _row('titleCase', 'flutter enterprise kit'.titleCase),
          _row('initials', 'John Appleseed'.initials),
          _row('truncate(20)', 'The quick brown fox jumps over the lazy dog'.truncate(20)),
          _row('mask()', '+14155551234'.mask(visibleStart: 2, visibleEnd: 4)),
          _row('wordCount', 'The quick brown fox'.wordCount.toString()),
          _row('camelCase', 'my_variable_name'.camelCase),
          _row('isStrongPassword', 'Secure@123'.isStrongPassword.toString()),

          const SizedBox(height: AppSpacing.lg),
          _label(context, 'DateTime Extensions'),
          _row('isToday', now.isToday.toString()),
          _row('formatted', now.formatted),
          _row('formattedFull', now.formattedFull),
          _row('timeAgo', now.subtract(const Duration(minutes: 45)).timeAgo),
          _row('monthName', now.monthName),
          _row('dayName', now.dayName),
          _row('weekOfYear', now.weekOfYear.toString()),
          _row('quarter', 'Q${now.quarter}'),
          _row('daysInMonth', now.daysInMonth.toString()),
          _row('startOfWeek', now.startOfWeek.formatted),
          _row('endOfMonth', now.endOfMonth.formatted),

          const SizedBox(height: AppSpacing.lg),
          _label(context, 'Formatters'),
          _row('currency(\$1234.5)', AppFormatter.currency(1234.5)),
          _row('compact(1250000)', AppFormatter.compact(1250000)),
          _row('percentage(0.742)', AppFormatter.percentage(74.2)),
          _row('fileSize(15728640)', AppFormatter.fileSize(15728640)),
          _row('phone()', AppFormatter.phone('4155551234')),
          _row('creditCard()', AppFormatter.creditCard('4111111111111111')),
          _row('maskedCard()', AppFormatter.maskedCard('4111111111111111')),
          _row('ordinal(21)', AppFormatter.ordinal(21)),
          _row('relativeDate', AppFormatter.relativeDate(now.subtract(const Duration(hours: 3)))),

          const SizedBox(height: AppSpacing.lg),
          _label(context, 'Helpers'),
          AppButton.outlined(label: 'Copy to Clipboard', onPressed: () async {
            await AppHelpers.copyToClipboard('Enterprise Kit — copied!');
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!')));
          }),
          const SizedBox(height: 8),
          AppButton.outlined(label: 'Haptic Feedback', onPressed: AppHelpers.hapticMedium),
          const SizedBox(height: 8),
          AppButton.outlined(label: 'Generate UUID', onPressed: () async {
            final id = AppHelpers.uuid();
            if (context.mounted) await AppDialog.show(context, title: 'UUID', message: id);
          }),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: 4),
    child: Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 160, child: Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.grey))),
        Expanded(child: Text(value,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w500))),
      ],
    ),
  );
}
