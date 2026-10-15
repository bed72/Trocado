<?php

declare(strict_types=1);

namespace App\Expense\Application\Data;

final readonly class GetAllExpenseInput
{
    /** @param list<string> $categories
     * @param  list<string>  $sorts
     */
    public function __construct(
        public int $size = 20,
        public ?string $to = null,
        public ?string $from = null,
        public ?string $cursor = null,
        public ?int $amountMin = null,
        public ?int $amountMax = null,
        public array $categories = [],
        public array $sorts = ['-occurred_on'],
    ) {}
}
