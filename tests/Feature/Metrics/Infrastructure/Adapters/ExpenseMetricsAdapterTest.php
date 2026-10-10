<?php

declare(strict_types=1);

use App\Core\Domain\Enums\ExpenseCategoryEnum;
use App\Core\Domain\ValueObjects\AmountValueObject;
use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Metrics\Domain\Enums\ExpenseMetricsGroupingEnum;
use App\Metrics\Infrastructure\Adapters\ExpenseMetricsAdapter;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;

function createMetricsUser(string $email = 'metrics@example.com'): int
{
    return DB::table('users')->insertGetId([
        'name' => 'Maria', 'email' => $email, 'password' => 'unused',
    ]);
}

function insertMetricsExpense(int $userId, string $date, int $amount, string $category = 'other'): int
{
    return DB::table('expenses')->insertGetId([
        'user_id' => $userId, 'occurred_on' => $date, 'amount' => $amount, 'category' => $category,
        'created_at' => '2026-11-12 12:00:00', 'updated_at' => '2026-11-12 12:00:00',
    ]);
}

it('reads only the owner inclusive occurrence period in one statement without writes', function (ExpenseMetricsGroupingEnum $grouping): void {
    $userId = createMetricsUser();
    $otherId = createMetricsUser('other-metrics@example.com');
    insertMetricsExpense($userId, '2026-09-30', 99999);
    insertMetricsExpense($userId, '2026-10-01', 6000, 'food');
    insertMetricsExpense($userId, '2026-10-31', 4000, 'transport');
    insertMetricsExpense($userId, '2026-11-01', 99999);
    insertMetricsExpense($otherId, '2026-10-01', 90000, 'food');
    $before = DB::table('expenses')->orderBy('id')->get()->all();
    DB::enableQueryLog();
    DB::flushQueryLog();

    try {
        $output = (new ExpenseMetricsAdapter)->summarize(
            $userId, DatePeriodValueObject::fromDates('2026-10-01', '2026-10-31'), $grouping,
        );
        $queries = DB::getQueryLog();
    } finally {
        DB::disableQueryLog();
    }

    expect($output->totalAmount)->toBe('10000')
        ->and($queries)->toHaveCount(1)
        ->and($queries[0]['bindings'])->toBe([$userId, '2026-10-01', '2026-10-31'])
        ->and($queries[0]['query'])->toStartWith('select ')
        ->and($queries[0]['query'])->not->toContain('users', 'created_at', 'updated_at', 'description', 'for update')
        ->and(DB::table('expenses')->orderBy('id')->get()->all())->toEqual($before);

    if ($grouping === ExpenseMetricsGroupingEnum::Category) {
        expect(array_column($output->categories, 'category'))->toBe(['food', 'transport'])
            ->and(array_column($output->categories, 'totalAmount'))->toBe(['6000', '4000']);
    } else {
        expect($output->categories)->toBe([]);
    }
})->with(ExpenseMetricsGroupingEnum::cases());

it('returns canonical zero only for an empty owner period even when another owner has expenses', function (ExpenseMetricsGroupingEnum $grouping): void {
    $userId = createMetricsUser();
    insertMetricsExpense(createMetricsUser('other-metrics@example.com'), '2026-10-01', 90000);
    insertMetricsExpense($userId, '2026-09-30', 100);

    $output = (new ExpenseMetricsAdapter)->summarize(
        $userId, DatePeriodValueObject::fromDates('2026-10-01', '2026-10-31'), $grouping,
    );

    expect($output->totalAmount)->toBe('0')->and($output->categories)->toBe([]);
})->with(ExpenseMetricsGroupingEnum::cases());

it('preserves sums above native integers in both modes and reconciles exact groups', function (ExpenseMetricsGroupingEnum $grouping): void {
    $userId = createMetricsUser();
    insertMetricsExpense($userId, '2026-10-01', 4000000000000000000, 'food');
    insertMetricsExpense($userId, '2026-10-01', 4000000000000000000, 'food');
    insertMetricsExpense($userId, '2026-10-01', 4000000000000000000, 'food');
    insertMetricsExpense($userId, '2026-10-01', 1, 'other');

    $output = (new ExpenseMetricsAdapter)->summarize(
        $userId, DatePeriodValueObject::fromDates('2026-10-01', '2026-10-31'), $grouping,
    );

    expect($output->totalAmount)->toBe('12000000000000000001');

    if ($grouping === ExpenseMetricsGroupingEnum::Category) {
        expect(array_column($output->categories, 'totalAmount'))->toBe(['12000000000000000000', '1']);
        $sum = AmountValueObject::fromAmount('0');

        foreach ($output->categories as $category) {
            $sum = $sum->plus(AmountValueObject::fromAmount($category->totalAmount));
        }

        expect($sum->amount())->toBe($output->totalAmount);
    }
})->with(ExpenseMetricsGroupingEnum::cases());

it('aggregates all categories in one statement with exact numeric ordering and alphabetical ties', function (): void {
    $userId = createMetricsUser();

    foreach (ExpenseCategoryEnum::cases() as $category) {
        insertMetricsExpense($userId, '2026-10-01', 900, $category->value);
    }

    insertMetricsExpense($userId, '2026-10-01', 9100, 'food');
    insertMetricsExpense($userId, '2026-10-01', 4100, 'transport');
    insertMetricsExpense($userId, '2026-10-01', 4100, 'health');
    DB::enableQueryLog();
    DB::flushQueryLog();

    try {
        $output = (new ExpenseMetricsAdapter)->summarize(
            $userId, DatePeriodValueObject::fromDates('2026-10-01', '2026-10-31'), ExpenseMetricsGroupingEnum::Category,
        );
        $queries = DB::getQueryLog();
    } finally {
        DB::disableQueryLog();
    }

    expect($queries)->toHaveCount(1)
        ->and($output->totalAmount)->toBe('26300')
        ->and(array_column($output->categories, 'category'))->toBe([
            'food', 'health', 'transport', 'education', 'housing', 'leisure', 'other', 'services', 'shopping', 'subscriptions',
        ])
        ->and(array_column($output->categories, 'totalAmount'))->toBe([
            '10000', '5000', '5000', '900', '900', '900', '900', '900', '900', '900',
        ]);
});

it('accepts single days future years leap days and extreme civil bounds through PostgreSQL', function (string $from, string $to): void {
    $userId = createMetricsUser();
    insertMetricsExpense($userId, $from, 1);
    insertMetricsExpense($userId, $to, 2);

    $output = (new ExpenseMetricsAdapter)->summarize(
        $userId, DatePeriodValueObject::fromDates($from, $to), ExpenseMetricsGroupingEnum::Category,
    );

    expect($output->totalAmount)->toBe('3')
        ->and($output->categories)->toHaveCount(1)
        ->and($output->categories[0]->totalAmount)->toBe('3');
})->with([
    ['2026-10-09', '2026-10-09'],
    ['2027-01-01', '2027-01-31'],
    ['2028-02-29', '2028-02-29'],
    ['2020-01-01', '2026-12-31'],
    ['0001-01-01', '9999-12-31'],
]);

it('reads confirmed creations edits recategorizations date changes and deletions without cache', function (): void {
    $userId = createMetricsUser();
    $adapter = new ExpenseMetricsAdapter;
    $period = DatePeriodValueObject::fromDates('2026-10-01', '2026-10-31');
    $read = fn () => $adapter->summarize($userId, $period, ExpenseMetricsGroupingEnum::Category);
    $id = insertMetricsExpense($userId, '2026-10-01', 10000);
    expect($read()->totalAmount)->toBe('10000');
    $secondId = insertMetricsExpense($userId, '2026-10-02', 2500, 'food');
    expect($read()->totalAmount)->toBe('12500');
    DB::table('expenses')->where('id', $id)->update(['amount' => 20000, 'category' => 'food']);
    $output = $read();
    expect($output->totalAmount)->toBe('22500')
        ->and($output->categories)->toHaveCount(1)
        ->and($output->categories[0]->category)->toBe('food');
    DB::table('expenses')->where('id', $id)->update(['occurred_on' => '2026-09-30']);
    expect($read()->totalAmount)->toBe('2500');
    DB::table('expenses')->where('id', $secondId)->delete();
    expect($read()->totalAmount)->toBe('0')->and($read()->categories)->toBe([]);
});

it('propagates real SQL failures instead of returning empty metrics', function (ExpenseMetricsGroupingEnum $grouping): void {
    $userId = createMetricsUser();
    DB::beginTransaction();

    try {
        DB::statement('ALTER TABLE expenses RENAME COLUMN amount TO unavailable_amount');

        expect(fn () => (new ExpenseMetricsAdapter)->summarize(
            $userId, DatePeriodValueObject::fromDates('2026-10-01', '2026-10-31'), $grouping,
        ))->toThrow(QueryException::class);
    } finally {
        DB::rollBack();
    }
})->with(ExpenseMetricsGroupingEnum::cases());
