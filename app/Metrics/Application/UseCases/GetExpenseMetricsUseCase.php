<?php

declare(strict_types=1);

namespace App\Metrics\Application\UseCases;

use App\Core\Application\Ports\UserPort;
use App\Core\Domain\Enums\ExpenseCategoryEnum;
use App\Core\Domain\ValueObjects\AmountValueObject;
use App\Core\Domain\ValueObjects\RatioValueObject;
use App\Metrics\Application\Data\ExpenseCategoryMetricsOutput;
use App\Metrics\Application\Data\ExpenseCategoryTotalOutput;
use App\Metrics\Application\Data\ExpenseMetricsOutput;
use App\Metrics\Application\Data\ExpenseMetricsProjectionOutput;
use App\Metrics\Application\Data\GetExpenseMetricsInput;
use App\Metrics\Application\Exceptions\InvalidExpenseMetricsProjectionException;
use App\Metrics\Application\Ports\ExpenseMetricsPort;
use App\Metrics\Domain\Enums\ExpenseMetricsGroupingEnum;

final readonly class GetExpenseMetricsUseCase
{
    public function __construct(
        private UserPort $userPort,
        private ExpenseMetricsPort $metricsPort,
    ) {}

    public function execute(GetExpenseMetricsInput $input): ExpenseMetricsOutput
    {
        $userId = $this->userPort->id();
        $projection = $this->metricsPort->summarize(
            userId: $userId,
            period: $input->period,
            grouping: $input->grouping,
        );
        $total = AmountValueObject::fromAmount($projection->totalAmount);

        if ($input->grouping === ExpenseMetricsGroupingEnum::Total && $projection->categories !== []) {
            throw new InvalidExpenseMetricsProjectionException('Uma consulta sem agrupamento não deve fornecer categorias.');
        }

        return new ExpenseMetricsOutput(
            id: hash('sha256', implode('|', [
                (string) $userId,
                $input->period->to(),
                $input->period->from(),
                $input->grouping->value,
            ])),
            period: $input->period,
            totalAmount: $total->amount(),
            categories: $input->grouping === ExpenseMetricsGroupingEnum::Category
                ? $this->categoryMetrics($projection, $total)
                : null,
        );
    }

    /** @return list<ExpenseCategoryMetricsOutput> */
    private function categoryMetrics(ExpenseMetricsProjectionOutput $projection, AmountValueObject $total): array
    {
        $amounts = [];
        $categories = [];
        $sum = AmountValueObject::fromAmount('0');

        if (! array_is_list($projection->categories)) {
            throw new InvalidExpenseMetricsProjectionException('A projeção deve fornecer uma lista de categorias.');
        }

        foreach ($projection->categories as $category) {
            if (! $category instanceof ExpenseCategoryTotalOutput || ExpenseCategoryEnum::tryFrom($category->category) === null
                || isset($amounts[$category->category])) {
                throw new InvalidExpenseMetricsProjectionException('A projeção deve conter categorias identificadas e únicas.');
            }

            $amount = AmountValueObject::fromAmount($category->totalAmount);

            if ($amount->isZero()) {
                throw new InvalidExpenseMetricsProjectionException('Uma categoria presente deve possuir total positivo.');
            }

            $sum = $sum->plus($amount);
            $amounts[$category->category] = $amount;
        }

        if ($sum->compareTo($total) !== 0) {
            throw new InvalidExpenseMetricsProjectionException('As categorias devem representar o total do período.');
        }

        foreach ($amounts as $category => $amount) {
            $categories[] = new ExpenseCategoryMetricsOutput(
                category: $category,
                totalAmount: $amount->amount(),
                percentage: RatioValueObject::fromShare(amount: $amount, total: $total)->roundedPercent(decimalPlaces: 2),
            );
        }

        usort($categories, static fn (ExpenseCategoryMetricsOutput $left, ExpenseCategoryMetricsOutput $right): int => $amounts[$right->category]->compareTo($amounts[$left->category])
            ?: strcmp($left->category, $right->category));

        return $categories;
    }
}
