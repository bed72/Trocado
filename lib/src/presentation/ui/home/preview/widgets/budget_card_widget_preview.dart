import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/preview/trocado_preview.dart';

import 'package:trocado/src/presentation/ui/home/data/budget_card_data.dart';
import 'package:trocado/src/presentation/ui/home/preview/mocks/budget_card_mock.dart';
import 'package:trocado/src/presentation/ui/home/widgets/budget/card/budget_card_widget.dart';

final _healthy = budgetCardMock(
  value: 300000,
  remaining: 210000,
  totalSpent: 90000,
);
final _warning = budgetCardMock(
  value: 300000,
  remaining: 135000,
  totalSpent: 165000,
);
final _critical = budgetCardMock(
  value: 300000,
  remaining: 15000,
  totalSpent: 285000,
);
final _overspent = budgetCardMock(
  value: 300000,
  remaining: -50000,
  totalSpent: 350000,
);

Widget _card(AsyncValue<BudgetCardData?> state) => Scaffold(
  body: SafeArea(
    child: Padding(
      padding: const .all(16.0),
      child: BudgetCardWidget(
        state: state,
        onRetry: () {},
        onCreateBudget: () {},
      ),
    ),
  ),
);

@TrocadoPreview(group: 'Estados', name: 'Empty')
Widget previewEmpty() => _card(const AsyncData(null));

@TrocadoPreview(group: 'Estados', name: 'Loading')
Widget previewLoading() => _card(const AsyncLoading());

@TrocadoPreview(group: 'Estados', name: 'Failure')
Widget previewFailure() =>
    _card(AsyncError('Falha ao carregar', StackTrace.empty));

@TrocadoPreview(group: 'Progresso', name: 'Saudável (30%)')
Widget previewSuccessHealthy() => _card(AsyncData(_healthy));

@TrocadoPreview(group: 'Progresso', name: 'Atenção (55%)')
Widget previewSuccessWarning() => _card(AsyncData(_warning));

@TrocadoPreview(group: 'Progresso', name: 'Crítico (95%)')
Widget previewSuccessCritical() => _card(AsyncData(_critical));

@TrocadoPreview(group: 'Progresso', name: 'Estourou (117%)')
Widget previewSuccessOverspent() => _card(AsyncData(_overspent));
