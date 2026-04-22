import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/models/active_budget_model.dart';

import 'package:trocado/src/presentation/widgets/preview/material_preview_widget.dart';
import 'package:trocado/src/presentation/screens/home/widgets/budget/card/budget_card_widget.dart';

const _endDate = 1746057600000;
const _startDate = 1743465600000;

const _healthy = ActiveBudgetModel(
  id: 1,
  value: 300000,
  remaining: 210000,
  totalSpent: 90000,
  endDate: _endDate,
  startDate: _startDate,
  description: 'Orçamento mensal',
);

const _warning = ActiveBudgetModel(
  id: 1,
  value: 300000,
  endDate: _endDate,
  remaining: 135000,
  totalSpent: 165000,
  startDate: _startDate,
  description: 'Orçamento mensal',
);

const _critical = ActiveBudgetModel(
  id: 1,
  value: 300000,
  remaining: 15000,
  endDate: _endDate,
  totalSpent: 285000,
  startDate: _startDate,
  description: 'Orçamento mensal',
);

const _overspent = ActiveBudgetModel(
  id: 1,
  value: 300000,
  remaining: -50000,
  endDate: _endDate,
  totalSpent: 350000,
  startDate: _startDate,
  description: 'Orçamento mensal',
);

String _format(double value) {
  final formatted = value.toStringAsFixed(2).replaceAll('.', ',');
  return 'R\$ $formatted';
}

Widget _card(AsyncValue<ActiveBudgetModel?> state) => MaterialPreviewWidget(
  child: Scaffold(
    body: Padding(
      padding: const .all(16.0),
      child: BudgetCardWidget(
        state: state,
        onRetry: () {},
        format: _format,
        onCreateBudget: () {},
      ),
    ),
  ),
);

@Preview(name: 'Empty')
Widget previewEmpty() => _card(const AsyncData(null));

@Preview(name: 'Loading')
Widget previewLoading() => _card(const AsyncLoading());

@Preview(name: 'Success — saudável (30%)')
Widget previewSuccessHealthy() => _card(const AsyncData(_healthy));

@Preview(name: 'Success — atenção (55%)')
Widget previewSuccessWarning() => _card(const AsyncData(_warning));

@Preview(name: 'Success — crítico (95%)')
Widget previewSuccessCritical() => _card(const AsyncData(_critical));

@Preview(name: 'Success — estourou (117%)')
Widget previewSuccessOverspent() => _card(const AsyncData(_overspent));

@Preview(name: 'Failure')
Widget previewFailure() => _card(AsyncError('Falha ao carregar', .empty));
