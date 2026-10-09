<?php

declare(strict_types=1);

namespace App\Insights\Domain\Enums;

enum InsightTypeEnum: string
{
    case CategoryConcentration = 'category_concentration';
    case ExpenseConcentration = 'expense_concentration';
    case RegisteredAmountIncrease = 'registered_amount_increase';
    case RegisteredAmountDecrease = 'registered_amount_decrease';
    case CategoryLeadStreak = 'category_lead_streak';
    case FirstExpense = 'first_expense';
    case InsufficientHistory = 'insufficient_history';
    case CategoryReview = 'category_review';

    public function group(): InsightGroupEnum
    {
        return match ($this) {
            self::CategoryConcentration, self::ExpenseConcentration => InsightGroupEnum::Observation,
            self::RegisteredAmountIncrease, self::RegisteredAmountDecrease, self::CategoryLeadStreak => InsightGroupEnum::Comparison,
            self::FirstExpense, self::InsufficientHistory, self::CategoryReview => InsightGroupEnum::Onboarding,
        };
    }

    public function priority(): int
    {
        return match ($this) {
            self::RegisteredAmountIncrease, self::RegisteredAmountDecrease => 0,
            self::CategoryLeadStreak => 1,
            self::CategoryConcentration => 2,
            self::ExpenseConcentration => 3,
            self::CategoryReview => 4,
            self::FirstExpense, self::InsufficientHistory => 5,
        };
    }
}
