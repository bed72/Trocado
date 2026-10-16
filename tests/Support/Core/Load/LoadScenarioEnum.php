<?php

declare(strict_types=1);

namespace Tests\Support\Core\Load;

enum LoadScenarioEnum: string
{
    case ExpensePages = 'expense-pages';
    case ExpenseMetrics = 'expense-metrics';
    case MonthlyInsights = 'monthly-insights';
    case ExpenseSuggestions = 'expense-suggestions';

    public function endpoint(): string
    {
        return match ($this) {
            self::ExpensePages => '/api/expenses',
            self::MonthlyInsights => '/api/insights',
            self::ExpenseMetrics => '/api/metrics/expenses',
            self::ExpenseSuggestions => '/api/expenses/suggestions',
        };
    }

    public function file(): string
    {
        return 'tests/Load/'.match ($this) {
            self::ExpensePages => 'Expense/Presentation/Http/ExpensePagesLoadTest.php',
            self::ExpenseMetrics => 'Metrics/Presentation/Http/ExpenseMetricsLoadTest.php',
            self::MonthlyInsights => 'Insights/Presentation/Http/MonthlyInsightsLoadTest.php',
            self::ExpenseSuggestions => 'Expense/Presentation/Http/ExpenseSuggestionsLoadTest.php',
        };
    }
}
