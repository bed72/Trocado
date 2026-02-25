import 'package:rearch/rearch.dart';

import 'package:trocado/src/main/capsules/capsules.dart';

import 'package:trocado/src/presentation/data/ui/expense_presentation_data.dart';

import 'package:trocado/src/presentation/capsules/date_capsule.dart';
import 'package:trocado/src/presentation/capsules/amount_capsule.dart';
import 'package:trocado/src/presentation/capsules/category_capsule.dart';
import 'package:trocado/src/presentation/capsules/description_capsule.dart';
import 'package:trocado/src/presentation/capsules/states/expense_saved_state.dart';

(ExpensePresentationData, void Function()) formExpenseCapsule(
  CapsuleHandle use,
) {
  final service = use(moneyServiceCapsule);

  final (date, setDate) = use(dateCapsule);
  final (amount, setAmount) = use(amountCapsule);
  final (category, setCategory) = use(categoryCapsule);
  final (description, setDescription) = use(descriptionCapsule);

  final data = ExpensePresentationData(
    date: date,
    category: category,
    description: description,
    amount: service.parse(amount),
  );

  void clear() {
    setDate(.now());
    setDescription('');
    setCategory(.other);
    setAmount(const .clear());
  }

  return (data, clear);
}

(ExpenseSavedState?, ExpenseSavedState Function()) saveExpenseCapsule(
  CapsuleHandle use,
) {
  final repository = use(expenseRepositoryCapsule);
  final (form, clearForm) = use(formExpenseCapsule);
  final mapper = use(expensePresentationToModelMapper);

  final (value, setValue) = use.state<ExpenseSavedState?>(null);

  ExpenseSavedState save() {
    setValue(const ExpenseSavedLoadingState());

    final data = repository.upsert(mapper(form)).fold(
      ExpenseSavedFailureState.new,
      (_) {
        clearForm();
        return const ExpenseSavedSuccessState('Despesa salva com sucesso');
      },
    );

    setValue(data);
    return data;
  }

  return (value, save);
}
