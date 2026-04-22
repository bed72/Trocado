enum InsightSeverity {
  info,
  danger,
  warning,
  unknown;

  static InsightSeverity fromString(String? value) => switch (value) {
    'info' => .info,
    'danger' => .danger,
    'warning' => .warning,
    _ => .unknown,
  };
}
