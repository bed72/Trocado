enum ExpenseCategoryEnum {
  food,
  debt,
  health,
  unknown,
  housing,
  shopping,
  transport,
  entertainment;

  static ExpenseCategoryEnum fromString(String? value) => switch (value) {
    'food' => .food,
    'debt' => .debt,
    'health' => .health,
    'housing' => .housing,
    'shopping' => .shopping,
    'transport' => .transport,
    'entertainment' => .entertainment,
    _ => .unknown,
  };
}
