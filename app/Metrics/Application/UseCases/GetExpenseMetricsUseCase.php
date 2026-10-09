<?php

declare(strict_types=1);

namespace App\Metrics\Application\UseCases;

use App\Core\Application\Ports\UserPort;
use App\Core\Domain\Enums\ExpenseCategoryEnum;
use App\Core\Domain\ValueObjects\CentsValueObject;
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
        $total = CentsValueObject::fromCents($projection->totalCents);

        if ($input->grouping === ExpenseMetricsGroupingEnum::Total && $projection->categories !== []) {
            throw new InvalidExpenseMetricsProjectionException('Uma consulta sem agrupamento não deve fornecer categorias.');
        }

        return new ExpenseMetricsOutput(
            id: hash('sha256', implode('|', [
                (string) $userId,
                $input->period->from(),
                $input->period->to(),
                $input->grouping->value,
            ])),
            period: $input->period,
            totalCents: $total->cents(),
            categories: $input->grouping === ExpenseMetricsGroupingEnum::Category
                ? $this->categoryMetrics($projection, $total)
                : null,
        );
    }

    /** @return list<ExpenseCategoryMetricsOutput> */
    private function categoryMetrics(ExpenseMetricsProjectionOutput $projection, CentsValueObject $total): array
    {
        $cents = [];
        $categories = [];
        $sum = CentsValueObject::fromCents('0');

        if (! array_is_list($projection->categories)) {
            throw new InvalidExpenseMetricsProjectionException('A projeção deve fornecer uma lista de categorias.');
        }

        foreach ($projection->categories as $category) {
            if (! $category instanceof ExpenseCategoryTotalOutput || ExpenseCategoryEnum::tryFrom($category->category) === null
                || isset($cents[$category->category])) {
                throw new InvalidExpenseMetricsProjectionException('A projeção deve conter categorias identificadas e únicas.');
            }

            $amount = CentsValueObject::fromCents($category->totalCents);

            if ($amount->isZero()) {
                throw new InvalidExpenseMetricsProjectionException('Uma categoria presente deve possuir total positivo.');
            }

            $sum = $sum->plus($amount);
            $cents[$category->category] = $amount;
        }

        if ($sum->compareTo($total) !== 0) {
            throw new InvalidExpenseMetricsProjectionException('As categorias devem representar o total do período.');
        }

        foreach ($cents as $category => $amount) {
            $categories[] = new ExpenseCategoryMetricsOutput(
                category: $category,
                totalCents: $amount->cents(),
                percentage: RatioValueObject::fromShare(cent: $amount, total: $total)->roundedPercent(decimalPlaces: 2),
            );
        }

        usort($categories, static fn (ExpenseCategoryMetricsOutput $left, ExpenseCategoryMetricsOutput $right): int => $cents[$right->category]->compareTo($cents[$left->category])
            ?: strcmp($left->category, $right->category));

        return $categories;
    }
}
