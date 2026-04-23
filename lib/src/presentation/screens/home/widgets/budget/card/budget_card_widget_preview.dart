import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/screens/home/data/budget_card_data.dart';
import 'package:trocado/src/presentation/widgets/preview/material_preview_widget.dart';
import 'package:trocado/src/presentation/screens/home/widgets/budget/card/budget_card_widget.dart';

String _format(double value) {
  final formatted = value.toStringAsFixed(2).replaceAll('.', ',');
  return 'R\$ $formatted';
}

BudgetCardData _data({
  required int value,
  required int remaining,
  required int totalSpent,
}) {
  final percentage = value > 0 ? totalSpent / value : 0.0;
  final dailyBudget = (remaining / max(1, 7)).round();

  return BudgetCardData(
    percentage: percentage,
    overspent: remaining < 0,
    formattedValue: _format(value / 100),
    formattedRemaining: _format(max(0, remaining) / 100),
    formattedOverspent: _format(remaining.abs() / 100),
    formattedTotalSpent: _format(totalSpent / 100),
    formattedDailyBudget: _format(dailyBudget / 100),
    formattedPercentage: (percentage * 100).clamp(0, 100).toStringAsFixed(0),
  );
}

final _healthy = _data(value: 300000, remaining: 210000, totalSpent: 90000);
final _warning = _data(value: 300000, remaining: 135000, totalSpent: 165000);
final _critical = _data(value: 300000, remaining: 15000, totalSpent: 285000);
final _overspent = _data(value: 300000, remaining: -50000, totalSpent: 350000);

Widget _card(AsyncValue<BudgetCardData?> state) => MaterialPreviewWidget(
  child: Scaffold(
    body: Padding(
      padding: const .all(16.0),
      child: BudgetCardWidget(
        state: state,
        onRetry: () {},
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
Widget previewSuccessHealthy() => _card(AsyncData(_healthy));

@Preview(name: 'Success — atenção (55%)')
Widget previewSuccessWarning() => _card(AsyncData(_warning));

@Preview(name: 'Success — crítico (95%)')
Widget previewSuccessCritical() => _card(AsyncData(_critical));

@Preview(name: 'Success — estourou (117%)')
Widget previewSuccessOverspent() => _card(AsyncData(_overspent));

@Preview(name: 'Failure')
Widget previewFailure() => _card(AsyncError('Falha ao carregar', .empty));
