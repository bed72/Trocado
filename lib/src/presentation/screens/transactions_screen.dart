import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/extensions/widget_extension.dart';

import 'package:trocado/src/presentation/notifiers/transaction/transaction_state.dart';
import 'package:trocado/src/presentation/notifiers/transaction/transaction_notifier.dart';

import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/icon_button_widget.dart';
import 'package:trocado/src/presentation/widgets/transaction/transactions_form_widget.dart';

class TransactionsScreen extends StatefulWidget {
  final int? id;

  final VoidCallback navigateToDate;
  final VoidCallback navigateToCategory;
  final VoidCallback navigateToCalculator;

  const TransactionsScreen({
    super.key,
    required this.navigateToDate,
    required this.navigateToCategory,
    required this.navigateToCalculator,
    this.id,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late final GlobalKey<FormState> _formKey;

  bool get _isEditing => widget.id != null;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, ref, _) {
        final state = ref.watch(transactionProvider);
        final notifier = ref.read(transactionProvider.notifier);

        _handleSideEffects(context, state);

        return ScaffoldWidget(
          appBar: AppBarWidget(
            leading: _buildGoBack(),
            title: _isEditing ? 'Editar Transação' : 'Nova Transação',
          ),
          child: Padding(
            padding: const .all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(child: TransactionsFormWidget()),
                ),
                _buildDeleteButton(notifier, state),
                _buildSaveButton(notifier, state),
              ],
            ),
          ),
        );
      },
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

  Container _buildSaveButton(
    TransactionNotifier notifier,
    TransactionState state,
  ) => Container(
    width: .infinity,
    padding: const .only(top: 16),
    child: ButtonWidget.outlined(
      label: 'Salvar',
      isLoading: state is TransactionLoading,
      onTap: () {
        hideKeyboard;

        final isValid = _formKey.currentState?.validate() ?? false;
        if (!isValid) return;

        // notifier.save();
      },
    ),
  );

  Container _buildDeleteButton(
    TransactionNotifier notifier,
    TransactionState state,
  ) {
    // final id = state.transaction?.id;
    // if (id == null) return const SizedBox.shrink();

    return Container(
      width: .infinity,
      padding: const .only(top: 16),
      child: ButtonWidget.elevated(
        label: 'Deletar',
        isLoading: state is TransactionLoading,
        onTap: () {
          hideKeyboard;
          // notifier.delete(id);
        },
      ),
    );
  }

  void _handleSideEffects(BuildContext context, TransactionState state) =>
      switch (state) {
        TransactionSuccess() => showToastWidget(
          context: context,
          onClose: context.pop,
          title: 'Ihulll, tudo certo.',
          description: 'Já atualizamos sua Home.',
        ),
        TransactionFailure(:final failure) => showToastWidget(
          type: .failure,
          context: context,
          description: failure,
          title: 'Ops, algo aconteceu.',
        ),
        _ => null,
      };
}
