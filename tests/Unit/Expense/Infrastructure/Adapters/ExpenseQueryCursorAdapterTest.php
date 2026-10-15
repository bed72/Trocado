<?php

declare(strict_types=1);

use App\Expense\Application\Data\ExpenseCursorOutput;
use App\Expense\Application\Data\GetAllExpenseInput;
use App\Expense\Application\Exceptions\InvalidExpenseCursorException;
use App\Expense\Infrastructure\Adapters\ExpenseQueryCursorAdapter;
use Tests\Support\Core\Fixtures\UuidFixture;
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
    expect(fn () => $adapter->decode(new GetAllExpenseInput(cursor: ExpenseCursorFixture::encode($payload))))
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
    expect(fn () => (new ExpenseQueryCursorAdapter)->decode(new GetAllExpenseInput(cursor: $encoded)))
        ->toThrow(InvalidExpenseCursorException::class);
})->with(['invalid characters' => '@', 'invalid json' => 'YWJj', 'null JSON' => 'bnVsbA', 'oversized' => str_repeat('a', 4097), 'padding' => 'e30=']);

it('round trips v2 positions with a UUID separate from integer cents', function (bool $forward): void {
    $adapter = new ExpenseQueryCursorAdapter;
    $input = new GetAllExpenseInput(sorts: ['amount', 'description', '-occurred_on']);
    $position = ['amount' => PHP_INT_MAX, 'description' => '', 'occurred_on' => '2026-09-24', 'id' => UuidFixture::at(999)];
    $cursor = $adapter->encode($input, new ExpenseCursorOutput($position, $forward));
    expect(ExpenseCursorFixture::payload($cursor)['v'])->toBe(2);
    $decoded = $adapter->decode(new GetAllExpenseInput(cursor: $cursor, sorts: $input->sorts));
    expect($decoded->position)->toBe($position)->and($decoded->forward)->toBe($forward);
})->with([true, false]);

it('canonicalizes UUID case without coercing the amount', function (): void {
    $adapter = new ExpenseQueryCursorAdapter;
    $input = new GetAllExpenseInput(sorts: ['amount']);
    $cursor = $adapter->encode($input, new ExpenseCursorOutput(['amount' => 1, 'id' => strtoupper(UuidFixture::at(10))], true));
    $decoded = $adapter->decode(new GetAllExpenseInput(cursor: $cursor, sorts: ['amount']));
    expect($decoded->position)->toBe(['amount' => 1, 'id' => UuidFixture::at(10)]);
});

it('rejects incompatible v2 fields and numeric legacy versions', function (array $changes): void {
    $adapter = new ExpenseQueryCursorAdapter;
    $input = new GetAllExpenseInput(sorts: ['amount']);
    $payload = ['v' => 2, 'query' => $adapter->fingerprint($input), 'position' => ['amount' => 100, 'id' => UuidFixture::at(1)], 'forward' => true];
    foreach ($changes as $field => $value) {
        if (str_starts_with($field, 'position.')) {
            $payload['position'][substr($field, 9)] = $value;
        } else {
            $payload[$field] = $value;
        }
    }
    expect(fn () => $adapter->decode(new GetAllExpenseInput(cursor: ExpenseCursorFixture::encode($payload), sorts: ['amount'])))->toThrow(InvalidExpenseCursorException::class);
})->with([
    'v1' => [['v' => 1]],
    'integer id' => [['position.id' => 42]],
    'numeric string id' => [['position.id' => '42']],
    'v4 id' => [['position.id' => '017f22e2-79b0-4cc3-98c4-000000000001']],
    'invalid variant' => [['position.id' => '017f22e2-79b0-7cc3-08c4-000000000001']],
    'UUID as amount' => [['position.amount' => UuidFixture::at(1)]],
    'string amount' => [['position.amount' => '100']],
    'fractional amount' => [['position.amount' => 100.5]],
    'non boolean direction' => [['forward' => 1]],
    'extra field' => [['position.user_id' => UuidFixture::at(2)]],
    'wrong fields' => [['position' => ['id' => UuidFixture::at(1), 'amount' => 100]]],
]);
