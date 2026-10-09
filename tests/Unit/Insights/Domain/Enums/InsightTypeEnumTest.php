<?php

declare(strict_types=1);

use App\Insights\Domain\Enums\InsightGroupEnum;
use App\Insights\Domain\Enums\InsightTypeEnum;

it('assigns each contract type to its expected group', function (string $value, InsightGroupEnum $group): void {
    expect(InsightTypeEnum::from(value: $value)->group())->toBe($group);
})->with([
    'category concentration' => ['category_concentration', InsightGroupEnum::Observation],
    'expense concentration' => ['expense_concentration', InsightGroupEnum::Observation],
    'registered increase' => ['registered_amount_increase', InsightGroupEnum::Comparison],
    'registered decrease' => ['registered_amount_decrease', InsightGroupEnum::Comparison],
    'category streak' => ['category_lead_streak', InsightGroupEnum::Comparison],
    'first expense' => ['first_expense', InsightGroupEnum::Onboarding],
    'insufficient history' => ['insufficient_history', InsightGroupEnum::Onboarding],
    'category review' => ['category_review', InsightGroupEnum::Onboarding],
]);

it('prioritizes comparisons before streaks, concentrations and onboarding', function (InsightTypeEnum $higher, InsightTypeEnum $lower): void {
    expect($higher->priority())->toBeLessThan($lower->priority());
})->with([
    'increase before streak' => [InsightTypeEnum::RegisteredAmountIncrease, InsightTypeEnum::CategoryLeadStreak],
    'decrease before streak' => [InsightTypeEnum::RegisteredAmountDecrease, InsightTypeEnum::CategoryLeadStreak],
    'streak before category' => [InsightTypeEnum::CategoryLeadStreak, InsightTypeEnum::CategoryConcentration],
    'category before expense' => [InsightTypeEnum::CategoryConcentration, InsightTypeEnum::ExpenseConcentration],
    'expense before category review' => [InsightTypeEnum::ExpenseConcentration, InsightTypeEnum::CategoryReview],
    'review before first expense' => [InsightTypeEnum::CategoryReview, InsightTypeEnum::FirstExpense],
    'review before history guidance' => [InsightTypeEnum::CategoryReview, InsightTypeEnum::InsufficientHistory],
]);

it('gives increase and decrease the same priority', function (): void {
    expect(InsightTypeEnum::RegisteredAmountIncrease->priority())
        ->toBe(InsightTypeEnum::RegisteredAmountDecrease->priority());
});

it('gives both history guidance types the same priority', function (): void {
    expect(InsightTypeEnum::FirstExpense->priority())
        ->toBe(InsightTypeEnum::InsufficientHistory->priority());
});
