<?php

declare(strict_types=1);

namespace App\Insights\Domain\ValueObjects;

use App\Core\Domain\ValueObjects\CentsValueObject;
use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Insights\Domain\Exceptions\InvalidInsightAnalysisException;

use function is_string;

final readonly class ExpensePeriodSummaryValueObject
{
    /** @param array<string, CentsValueObject> $categories */
    public function __construct(
        public array $categories,
        public int $expenseCount,
        public int $distinctDateCount,
        public DatePeriodValueObject $period,
        public CentsValueObject $totalAmount,
        public CentsValueObject $largestExpenseAmount,
        public ?string $largestExpenseCategory,
    ) {
        if ($expenseCount < 0 || $distinctDateCount < 0 || $distinctDateCount > $expenseCount
            || $distinctDateCount > $period->days()) {
            throw new InvalidInsightAnalysisException('As contagens do período são inconsistentes.');
        }

        $categoryTotal = CentsValueObject::fromCents('0');

        foreach ($categories as $category => $amount) {
            if (! is_string($category) || $category === '' || ! $amount instanceof CentsValueObject || $amount->isZero()) {
                throw new InvalidInsightAnalysisException('A distribuição de categorias é inválida.');
            }

            $categoryTotal = $categoryTotal->plus($amount);
        }

        if ($categoryTotal->compareTo($totalAmount) !== 0 || count($categories) > $expenseCount) {
            throw new InvalidInsightAnalysisException('As categorias devem representar o total do período.');
        }

        if ($expenseCount === 0) {
            if ($distinctDateCount !== 0 || ! $totalAmount->isZero() || ! $largestExpenseAmount->isZero()
                || $largestExpenseCategory !== null || $categories !== []) {
                throw new InvalidInsightAnalysisException('Um período vazio não pode conter valores ou categorias.');
            }

            return;
        }

        if ($distinctDateCount === 0 || $totalAmount->isZero() || $largestExpenseAmount->isZero()
            || $largestExpenseCategory === null || ! isset($categories[$largestExpenseCategory])
            || $largestExpenseAmount->compareTo($categories[$largestExpenseCategory]) > 0) {
            throw new InvalidInsightAnalysisException('O maior lançamento deve pertencer à distribuição do período.');
        }
    }

    public function categoryAmount(string $category): CentsValueObject
    {
        return $this->categories[$category] ?? CentsValueObject::fromCents('0');
    }

    public function uniqueLeadingCategory(): ?string
    {
        $tied = false;
        $leader = null;
        $largestAmount = CentsValueObject::fromCents('0');

        foreach ($this->categories as $category => $amount) {
            $comparison = $amount->compareTo($largestAmount);

            if ($comparison > 0) {
                $leader = $category;
                $largestAmount = $amount;
                $tied = false;
            } elseif ($comparison === 0) {
                $tied = true;
            }
        }

        return $tied ? null : $leader;
    }
}
