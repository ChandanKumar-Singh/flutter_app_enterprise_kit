import 'package:flutter/material.dart';
import 'package:enterprise_kit/core/theme/tokens/app_spacing.dart';
import 'package:enterprise_kit/shared/widgets/states/app_state_widget.dart';

class StatesShowcasePage extends StatefulWidget {
  const StatesShowcasePage({super.key});
  @override State<StatesShowcasePage> createState() => _StatesShowcasePageState();
}

class _StatesShowcasePageState extends State<StatesShowcasePage> {
  AppStateType _current = AppStateType.empty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('States')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Wrap(spacing: 8, runSpacing: 8, children: AppStateType.values.where((t) => t != AppStateType.loading).map((t) =>
              ChoiceChip(
                label: Text(t.name),
                selected: _current == t,
                onSelected: (_) => setState(() => _current = t),
              ),
            ).toList()),
          ),
          const Divider(height: 1),
          Expanded(child: _current == AppStateType.loading
              ? AppStateWidget.loading(message: 'Fetching data...')
              : switch (_current) {
                  AppStateType.empty => AppStateWidget.empty(title: 'Nothing here', message: 'Add your first item to get started.', actionLabel: 'Add Item', onAction: () {}),
                  AppStateType.error => AppStateWidget.error(message: 'Failed to load data.', onRetry: () {}),
                  AppStateType.noConnection => AppStateWidget.noConnection(onRetry: () {}),
                  AppStateType.noResults => AppStateWidget.noResults(query: 'flutter enterprise'),
                  AppStateType.comingSoon => const AppStateWidget(type: AppStateType.comingSoon),
                  AppStateType.accessDenied => const AppStateWidget(type: AppStateType.accessDenied),
                  _ => const SizedBox(),
                },
          ),
        ],
      ),
    );
  }
}
