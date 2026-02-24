import 'package:rearch/rearch.dart';

import 'package:trocado/src/main/capsules/capsules.dart';

import 'package:trocado/src/presentation/capsules/date_capsule.dart';
import 'package:trocado/src/presentation/capsules/amount_capsule.dart';
import 'package:trocado/src/presentation/capsules/category_capsule.dart';
import 'package:trocado/src/presentation/capsules/description_capsule.dart';
import 'package:trocado/src/presentation/data/expense_presentation_data.dart';

(ExpenseSavedPresentationData?, void Function(), void Function())
saveExpenseCapsule(CapsuleHandle use) {
  final repository = use(expenseRepositoryCapsule);
  final (expense, clearForm) = use(formExpenseCapsule);
  final mapper = use(expensePresentationToModelMapper);

  final (value, setValue) = use.state<ExpenseSavedPresentationData?>(null);

  void clear() {
    setValue(null);
  }

  void save() {
    repository
        .upsert(mapper(expense))
        .fold(
          (failure) {
            setValue(ExpenseSavedFailurePresentationData(failure));
          },
          (_) {
            setValue(
              const ExpenseSavedSuccessPresentationData(
                'Despesa salva com sucesso',
              ),
            );
            clearForm();
          },
        );
  }

  return (value, save, clear);
}

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
