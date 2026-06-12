import 'package:flutter/material.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';
import 'package:enterprise_kit/shared/widgets/buttons/app_button.dart';
import 'package:enterprise_kit/shared/widgets/dialogs/app_dialog.dart';

class DialogsShowcasePage extends StatelessWidget {
  const DialogsShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dialogs')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppButton.outlined(label: 'Basic Dialog', onPressed: () => AppDialog.show(context, title: 'Info', message: 'This is a basic informational dialog.')),
          const SizedBox(height: 8),
          AppButton.outlined(label: 'Confirm Dialog', onPressed: () async {
            final r = await AppDialog.confirm(context, title: 'Confirm', message: 'Are you sure you want to proceed?');
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Result: $r')));
          }),
          const SizedBox(height: 8),
          AppButton.outlined(label: 'Danger/Delete Dialog', onPressed: () => AppDialog.danger(context, title: 'Delete Item', message: 'This action cannot be undone. The item will be permanently deleted.')),
          const SizedBox(height: 8),
          AppButton.outlined(label: 'Input Dialog', onPressed: () async {
            final val = await AppDialog.input(context, title: 'Enter Name', hint: 'John Appleseed', label: 'Full Name');
            if (context.mounted && val != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Input: $val')));
          }),
          const SizedBox(height: 8),
          AppButton.outlined(label: 'Success Dialog', onPressed: () => AppDialog.success(context, title: 'Saved!', message: 'Your changes have been saved successfully.')),
          const SizedBox(height: 8),
          AppButton.outlined(label: 'Error Dialog', onPressed: () => AppDialog.error(context, title: 'Something went wrong', message: 'An unexpected error occurred.', details: 'Error code: 500\nNullPointerException at line 42')),
          const SizedBox(height: 8),
          AppButton.outlined(label: 'Warning Dialog', onPressed: () => AppDialog.warning(context, title: 'Warning', message: 'This action may cause data loss.')),
          const SizedBox(height: 8),
          AppButton.outlined(label: 'Loading Dialog (2s)', onPressed: () => AppDialog.loading(context, message: 'Processing...', future: Future.delayed(const Duration(seconds: 2)))),
          const SizedBox(height: 8),
          AppButton.outlined(label: 'Full Screen Dialog', onPressed: () => AppDialog.fullScreen(context, child: Scaffold(appBar: AppBar(title: const Text('Full Screen'), leading: BackButton()), body: const Center(child: Text('Full screen dialog content'))))),
        ],
      ),
    );
  }
}
