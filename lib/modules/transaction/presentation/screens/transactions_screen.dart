import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/modules/date/date.dart';
import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/category/category.dart';

import 'package:trocado/modules/calculator/presentation/cubits/calculator_cubit.dart';

class TransactionsScreen extends StatefulWidget {
  final DateCubit dateCubit;
  final CategoryCubit categoryCubit;
  final CalculatorCubit caculatorCubit;

  final VoidCallback navigateToDate;
  final VoidCallback navigateToCategory;
  final VoidCallback navigateToCalculator;

  const TransactionsScreen({
    super.key,
    required this.dateCubit,
    required this.categoryCubit,
    required this.caculatorCubit,
    required this.navigateToDate,
    required this.navigateToCategory,
    required this.navigateToCalculator,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late final TextEditingController _dateController;
  late final TextEditingController _amountController;
  late final TextEditingController _categoryController;

  @override
  void initState() {
    super.initState();

    _dateController = TextEditingController();
    _amountController = TextEditingController();
    _categoryController = TextEditingController();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _amountController.dispose();
    _categoryController.dispose();

    widget.dateCubit.close();
    widget.categoryCubit.close();
    widget.caculatorCubit.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWidget(
      appBar: AppBarWidget(title: 'Transações'),
      child: Padding(
        padding: const .all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  spacing: 16.0,
                  crossAxisAlignment: .start,
                  children: [
                    TextFormFieldWidget(hint: 'Descrição', placeholder: 'Café'),

                    BounceWidget.withTap(
                      onTap: widget.navigateToCalculator,
                      child: BlocListener<CalculatorCubit, CalculatorState>(
                        bloc: widget.caculatorCubit,
                        listenWhen: (previous, current) =>
                            previous.preview != current.preview,
                        listener: (_, state) {
                          _amountController.text = state.amount;
                        },
                        child: TextFieldWidget(
                          hint: 'R\$',
                          readOnly: true,
                          absorbing: true,
                          controller: _amountController,
                        ),
                      ),
                    ),

                    BounceWidget.withTap(
                      onTap: widget.navigateToCategory,
                      child: BlocListener<CategoryCubit, CategoryState>(
                        bloc: widget.categoryCubit,
                        listenWhen: (previous, current) =>
                            previous.category.label != current.category.label,
                        listener: (_, state) {
                          _categoryController.text = state.category.label;
                        },
                        child: TextFormFieldWidget(
                          readOnly: true,
                          absorbing: true,
                          hint: 'Categoria',
                          controller: _categoryController,
                        ),
                      ),
                    ),

                    BounceWidget.withTap(
                      onTap: widget.navigateToDate,
                      child: BlocListener<DateCubit, DateState>(
                        bloc: widget.dateCubit,
                        listenWhen: (previous, current) =>
                            previous.formatted != current.formatted,
                        listener: (_, state) {
                          _dateController.text = state.formatted;
                        },
                        child: TextFormFieldWidget(
                          hint: 'Data',
                          readOnly: true,
                          absorbing: true,
                          controller: _dateController,
                        ),
                      ),
                    ),

                    TextFormFieldWidget(
                      hint: 'Observações',
                      placeholder: 'Meio quilo em grão',
                    ),

                    SelectorWidget(
                      options: ['Receita', 'Despesa'],
                      selected: 1,
                      onSelected: (_) {},
                    ),
                  ],
                ),
              ),
            ),

            Container(
              width: .infinity,
              padding: .only(top: 16.0),
              child: ButtonWidget.elevated(onTap: () {}, label: 'Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
