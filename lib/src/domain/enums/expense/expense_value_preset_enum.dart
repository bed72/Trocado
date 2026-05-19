typedef ExpenseValueRange = ({int? minValue, int? maxValue});

enum ExpenseValuePresetEnum {
  upTo50('Até R\$50'),
  above500('Acima de R\$500'),
  from50To200('R\$50 – R\$200'),
  from200To500('R\$200 – R\$500');

  final String label;

  const ExpenseValuePresetEnum(this.label);

  ExpenseValueRange toRange() => switch (this) {
    .upTo50 => (minValue: null, maxValue: 5000),
    .above500 => (minValue: 50000, maxValue: null),
    .from50To200 => (minValue: 5000, maxValue: 20000),
    .from200To500 => (minValue: 20000, maxValue: 50000),
  };
}
