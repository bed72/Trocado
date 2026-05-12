enum NotificationTypeEnum {
  unknown,
  budgetEightyPercent,
  sharedExpenseCreated;

  factory NotificationTypeEnum.fromString(String value) => switch (value) {
    'budget_eighty_percent' => budgetEightyPercent,
    'shared_expense_created' => sharedExpenseCreated,
    _ => unknown,
  };
}
