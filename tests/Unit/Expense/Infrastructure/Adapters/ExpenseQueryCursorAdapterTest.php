<?php

declare(strict_types=1);

use App\Expense\Application\Data\GetAllExpenseInput;
use App\Expense\Application\Exceptions\InvalidExpenseCursorException;
use App\Expense\Infrastructure\Adapters\ExpenseQueryCursorAdapter;
use Tests\Support\Expense\Fixtures\ExpenseCursorFixture;

it('normalizes category identity but preserves criteria sort direction and priority', function (): void {
    $adapter = new ExpenseQueryCursorAdapter;
    $input = new GetAllExpenseInput(from: '2026-09-01', to: '2026-09-30', categories: ['food', 'transport'], amountMin: 0, sorts: ['amount', 'description']);
    $equivalent = new GetAllExpenseInput(...array_replace(get_object_vars($input), ['size' => 6, 'categories' => ['transport', 'food', 'food'], 'cursor' => 'opaque']));
    expect($adapter->fingerprint($equivalent))->toBe($adapter->fingerprint($input));
    foreach ([['sorts' => ['description', 'amount']], ['sorts' => ['-amount', 'description']], ['amountMin' => null], ['to' => null]] as $changes) {
        expect($adapter->fingerprint(new GetAllExpenseInput(...array_replace(get_object_vars($input), $changes))))->not->toBe($adapter->fingerprint($input));
    }
});

it('strictly validates legacy field names types and calendar dates', function (array $payload): void {
    $adapter = new ExpenseQueryCursorAdapter;
    expect(fn () => $adapter->decode(new GetAllExpenseInput(cursor: ExpenseCursorFixture::encode($payload), legacyCursorAllowed: true)))
        ->toThrow(InvalidExpenseCursorException::class);
})->with([
    'year zero' => [['occurred_on' => '0000-01-01', 'id' => 1, '_pointsToNextItems' => true]],
    'invalid leap day' => [['occurred_on' => '2026-02-29', 'id' => 1, '_pointsToNextItems' => true]],
    'id string' => [['occurred_on' => '2026-09-01', 'id' => '1', '_pointsToNextItems' => true]],
    'negative id' => [['occurred_on' => '2026-09-01', 'id' => -1, '_pointsToNextItems' => true]],
    'numeric direction' => [['occurred_on' => '2026-09-01', 'id' => 1, '_pointsToNextItems' => 1]],
    'extra field' => [['occurred_on' => '2026-09-01', 'id' => 1, '_pointsToNextItems' => true, 'user_id' => 1]],
    'missing id' => [['occurred_on' => '2026-09-01', '_pointsToNextItems' => true]],
]);

it('does not decode non canonical or malformed cursor representations', function (string $encoded): void {
    expect(fn () => (new ExpenseQueryCursorAdapter)->decode(new GetAllExpenseInput(cursor: $encoded, legacyCursorAllowed: true)))
        ->toThrow(InvalidExpenseCursorException::class);
})->with(['invalid characters' => '@', 'invalid json' => 'YWJj', 'null JSON' => 'bnVsbA', 'oversized' => str_repeat('a', 4097), 'padding' => 'e30=']);
