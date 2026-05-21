import 'package:flutter/material.dart';

import 'package:trocado/src/domain/enums/scope/financial_scope_enum.dart';

import 'package:trocado/src/presentation/widgets/selectors/selector_widget.dart';

class ExpensesScopeSelectorWidget extends StatelessWidget {
  final FinancialScopeEnum scope;
  final ValueChanged<FinancialScopeEnum> onScopeChanged;

  const ExpensesScopeSelectorWidget({
    super.key,
    required this.scope,
    required this.onScopeChanged,
  });

  static const _options = ['Minhas', 'Nossas'];

  @override
  Widget build(BuildContext context) => SelectorWidget(
    options: _options,
    selected: scope == .couple ? 1 : 0,
    onSelected: (label) =>
        onScopeChanged(label == _options.last ? .couple : .mine),
  );
}
