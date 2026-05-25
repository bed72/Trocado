abstract interface class IQuickActionService {
  void clear();
  void register({
    required void Function() onBudget,
    required void Function() onExpense,
  });
}
