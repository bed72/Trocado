enum ExpenseCategory {
  unknown,
  food,
  transport,
  shopping,
  health,
  housing,
  debt,
  entertainment;

  static ExpenseCategory fromString(String? value) => switch (value) {
    'food' => .food,
    'transport' => .transport,
    'shopping' => .shopping,
    'health' => .health,
    'housing' => .housing,
    'debt' => .debt,
    'entertainment' => .entertainment,
    _ => .unknown,
  };
}
