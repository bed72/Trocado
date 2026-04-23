import 'package:flutter/material.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/models/expense/expense_category.dart';

import 'package:trocado/src/presentation/data/expense/expense_item_data.dart';

import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/screen_header_widget.dart';

import 'package:trocado/src/presentation/preview/trocado_preview.dart';
import 'package:trocado/src/presentation/preview/mocks/expense/expense_item_mock.dart';

import 'package:trocado/src/presentation/screens/expenses/notifiers/expenses_state.dart';

import 'package:trocado/src/presentation/screens/expenses/data/expense_groups_builder.dart';

import 'package:trocado/src/presentation/screens/expenses/widgets/expenses_list_widget.dart';
import 'package:trocado/src/presentation/screens/expenses/widgets/expenses_empty_widget.dart';
import 'package:trocado/src/presentation/screens/expenses/widgets/expenses_failure_widget.dart';
import 'package:trocado/src/presentation/screens/expenses/widgets/expenses_loading_widget.dart';
import 'package:trocado/src/presentation/screens/expenses/widgets/expenses_filter_button_widget.dart';

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

Widget _listPreview(
  List<ExpenseItemData> items, {
  bool isLoadingMore = false,
  Failure? loadMoreFailure,
  String? nextCursor = 'CUR',
}) => _shell(
  slivers: [
    ExpensesListWidget(
      state: ExpensesState(
        items: items,
        nextCursor: nextCursor,
        isLoadingMore: isLoadingMore,
        loadMoreFailure: loadMoreFailure,
      ),
      groups: buildExpenseGroups(items),
      onLoadMore: () {},
    ),
  ],
);

@TrocadoPreview(group: 'Agrupamento', name: 'Hoje apenas')
Widget previewToday() => _listPreview([
  expenseItemMock(
    id: 1,
    ago: Duration.zero,
    value: 85.50,
    category: ExpenseCategory.food,
    description: 'Cafezinho com o meu amor',
  ),
  expenseItemMock(
    id: 2,
    ago: const Duration(hours: 2),
    value: 38.91,
    category: ExpenseCategory.health,
    description: 'Farmácia',
  ),
  expenseItemMock(
    id: 3,
    ago: const Duration(hours: 6),
    value: 22.00,
    category: ExpenseCategory.transport,
    description: 'Uber',
  ),
]);

@TrocadoPreview(group: 'Agrupamento', name: 'Hoje + Ontem')
Widget previewTodayAndYesterday() => _listPreview([
  expenseItemMock(
    id: 1,
    ago: Duration.zero,
    value: 85.50,
    category: ExpenseCategory.food,
    description: 'Cafezinho',
  ),
  expenseItemMock(
    id: 2,
    ago: const Duration(hours: 5),
    value: 38.91,
    category: ExpenseCategory.shopping,
    description: 'Arezzo',
  ),
  expenseItemMock(
    id: 3,
    ago: const Duration(days: 1),
    value: 164.00,
    category: ExpenseCategory.food,
    description: 'Pão de Açúcar',
  ),
  expenseItemMock(
    id: 4,
    ago: const Duration(days: 1, hours: 3),
    value: 19.24,
    category: ExpenseCategory.transport,
    description: 'Estacionamento',
  ),
]);

@TrocadoPreview(group: 'Agrupamento', name: 'Dentro da semana')
Widget previewWithinWeek() => _listPreview([
  expenseItemMock(
    id: 1,
    ago: Duration.zero,
    value: 85.50,
    category: ExpenseCategory.food,
    description: 'Cafezinho',
  ),
  expenseItemMock(
    id: 2,
    ago: const Duration(days: 1),
    value: 38.91,
    category: ExpenseCategory.health,
    description: 'Farmácia',
  ),
  expenseItemMock(
    id: 3,
    ago: const Duration(days: 2),
    value: 236.66,
    category: ExpenseCategory.shopping,
    description: 'Arezzo',
  ),
  expenseItemMock(
    id: 4,
    ago: const Duration(days: 4),
    value: 164.00,
    category: ExpenseCategory.food,
    description: 'Pão de Açúcar',
  ),
  expenseItemMock(
    id: 5,
    ago: const Duration(days: 6),
    value: 19.24,
    category: ExpenseCategory.transport,
    description: 'Estacionamento',
  ),
]);

@TrocadoPreview(group: 'Agrupamento', name: 'Mês anterior')
Widget previewOlderMonth() => _listPreview([
  expenseItemMock(
    id: 1,
    ago: const Duration(days: 30),
    value: 1200.00,
    category: ExpenseCategory.housing,
    description: 'Aluguel',
  ),
  expenseItemMock(
    id: 2,
    ago: const Duration(days: 45),
    value: 89.90,
    category: ExpenseCategory.entertainment,
    description: 'Cinema',
  ),
  expenseItemMock(
    id: 3,
    ago: const Duration(days: 60),
    value: 420.50,
    category: ExpenseCategory.debt,
    description: 'Cartão de crédito',
  ),
]);

@TrocadoPreview(group: 'Agrupamento', name: 'Todos os grupos (mix)')
Widget previewAllGroups() => _listPreview([
  expenseItemMock(
    id: 1,
    ago: Duration.zero,
    value: 85.50,
    category: ExpenseCategory.food,
    description: 'Cafezinho',
  ),
  expenseItemMock(
    id: 2,
    ago: const Duration(hours: 4),
    value: 38.91,
    category: ExpenseCategory.health,
    description: 'Farmácia',
  ),
  expenseItemMock(
    id: 3,
    ago: const Duration(days: 1),
    value: 164.00,
    category: ExpenseCategory.food,
    description: 'Mercado',
  ),
  expenseItemMock(
    id: 4,
    ago: const Duration(days: 3),
    value: 19.24,
    category: ExpenseCategory.transport,
    description: 'Uber',
  ),
  expenseItemMock(
    id: 5,
    ago: const Duration(days: 5),
    value: 50.00,
    category: ExpenseCategory.entertainment,
    description: 'Streaming',
  ),
  expenseItemMock(
    id: 6,
    ago: const Duration(days: 20),
    value: 1200.00,
    category: ExpenseCategory.housing,
    description: 'Aluguel',
  ),
  expenseItemMock(
    id: 7,
    ago: const Duration(days: 40),
    value: 420.50,
    category: ExpenseCategory.debt,
    description: 'Cartão',
  ),
  expenseItemMock(
    id: 8,
    ago: const Duration(days: 75),
    value: 89.90,
    category: ExpenseCategory.shopping,
    description: 'Sapato',
  ),
]);

@TrocadoPreview(group: 'Scroll', name: 'Lista longa (25 items)')
Widget previewLongList() => _listPreview([
  for (int i = 0; i < 25; i++)
    expenseItemMock(
      id: i + 1,
      ago: Duration(days: i ~/ 2, hours: (i % 2) * 6),
      value: 10.0 + i * 7.5,
      category: ExpenseCategory.values[i % ExpenseCategory.values.length],
      description: 'Despesa #${i + 1}',
    ),
]);

@TrocadoPreview(group: 'Tail', name: 'Carregando mais')
Widget previewTailLoading() => _listPreview(
  [
    for (int i = 0; i < 6; i++)
      expenseItemMock(
        id: i + 1,
        ago: Duration(days: i ~/ 2),
        value: 50.0 + i * 12.0,
        category: ExpenseCategory.values[i % ExpenseCategory.values.length],
        description: 'Despesa #${i + 1}',
      ),
  ],
  isLoadingMore: true,
);

@TrocadoPreview(group: 'Tail', name: 'Falha ao carregar mais')
Widget previewTailFailure() => _listPreview(
  [
    for (int i = 0; i < 6; i++)
      expenseItemMock(
        id: i + 1,
        ago: Duration(days: i ~/ 2),
        value: 50.0 + i * 12.0,
        category: ExpenseCategory.values[i % ExpenseCategory.values.length],
        description: 'Despesa #${i + 1}',
      ),
  ],
  loadMoreFailure: const ServerFailure(),
);

@TrocadoPreview(group: 'Tail', name: 'Fim da lista')
Widget previewTailEnd() => _listPreview(
  [
    for (int i = 0; i < 4; i++)
      expenseItemMock(
        id: i + 1,
        ago: Duration(days: i),
        value: 50.0 + i * 12.0,
        category: ExpenseCategory.values[i % ExpenseCategory.values.length],
        description: 'Despesa #${i + 1}',
      ),
  ],
  nextCursor: null,
);

@TrocadoPreview(group: 'Estados', name: 'Empty')
Widget previewEmpty() => _shell(
  slivers: const [
    SliverFillRemaining(hasScrollBody: false, child: ExpensesEmptyWidget()),
  ],
);

@TrocadoPreview(group: 'Estados', name: 'Loading')
Widget previewLoading() => _shell(
  slivers: const [SliverToBoxAdapter(child: ExpensesLoadingWidget())],
);

@TrocadoPreview(group: 'Estados', name: 'Failure')
Widget previewFailure() => _shell(
  slivers: [
    SliverFillRemaining(
      hasScrollBody: false,
      child: ExpensesFailureWidget(onRetry: () {}),
    ),
  ],
);
