import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/models/expense/expense_filter_model.dart';

import 'package:trocado/src/presentation/data/date_range_navigation.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/screen_header_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

import 'package:trocado/src/presentation/ui/expenses/notifiers/expenses_notifier.dart';
import 'package:trocado/src/presentation/ui/expenses/notifiers/expenses_filters_intent.dart';
import 'package:trocado/src/presentation/ui/expenses/notifiers/expenses_filters_notifier.dart';

import 'package:trocado/src/presentation/ui/expenses/widgets/filter/expenses_filter_value_section_widget.dart';
import 'package:trocado/src/presentation/ui/expenses/widgets/filter/expenses_filter_period_section_widget.dart';
import 'package:trocado/src/presentation/ui/expenses/widgets/filter/expenses_filter_category_section_widget.dart';

class ExpensesFilterScreen extends StatelessWidget {
  final ExpenseFilterModel initialFilter;
  final NavigateToDateRange navigateToDateRange;

  const ExpensesFilterScreen({
    super.key,
    required this.initialFilter,
    required this.navigateToDateRange,
  });

  @override
  Widget build(BuildContext context) => Consumer(
    builder: (_, ref, _) {
      final state = ref.watch(expensesFiltersProvider(initialFilter));
      final notifier = ref.read(
        expensesFiltersProvider(initialFilter).notifier,
      );

      return ScaffoldWidget(
        appBar: AppBarWidget(leading: GoBackWidget()),
        child: Padding(
          padding: const .all(16.0),
          child: Column(
            crossAxisAlignment: .start,
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
                        selectedPreset: state.selectedPeriodPreset,
                        formattedSummary: state.formattedPeriodSummary,
                        onPresetSelected: (preset) {
                          notifier.dispatch(PeriodPresetSelected(preset));
                          if (preset == .custom) {
                            navigateToDateRange(
                              initialEndDate: state.draft.endDate,
                              initialStartDate: state.draft.startDate,
                              onSelected: (start, end) => notifier.dispatch(
                                CustomRangeChanged(start, end),
                              ),
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 8.0),

                      ExpensesFilterValueSectionWidget(
                        selectedPreset: state.selectedValuePreset,
                        onPresetSelected: (preset) =>
                            notifier.dispatch(ValuePresetSelected(preset)),
                      ),

                      const SizedBox(height: 8.0),
                    ],
                  ),
                ),
              ),
              _footer(
                context: context,
                ref: ref,
                notifier: notifier,
                isEmpty: state.draft.isEmpty,
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _footer({
    required BuildContext context,
    required bool isEmpty,
    required WidgetRef ref,
    required ExpensesFiltersNotifier notifier,
  }) => Padding(
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
              final draft = ref
                  .read(expensesFiltersProvider(initialFilter))
                  .draft;
              context.pop();
              ref.read(expensesProvider.notifier).applyFilter(draft);
            },
          ),
        ),
      ],
    ),
  );
}
