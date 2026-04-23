enum InsightSeverityEnum {
  info,
  danger,
  warning,
  unknown;

  static InsightSeverityEnum fromString(String? value) => switch (value) {
    'info' => .info,
    'danger' => .danger,
    'warning' => .warning,
    _ => .unknown,
  };
}
