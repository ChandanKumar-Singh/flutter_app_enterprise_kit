import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';
import 'package:enterprise_kit/shared/validators/form_validators.dart';
import 'package:enterprise_kit/shared/widgets/buttons/app_button.dart';
import 'package:enterprise_kit/shared/widgets/inputs/app_text_field.dart';

class InputsShowcasePage extends StatefulWidget {
  const InputsShowcasePage({super.key});
  @override State<InputsShowcasePage> createState() => _InputsShowcasePageState();
}

class _InputsShowcasePageState extends State<InputsShowcasePage> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inputs')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            AppTextField.email(validator: FormValidators.requiredEmail()),
            const SizedBox(height: AppSpacing.md),
            AppTextField.password(validator: FormValidators.requiredPassword()),
            const SizedBox(height: AppSpacing.md),
            AppTextField.phone(validator: FormValidators.requiredPhone()),
            const SizedBox(height: AppSpacing.md),
            AppTextField.search(),
            const SizedBox(height: AppSpacing.md),
            AppTextField.multiline(label: 'Notes', hint: 'Write something...', maxLength: 500, showCharacterCount: true),
            const SizedBox(height: AppSpacing.md),
            AppTextField.number(label: 'Amount', hint: '0.00', allowDecimals: true, suffixIcon: const Icon(Iconsax.wallet_money)),
            const SizedBox(height: AppSpacing.md),
            const AppTextField(label: 'Read Only', initialValue: 'Cannot edit this', readOnly: true),
            const SizedBox(height: AppSpacing.md),
            const AppTextField(label: 'Disabled', initialValue: 'Disabled field', enabled: false),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'With Helper & Error',
              hint: 'Type something...',
              helper: 'This is helper text',
              validator: FormValidators.minLength(5),
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton.filled(label: 'Validate Form', onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Form is valid!')));
              }
            }),
          ],
        ),
      ),
    );
  }
}
