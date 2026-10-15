<?php

declare(strict_types=1);

use App\Core\Domain\Enums\ExpenseCategoryEnum;
use App\Core\Domain\Exceptions\InvalidUuidException;
use App\Expense\Domain\Entities\ExpenseEntity;
use App\Expense\Domain\Exceptions\InvalidExpenseException;
use Tests\Support\Core\Fixtures\UuidFixture;

it('defaults the category and keeps valid civil dates and descriptions', function (): void {
    $expense = new ExpenseEntity(id: null, userId: UuidFixture::at(1), amount: 1250, occurredOn: '2026-09-20');

    expect($expense->category)->toBe(ExpenseCategoryEnum::Other)
        ->and($expense->description)->toBeNull();
});

it('rejects invalid expenses outside HTTP', function (int $userId, int $amount, string $date, ?string $category, ?string $description): void {
    new ExpenseEntity(id: null, userId: UuidFixture::at($userId), amount: $amount, occurredOn: $date, category: $category, description: $description);
})->with([
    'zero amount' => [1, 0, '2026-09-20', null, null],
    'negative amount' => [1, -1, '2026-09-20', null, null],
    'invalid calendar date' => [1, 1250, '2026-02-30', null, null],
    'timestamp instead of date' => [1, 1250, '2026-09-20T10:00:00', null, null],
    'unknown category' => [1, 1250, '2026-09-20', 'unknown', null],
    'long category' => [1, 1250, '2026-09-20', str_repeat('a', 33), null],
    'long description' => [1, 1250, '2026-09-20', null, str_repeat('a', 65)],
])->throws(InvalidExpenseException::class);

it('canonicalizes present expense and owner UUIDs', function (): void {
    $expense = new ExpenseEntity(id: strtoupper(UuidFixture::at(100)), userId: strtoupper(UuidFixture::at(200)), amount: 1, occurredOn: '2026-09-20');
    expect($expense->id)->toBe(UuidFixture::at(100))->and($expense->userId)->toBe(UuidFixture::at(200));
});

it('rejects invalid expense and owner identifiers outside HTTP', function (string $invalid): void {
    expect(fn () => new ExpenseEntity(id: $invalid, userId: UuidFixture::at(1), amount: 1, occurredOn: '2026-09-20'))->toThrow(InvalidUuidException::class);
    expect(fn () => new ExpenseEntity(id: null, userId: $invalid, amount: 1, occurredOn: '2026-09-20'))->toThrow(InvalidUuidException::class);
})->with(['', '1', '00000000-0000-4000-8000-000000000001', '00000000-0000-7000-0000-000000000001', ' '.UuidFixture::at(1)]);

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
