import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/widget_extension.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/icon_button_widget.dart';
import 'package:trocado/src/presentation/widgets/expense/expense_form_widget.dart';

class ExpenseScreen extends StatefulWidget {
  final int? id;

  final VoidCallback navigateToDate;
  final VoidCallback navigateToCategory;
  final VoidCallback navigateToCalculator;

  const ExpenseScreen({
    super.key,
    required this.navigateToDate,
    required this.navigateToCategory,
    required this.navigateToCalculator,
    this.id,
  });

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  late final GlobalKey<FormState> _formKey;

  bool get _isEditing => widget.id != null;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWidget(
      appBar: AppBarWidget(
        leading: _buildGoBack(),
        title: _isEditing ? 'Editar Despesa' : 'Nova Despesa',
      ),
      child: Padding(
        padding: const .all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: TransactionsFormWidget(
                  navigateToDate: widget.navigateToDate,
                  navigateToCategory: widget.navigateToCategory,
                  navigateToCalculator: widget.navigateToCalculator,
                ),
              ),
            ),
            // _buildDeleteButton(notifier, state),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  IconButtonWidget _buildGoBack() => IconButtonWidget(
    width: 36,
    height: 36,
    iconSize: 22,
    onPress: context.pop,
    icon: Icons.chevron_left,
    borderRadius: context.radius.cornerRadius100,
  );

  Container _buildSaveButton() => Container(
    width: .infinity,
    padding: const .only(top: 16),
    child: ButtonWidget.outlined(
      label: 'Salvar',
      isLoading: false,
      onTap: () {
        hideKeyboard;

        final isValid = _formKey.currentState?.validate() ?? false;
        if (!isValid) return;

        // notifier.save();
      },
    ),
  );

  // Container _buildDeleteButton(
  //   TransactionController notifier,
  //   TransactionState state,
  // ) {
  //   return Container(
  //     width: .infinity,
  //     padding: const .only(top: 16),
  //     child: ButtonWidget.elevated(
  //       label: 'Deletar',
  //       isLoading: state is TransactionLoading,
  //       onTap: () {
  //         hideKeyboard;
  //         // notifier.delete(id);
  //       },
  //     ),
  //   );
  // }

  // void _handleSideEffects(BuildContext context, TransactionState state) =>
  //     switch (state) {
  //       TransactionSuccess() => showToastWidget(
  //         context: context,
  //         onClose: context.pop,
  //         title: 'Ihulll, tudo certo.',
  //         description: 'Já atualizamos sua Home.',
  //       ),
  //       TransactionFailure(:final failure) => showToastWidget(
  //         type: .failure,
  //         context: context,
  //         description: failure,
  //         title: 'Ops, algo aconteceu.',
  //       ),
  //       _ => null,
  //     };
}
