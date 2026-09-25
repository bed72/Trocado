<?php

declare(strict_types=1);

use App\Expense\Domain\Entities\ExpenseEntity;
use App\Expense\Domain\Enums\ExpenseCategoryEnum;
use App\Expense\Domain\Exceptions\InvalidExpenseException;

it('defaults the category and keeps valid civil dates and descriptions', function (): void {
    $expense = new ExpenseEntity(id: null, userId: 1, amount: 1250, occurredOn: '2026-09-20');

    expect($expense->category)->toBe(ExpenseCategoryEnum::Other)
        ->and($expense->description)->toBeNull();
});

it('rejects invalid expenses outside HTTP', function (int $userId, int $amount, string $date, ?string $category, ?string $description): void {
    new ExpenseEntity(id: null, userId: $userId, amount: $amount, occurredOn: $date, category: $category, description: $description);
})->with([
    'missing owner' => [0, 1250, '2026-09-20', null, null],
    'zero amount' => [1, 0, '2026-09-20', null, null],
    'negative amount' => [1, -1, '2026-09-20', null, null],
    'invalid calendar date' => [1, 1250, '2026-02-30', null, null],
    'timestamp instead of date' => [1, 1250, '2026-09-20T10:00:00', null, null],
    'unknown category' => [1, 1250, '2026-09-20', 'unknown', null],
    'long category' => [1, 1250, '2026-09-20', str_repeat('a', 33), null],
    'long description' => [1, 1250, '2026-09-20', null, str_repeat('a', 65)],
])->throws(InvalidExpenseException::class);

it('only considers useful expense descriptions eligible for classification', function (?string $description, bool $eligible): void {
    expect(ExpenseEntity::isDescriptionEligibleForClassification($description))->toBe($eligible);
})->with([
    'null' => [null, false],
    'empty' => ['', false],
    'unicode whitespace' => ["\u{00A0}\u{2003}", false],
    'sql injection payload' => ["' OR '1'='1", false],
    'xss payload' => ["<script>alert('hack')</script>", false],
    'numbered transport' => ['Uber 123', true],
    'punctuated grocery purchase' => ['Mercado - 2 itens', true],
]);
