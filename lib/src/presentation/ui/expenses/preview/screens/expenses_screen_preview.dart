import 'package:flutter/material.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/services/date_formatter_service.dart';
import 'package:trocado/src/domain/enums/expense/expense_category_enum.dart';
import 'package:trocado/src/infrastructure/services/date_formatter_service.dart';

import 'package:trocado/src/presentation/data/expense_item_presentation_data.dart';

import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/screen_header_widget.dart';

import 'package:trocado/src/presentation/preview/trocado_preview.dart';
import 'package:trocado/src/presentation/preview/mocks/expense/expense_item_mock.dart';

import 'package:trocado/src/presentation/ui/expenses/notifiers/expenses_state.dart';

import 'package:trocado/src/presentation/ui/expenses/data/expense_groups_builder.dart';

import 'package:trocado/src/presentation/ui/expenses/widgets/expenses_list_widget.dart';
import 'package:trocado/src/presentation/ui/expenses/widgets/expenses_empty_widget.dart';
import 'package:trocado/src/presentation/ui/expenses/widgets/expenses_failure_widget.dart';
import 'package:trocado/src/presentation/ui/expenses/widgets/expenses_loading_widget.dart';
import 'package:trocado/src/presentation/ui/expenses/widgets/expenses_filter_button_widget.dart';

Widget _shell({required List<Widget> slivers}) => Scaffold(
  appBar: AppBarWidget(
    leading: const GoBackWidget(),
    actions: [
      Padding(
        padding: const .only(right: 16.0),
        child: ExpensesFilterButtonWidget(onPress: () {}),
      ),
    ],
  ),
  body: CustomScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    slivers: [
      const SliverToBoxAdapter(
        child: Padding(
          padding: .symmetric(horizontal: 16.0, vertical: 8.0),
          child: ScreenHeaderWidget(
            title: 'Despesas',
            description: 'Acompanhe todas as suas despesas.',
          ),
        ),
      ),
      ...slivers,
    ],
  ),
);

final IDateFormatterService _previewFormatter = DateFormatterService(
  now: DateTime.now,
);

Widget _listPreview(
  List<ExpenseItemPresentationData> items, {
  bool isLoadingMore = false,
  Failure? loadMoreFailure,
  String? nextCursor = 'CUR',
}) {
  final groups = buildExpenseGroups(items, dateFormatter: _previewFormatter);

  return _shell(
    slivers: [
      ExpensesListWidget(
        groups: groups,
        onLoadMore: () {},
        onTapExpense: (_) {},
        state: ExpensesState(
          items: items,
          groups: groups,
          nextCursor: nextCursor,
          isLoadingMore: isLoadingMore,
          loadMoreFailure: loadMoreFailure,
        ),
      ),
    ],
  );
}

@TrocadoPreview(group: 'Agrupamento', name: 'Hoje apenas')
Widget previewToday() => _listPreview([
  expenseItemMock(
    id: 1,
    ago: .zero,
    value: 85.50,
    category: .food,
    description: 'Cafezinho com o meu amor',
  ),
  expenseItemMock(
    id: 2,
    value: 38.91,
    category: .health,
    description: 'Farmácia',
    ago: const Duration(hours: 2),
  ),
  expenseItemMock(
    id: 3,
    value: 22.00,
    description: 'Uber',
    category: .transport,
    ago: const Duration(hours: 6),
  ),
]);

@TrocadoPreview(group: 'Agrupamento', name: 'Hoje + Ontem')
Widget previewTodayAndYesterday() => _listPreview([
  expenseItemMock(
    id: 1,
    ago: .zero,
    value: 85.50,
    category: .food,
    description: 'Cafezinho',
  ),
  expenseItemMock(
    id: 2,
    value: 38.91,
    category: .shopping,
    description: 'Arezzo',
    ago: const Duration(hours: 5),
  ),
  expenseItemMock(
    id: 3,
    value: 164.00,
    category: .food,
    ago: const Duration(days: 1),
    description: 'Pão de Açúcar',
  ),
  expenseItemMock(
    id: 4,
    value: 19.24,
    category: .transport,
    description: 'Estacionamento',
    ago: const Duration(days: 1, hours: 3),
  ),
]);

@TrocadoPreview(group: 'Agrupamento', name: 'Dentro da semana')
Widget previewWithinWeek() => _listPreview([
  expenseItemMock(
    id: 1,
    ago: .zero,
    value: 85.50,
    category: .food,
    description: 'Cafezinho',
  ),
  expenseItemMock(
    id: 2,
    value: 38.91,
    category: .health,
    description: 'Farmácia',
    ago: const Duration(days: 1),
  ),
  expenseItemMock(
    id: 3,
    value: 236.66,
    category: .shopping,
    description: 'Arezzo',
    ago: const Duration(days: 2),
  ),
  expenseItemMock(
    id: 4,
    value: 164.00,
    category: .food,
    description: 'Pão de Açúcar',
    ago: const Duration(days: 4),
  ),
  expenseItemMock(
    id: 5,
    value: 19.24,
    category: .transport,
    ago: const Duration(days: 6),
    description: 'Estacionamento',
  ),
]);

@TrocadoPreview(group: 'Agrupamento', name: 'Mês anterior')
Widget previewOlderMonth() => _listPreview([
  expenseItemMock(
    id: 1,
    value: 1200.00,
    category: .housing,
    description: 'Aluguel',
    ago: const Duration(days: 30),
  ),
  expenseItemMock(
    id: 2,
    value: 89.90,
    description: 'Cinema',
    category: .entertainment,
    ago: const Duration(days: 45),
  ),
  expenseItemMock(
    id: 3,
    value: 420.50,
    category: .debt,
    ago: const Duration(days: 60),
    description: 'Cartão de crédito',
  ),
]);

@TrocadoPreview(group: 'Agrupamento', name: 'Todos os grupos (mix)')
Widget previewAllGroups() => _listPreview([
  expenseItemMock(
    id: 1,
    ago: .zero,
    value: 85.50,
    category: .food,
    description: 'Cafezinho',
  ),
  expenseItemMock(
    id: 2,
    value: 38.91,
    category: .health,
    description: 'Farmácia',
    ago: const Duration(hours: 4),
  ),
  expenseItemMock(
    id: 3,
    value: 164.00,
    category: .food,
    description: 'Mercado',
    ago: const Duration(days: 1),
  ),
  expenseItemMock(
    id: 4,
    value: 19.24,
    description: 'Uber',
    category: .transport,
    ago: const Duration(days: 3),
  ),
  expenseItemMock(
    id: 5,
    value: 50.00,
    category: .entertainment,
    description: 'Streaming',
    ago: const Duration(days: 5),
  ),
  expenseItemMock(
    id: 6,
    ago: const Duration(days: 20),
    value: 1200.00,
    category: .housing,
    description: 'Aluguel',
  ),
  expenseItemMock(
    id: 7,
    value: 420.50,
    category: .debt,
    description: 'Cartão',
    ago: const Duration(days: 40),
  ),
  expenseItemMock(
    id: 8,
    value: 89.90,
    category: .shopping,
    description: 'Sapato',
    ago: const Duration(days: 75),
  ),
]);

@TrocadoPreview(group: 'Scroll', name: 'Lista longa (25 items)')
Widget previewLongList() => _listPreview([
  for (int i = 0; i < 25; i++)
    expenseItemMock(
      id: i + 1,
      value: 10.0 + i * 7.5,
      description: 'Despesa #${i + 1}',
      ago: Duration(days: i ~/ 2, hours: (i % 2) * 6),
      category:
          ExpenseCategoryEnum.values[i % ExpenseCategoryEnum.values.length],
    ),
]);

@TrocadoPreview(group: 'Tail', name: 'Carregando mais')
Widget previewTailLoading() => _listPreview([
  for (int i = 0; i < 6; i++)
    expenseItemMock(
      id: i + 1,
      ago: Duration(days: i ~/ 2),
      value: 50.0 + i * 12.0,
      category:
          ExpenseCategoryEnum.values[i % ExpenseCategoryEnum.values.length],
      description: 'Despesa #${i + 1}',
    ),
], isLoadingMore: true);

@TrocadoPreview(group: 'Tail', name: 'Falha ao carregar mais')
Widget previewTailFailure() => _listPreview([
  for (int i = 0; i < 6; i++)
    expenseItemMock(
      id: i + 1,
      value: 50.0 + i * 12.0,
      ago: Duration(days: i ~/ 2),
      description: 'Despesa #${i + 1}',
      category:
          ExpenseCategoryEnum.values[i % ExpenseCategoryEnum.values.length],
    ),
], loadMoreFailure: const ServerFailure());

@TrocadoPreview(group: 'Tail', name: 'Fim da lista')
Widget previewTailEnd() => _listPreview([
  for (int i = 0; i < 4; i++)
    expenseItemMock(
      id: i + 1,
      ago: Duration(days: i),
      value: 50.0 + i * 12.0,
      description: 'Despesa #${i + 1}',
      category:
          ExpenseCategoryEnum.values[i % ExpenseCategoryEnum.values.length],
    ),
], nextCursor: null);

@TrocadoPreview(group: 'Estados', name: 'Empty')
Widget previewEmpty() => _shell(
  slivers: const [
    SliverFillRemaining(hasScrollBody: false, child: ExpensesEmptyWidget()),
  ],
);

@TrocadoPreview(group: 'Estados', name: 'Loading')
Widget previewLoading() =>
    _shell(slivers: const [SliverToBoxAdapter(child: ExpensesLoadingWidget())]);

@TrocadoPreview(group: 'Estados', name: 'Failure')
Widget previewFailure() => _shell(
  slivers: [
    SliverFillRemaining(
      hasScrollBody: false,
      child: ExpensesFailureWidget(onRetry: () {}),
    ),
  ],
);
