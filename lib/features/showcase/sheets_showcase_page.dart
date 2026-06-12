import 'package:flutter/material.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';
import 'package:enterprise_kit/shared/widgets/buttons/app_button.dart';
import 'package:enterprise_kit/shared/widgets/sheets/app_sheet.dart';

class SheetsShowcasePage extends StatelessWidget {
  const SheetsShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sheets')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppButton.outlined(label: 'Standard Sheet', onPressed: () => AppSheet.show(context, title: 'Standard Sheet', child: const Padding(padding: EdgeInsets.all(16), child: Text('Standard bottom sheet content. Dismiss by tapping outside or dragging down.')))),
          const SizedBox(height: 8),
          AppButton.outlined(label: 'Scrollable / Draggable Sheet', onPressed: () => AppSheet.scrollable(context, title: 'Draggable Sheet', builder: (ctx, ctrl) => ListView.builder(controller: ctrl, itemCount: 30, itemBuilder: (_, i) => ListTile(title: Text('Item ${i+1}'))))),
          const SizedBox(height: 8),
          AppButton.outlined(label: 'Full Screen Sheet', onPressed: () => AppSheet.fullScreen(context, title: 'Full Screen', child: const Center(child: Text('Full screen sheet content')))),
          const SizedBox(height: 8),
          AppButton.outlined(label: 'Dialog Sheet', onPressed: () => AppSheet.dialog(context, title: 'Confirm Action', child: const Text('This sheet looks and behaves like a dialog but comes from the bottom.'), confirmLabel: 'OK', cancelLabel: 'Cancel')),
          const SizedBox(height: 8),
          AppButton.outlined(label: 'Action Sheet', onPressed: () => AppSheet.actions(context, title: 'Options', actions: [
            AppSheetAction(label: 'Edit', icon: Icons.edit_outlined, value: 'edit'),
            AppSheetAction(label: 'Share', icon: Icons.share_outlined, value: 'share'),
            AppSheetAction(label: 'Delete', icon: Icons.delete_outline, value: 'delete', isDestructive: true),
          ], cancelAction: const AppSheetAction(label: 'Cancel', value: null))),
          const SizedBox(height: 8),
          AppButton.outlined(label: 'Confirm Sheet', onPressed: () => AppSheet.confirm(context, title: 'Are you sure?', message: 'This will permanently delete your account and all data.', confirmLabel: 'Delete Account', isDestructive: true, icon: const Icon(Icons.warning_amber_outlined, size: 48, color: Colors.orange))),
        ],
      ),
    );
  }
}
