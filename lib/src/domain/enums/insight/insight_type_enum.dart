enum InsightTypeEnum {
  unknown,
  topCategory,
  dailyAverage,
  willOverspend,
  budgetUtilization;

  static InsightTypeEnum fromString(String? value) => switch (value) {
    'top_category' => .topCategory,
    'daily_average' => .dailyAverage,
    'will_overspend' => .willOverspend,
    'budget_utilization' => .budgetUtilization,
    _ => .unknown,
  };
}
