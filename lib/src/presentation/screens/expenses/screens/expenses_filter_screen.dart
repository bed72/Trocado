import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/models/expense/expense_period_preset.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/screen_header_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

import 'package:trocado/src/presentation/screens/date_range/screens/date_range_screen.dart';

import 'package:trocado/src/presentation/screens/expenses/notifiers/expenses_notifier.dart';
import 'package:trocado/src/presentation/screens/expenses/notifiers/expenses_filters_intent.dart';
import 'package:trocado/src/presentation/screens/expenses/notifiers/expenses_filters_notifier.dart';

import 'package:trocado/src/presentation/screens/expenses/widgets/filter/expenses_filter_value_section_widget.dart';
import 'package:trocado/src/presentation/screens/expenses/widgets/filter/expenses_filter_period_section_widget.dart';
import 'package:trocado/src/presentation/screens/expenses/widgets/filter/expenses_filter_category_section_widget.dart';
import 'package:trocado/src/presentation/screens/expenses/widgets/filter/expenses_filter_ordering_section_widget.dart';

class ExpensesFilterScreen extends StatefulWidget {
  final NavigateToDateRange navigateToCustomRange;

  const ExpensesFilterScreen({super.key, required this.navigateToCustomRange});

  @override
  State<ExpensesFilterScreen> createState() => _ExpensesFilterScreenState();
}

class _ExpensesFilterScreenState extends State<ExpensesFilterScreen> {
  bool _initialized = false;

  @override
  Widget build(BuildContext context) => Consumer(
    builder: (_, ref, _) {
      if (!_initialized) {
        _initialized = true;
        final current =
            ref.read(expensesProvider).value?.filter ?? const .empty();
        Future.microtask(
          () => ref
              .read(expensesFiltersProvider.notifier)
              .dispatch(InitializeFrom(current)),
        );
      }

      final state = ref.watch(expensesFiltersProvider);
      final notifier = ref.read(expensesFiltersProvider.notifier);

      return ScaffoldWidget(
        appBar: AppBarWidget(leading: GoBackWidget()),
        child: Padding(
          padding: const .all(16.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    spacing: 8.0,
                    crossAxisAlignment: .start,
                    children: [
                      const ScreenHeaderWidget(
                        title: 'Filtros',
                        description: 'Refine a lista de despesas.',
                      ),

                      const SizedBox(height: 8.0),

                      ExpensesFilterCategorySectionWidget(
                        selected: state.draft.category,
                        onSelected: (category) =>
                            notifier.dispatch(CategorySelected(category)),
                      ),

                      const SizedBox(height: 8.0),

                      ExpensesFilterPeriodSectionWidget(
                        endDate: state.draft.endDate,
                        startDate: state.draft.startDate,
                        selectedPreset: state.selectedPreset,
                        onPresetSelected: (preset) {
                          notifier.dispatch(PresetSelected(preset));
                          if (preset == ExpensePeriodPreset.custom) {
                            widget.navigateToCustomRange(
                              initialStartDate: state.draft.startDate,
                              initialEndDate: state.draft.endDate,
                              onSelected: (start, end) => notifier.dispatch(
                                CustomRangeChanged(start, end),
                              ),
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 8.0),

                      ExpensesFilterValueSectionWidget(
                        minValue: state.draft.minValue,
                        maxValue: state.draft.maxValue,
                        onMinChanged: (value) =>
                            notifier.dispatch(MinValueChanged(value)),
                        onMaxChanged: (value) =>
                            notifier.dispatch(MaxValueChanged(value)),
                      ),

                      const SizedBox(height: 8.0),

                      ExpensesFilterOrderingSectionWidget(
                        selected: state.draft.ordering,
                        onSelected: (ordering) =>
                            notifier.dispatch(OrderingSelected(ordering)),
                      ),

                      const SizedBox(height: 8.0),
                    ],
                  ),
                ),
              ),
              _footer(context, ref, state.draft.isEmpty, notifier),
            ],
          ),
        ),
      );
    },
  );

  Widget _footer(
    BuildContext context,
    WidgetRef ref,
    bool isEmpty,
    ExpensesFiltersNotifier notifier,
  ) => Padding(
    padding: const .only(top: 8.0),
    child: Row(
      spacing: 12.0,
      children: [
        Expanded(
          child: ButtonWidget.outlined(
            label: 'Limpar tudo',
            onTap: isEmpty ? null : () => notifier.dispatch(const Cleared()),
          ),
        ),
        Expanded(
          child: ButtonWidget.elevated(
            label: 'Aplicar',
            onTap: () {
              final draft = ref.read(expensesFiltersProvider).draft;
              context.pop();
              ref.read(expensesProvider.notifier).applyFilter(draft);
            },
          ),
        ),
      ],
    ),
  );
}
