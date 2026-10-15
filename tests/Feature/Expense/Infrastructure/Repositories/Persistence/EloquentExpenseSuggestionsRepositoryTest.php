<?php

declare(strict_types=1);

use App\Core\Application\Ports\UserPort;
use App\Core\Domain\ValueObjects\DatePeriodValueObject;
use App\Expense\Application\Repositories\ExpenseSuggestionsRepository;
use App\Expense\Application\UseCases\GetExpenseSuggestionsUseCase;
use App\Expense\Infrastructure\Repositories\Persistence\EloquentExpenseSuggestionsRepository;
use App\Identity\Domain\Enums\UserStatusEnum;
use Illuminate\Support\Facades\DB;
use Tests\Support\Core\Fixtures\UuidFixture;
use Tests\Support\Core\Stubs\UserPortStub;
use Tests\Support\Expense\Fixtures\ExpenseSuggestionHistoryFixture;
use Tests\Support\Identity\Fixtures\IdentityFixture;

beforeEach(function (): void {
    $this->owner = IdentityFixture::create(UserStatusEnum::Active, new DateTimeImmutable('2026-01-01'));
    $this->period = DatePeriodValueObject::fromDates('2026-07-01', '2026-09-30');
    $this->repository = app(ExpenseSuggestionsRepository::class);
});

it('resolves the repository binding through the suggestions use case', function (): void {
    ExpenseSuggestionHistoryFixture::create($this->owner->id, 'Internet', 14000, '2026-07-01', '2026-07-01 12:00:00');
    $this->app->instance(UserPort::class, new UserPortStub($this->owner->id));

    expect($this->repository)->toBeInstanceOf(EloquentExpenseSuggestionsRepository::class)
        ->and(app(GetExpenseSuggestionsUseCase::class)->execute('Int', '2026-10-11')[0]->description)->toBe('Internet');
});

it('isolates descriptions spelling ranking and monetary facts before aggregation', function (): void {
    $other = IdentityFixture::create(UserStatusEnum::Active, null, email: 'other@example.com');
    ExpenseSuggestionHistoryFixture::create($this->owner->id, 'Internet', 14000, '2026-07-01', '2026-07-01 12:00:00');
    ExpenseSuggestionHistoryFixture::create($this->owner->id, 'Internal', 9000, '2026-07-01', '2026-08-01 12:00:00');
    foreach (['2026-08-01', '2026-09-01'] as $date) {
        ExpenseSuggestionHistoryFixture::create($other->id, 'INTERNET', 15000, $date, '2026-10-11 12:00:00');
    }
    ExpenseSuggestionHistoryFixture::create($other->id, 'Intercom', 100, '2026-07-01', '2026-10-11 12:00:00');

    $output = $this->repository->search($this->owner->id, 'Int', $this->period);

    expect(array_column($output, 'description'))->toBe(['Internal', 'Internet'])
        ->and($output[1]->representedMonths)->toBe(1)
        ->and($output[1]->minimumAmount)->toBe(14000)
        ->and($output[1]->maximumAmount)->toBe(14000)
        ->and($this->repository->search($other->id, 'Int', $this->period)[0]->description)->toBe('INTERNET');
});

it('normalizes case and external whitespace consistently while selecting latest spelling with id ties', function (): void {
    ExpenseSuggestionHistoryFixture::create($this->owner->id, 'Internet', 14000, '2026-07-01', '2026-07-01 12:00:00');
    ExpenseSuggestionHistoryFixture::create($this->owner->id, "\tinternet\r\n", 14000, '2026-08-01', '2026-08-01 12:00:00');
    ExpenseSuggestionHistoryFixture::create($this->owner->id, 'INTERNET', 14000, '2026-09-01', '2026-09-01 12:00:00');
    ExpenseSuggestionHistoryFixture::create($this->owner->id, " \nInTeRnEt\t ", 14000, '2026-09-02', '2026-09-01 12:00:00');

    $output = $this->repository->search($this->owner->id, "\t iNt \n", $this->period);

    expect($output)->toHaveCount(1)
        ->and($output[0]->key)->toBe('internet')
        ->and($output[0]->description)->toBe('InTeRnEt')
        ->and($output[0]->representedMonths)->toBe(3)
        ->and($output[0]->minimumAmount)->toBe(14000)
        ->and($output[0]->maximumAmount)->toBe(14000);
});

it('preserves accents and internal spaces and excludes unusable descriptions', function (): void {
    foreach ([null, '', " \t\r\n", 'Café', 'CAFÉ', 'Cafe', 'Plano  Internet', 'Plano Internet'] as $index => $description) {
        ExpenseSuggestionHistoryFixture::create($this->owner->id, $description, 100, '2026-07-01', '2026-07-01 12:00:00', UuidFixture::at($index + 1));
    }

    expect(array_column($this->repository->search($this->owner->id, 'Cafe', $this->period), 'description'))->toBe(['Cafe'])
        ->and(array_column($this->repository->search($this->owner->id, 'café', $this->period), 'description'))->toBe(['CAFÉ'])
        ->and(array_column($this->repository->search($this->owner->id, 'Plano Internet', $this->period), 'description'))->toBe(['Plano Internet'])
        ->and(array_column($this->repository->search($this->owner->id, 'Plano  Internet', $this->period), 'description'))->toBe(['Plano  Internet'])
        ->and($this->repository->search($this->owner->id, 'absent', $this->period))->toBe([]);
});

it('searches special characters literally with bound parameters', function (string $term, string $description, string $decoy): void {
    ExpenseSuggestionHistoryFixture::create($this->owner->id, $description, 100, '2026-07-01', '2026-07-01 12:00:00');
    ExpenseSuggestionHistoryFixture::create($this->owner->id, $decoy, 100, '2026-07-01', '2026-07-01 12:00:00');

    expect(array_column($this->repository->search($this->owner->id, $term, $this->period), 'description'))->toBe([$description]);
})->with([
    'percent' => ['%', 'Taxa 10%', 'Taxa 100'],
    'underscore' => ['_', 'Plano_A', 'Plano A'],
    'backslash' => ['\\', 'Plano\\A', 'Plano A'],
    'quote' => ["'", "D'agua", 'Agua'],
    'SQL-shaped text' => ["' OR 1=1 --", "Plano ' OR 1=1 --", 'Internet'],
]);

it('ranks prefix before substring then registration recency frequency and deterministic key', function (): void {
    $rows = [
        ['Internet antigo', '2020-01-01 12:00:00'],
        ['Plano Internet', '2026-10-11 12:00:00'],
        ['Internet frequente', '2026-08-01 12:00:00'],
        ['Internet frequente', '2026-08-01 12:00:00'],
        ['Internet recente', '2026-09-01 12:00:00'],
        ['Internet beta', '2026-08-01 12:00:00'],
        ['Internet alfa', '2026-08-01 12:00:00'],
    ];
    foreach ($rows as [$description, $createdAt]) {
        ExpenseSuggestionHistoryFixture::create($this->owner->id, $description, 100, '2020-01-01', $createdAt);
    }

    expect(array_column($this->repository->search($this->owner->id, 'Int', $this->period), 'description'))->toBe([
        'Internet recente', 'Internet frequente', 'Internet alfa', 'Internet beta', 'Internet antigo',
    ]);
    expect(array_column($this->repository->search($this->owner->id, 'Internet antigo', $this->period), 'representedMonths'))->toBe([0]);
});

it('uses created_at rather than occurrence or update time for recency and keeps substring matches', function (): void {
    $id = ExpenseSuggestionHistoryFixture::create($this->owner->id, 'Internet', 100, '2026-09-30', '2026-08-01 12:00:00');
    DB::table('expenses')->where('id', $id)->update(['updated_at' => '2027-01-01 12:00:00']);
    ExpenseSuggestionHistoryFixture::create($this->owner->id, 'Internet retroativo', 100, '2020-01-01', '2026-10-11 12:00:00');
    ExpenseSuggestionHistoryFixture::create($this->owner->id, 'Plano Internet', 100, '2026-09-30', '2026-11-01 12:00:00');

    expect(array_column($this->repository->search($this->owner->id, 'iNt', $this->period), 'description'))->toBe([
        'Internet retroativo', 'Internet', 'Plano Internet',
    ]);
});

it('counts historical frequency before limiting distinct groups and never limits monetary records', function (): void {
    foreach (['2026-07-01', '2026-08-01', '2026-09-01', '2026-09-02', '2026-09-03', '2026-09-04'] as $date) {
        ExpenseSuggestionHistoryFixture::create($this->owner->id, 'Internet beta', 14000, $date, '2026-10-01 12:00:00');
    }
    ExpenseSuggestionHistoryFixture::create($this->owner->id, 'INTERNET BETA', 15000, '2026-07-02', '2026-07-02 12:00:00');
    foreach (range(1, 8) as $index) {
        ExpenseSuggestionHistoryFixture::create($this->owner->id, 'Internet alfa', 100, '2020-01-01', '2026-10-01 12:00:00');
    }
    foreach (['Internet delta', 'Internet gamma', 'Internet epsilon', 'Internet zeta', 'Internet eta'] as $description) {
        ExpenseSuggestionHistoryFixture::create($this->owner->id, $description, 100, '2020-01-01', '2026-10-01 12:00:00');
    }

    $output = $this->repository->search($this->owner->id, 'Int', $this->period);

    expect(array_column($output, 'key'))->toBe(['internet alfa', 'internet beta', 'internet delta', 'internet epsilon', 'internet eta'])
        ->and($output[0]->representedMonths)->toBe(0)
        ->and($output[1]->representedMonths)->toBe(3)
        ->and($output[1]->minimumAmount)->toBe(14000)
        ->and($output[1]->maximumAmount)->toBe(15000);
});

it('does not let foreign values spoil a complete owner pattern or change tied group frequency', function (): void {
    $other = IdentityFixture::create(UserStatusEnum::Active, null, email: 'foreign@example.com');
    foreach (['2026-07-01', '2026-08-01', '2026-09-01'] as $date) {
        ExpenseSuggestionHistoryFixture::create($this->owner->id, 'Internet', 14000, $date, '2026-09-01 12:00:00');
    }
    ExpenseSuggestionHistoryFixture::create($this->owner->id, 'Internal', 100, '2026-07-01', '2026-09-01 12:00:00');
    foreach (range(1, 5) as $index) {
        ExpenseSuggestionHistoryFixture::create($other->id, 'INTERNAL', 15000, '2026-09-01', '2026-09-01 12:00:00');
    }
    ExpenseSuggestionHistoryFixture::create($other->id, 'INTERNET', 15000, '2026-09-01', '2026-10-11 12:00:00');

    $output = (new GetExpenseSuggestionsUseCase(new UserPortStub($this->owner->id), $this->repository))->execute('Int', '2026-10-11');

    expect(array_column($output, 'description'))->toBe(['Internet', 'Internal'])
        ->and($output[0]->amount)->toBe(14000);
});

it('aggregates every matching value inside inclusive civil limits and transforms the policy without loss', function (array $records, int $months, ?int $minimum, ?int $maximum, ?int $amount): void {
    foreach ($records as [$date, $value]) {
        ExpenseSuggestionHistoryFixture::create($this->owner->id, 'Internet', $value, $date, '2026-10-01 12:00:00');
    }
    $history = $this->repository->search($this->owner->id, 'Int', $this->period)[0];
    $output = (new GetExpenseSuggestionsUseCase(new UserPortStub($this->owner->id), $this->repository))->execute('Int', '2026-10-11')[0];

    expect($history->representedMonths)->toBe($months)
        ->and($history->minimumAmount)->toBe($minimum)
        ->and($history->maximumAmount)->toBe($maximum)
        ->and($output->amount)->toBe($amount);
})->with([
    'inclusive limits with outside divergences' => [[['2026-06-30', 1], ['2026-07-01', 14001], ['2026-08-01', 14001], ['2026-09-30', 14001], ['2026-10-01', 2]], 3, 14001, 14001, 14001],
    'different months' => [[['2026-07-01', 10000], ['2026-08-01', 12000], ['2026-09-01', 10000]], 3, 10000, 12000, null],
    'three records in one month' => [[['2026-09-01', 14000], ['2026-09-02', 14000], ['2026-09-03', 14000]], 1, 14000, 14000, null],
    'missing month' => [[['2026-07-01', 14000], ['2026-09-01', 14000]], 2, 14000, 14000, null],
    'multiple consistent records' => [[['2026-07-01', 14000], ['2026-08-01', 14000], ['2026-09-01', 14000], ['2026-09-02', 14000]], 3, 14000, 14000, 14000],
    'earlier divergent record in same month' => [[['2026-07-01', 14000], ['2026-08-01', 14000], ['2026-09-01', 15000], ['2026-09-02', 14000]], 3, 14000, 15000, null],
    'later divergent record in same month' => [[['2026-07-01', 14000], ['2026-08-01', 14000], ['2026-09-01', 14000], ['2026-09-02', 15000]], 3, 14000, 15000, null],
    'old history only' => [[['2020-01-01', 14000]], 0, null, null, null],
    'exact large integer' => [[['2026-07-01', 9007199254740993], ['2026-08-01', 9007199254740993], ['2026-09-01', 9007199254740993]], 3, 9007199254740993, 9007199254740993, 9007199254740993],
    'maximum expense integer' => [[['2026-07-01', PHP_INT_MAX], ['2026-08-01', PHP_INT_MAX], ['2026-09-01', PHP_INT_MAX]], 3, PHP_INT_MAX, PHP_INT_MAX, PHP_INT_MAX],
]);

it('reads zero one or five groups in a single statement without mutating expenses', function (int $groups, int $expected): void {
    foreach (range(1, max(1, $groups)) as $index) {
        if ($groups > 0) {
            ExpenseSuggestionHistoryFixture::create($this->owner->id, "Internet {$index}", 100, '2026-07-01', '2026-07-01 12:00:00');
        }
    }
    ExpenseSuggestionHistoryFixture::create($this->owner->id, " \t\n ", 100, '2026-07-01', '2026-07-01 12:00:00');
    $before = DB::table('expenses')->orderBy('id')->get()->all();
    $connection = DB::connection();
    $wasLogging = $connection->logging();
    expect($connection->getQueryLog())->toBe([]);
    $connection->enableQueryLog();

    try {
        $output = $this->repository->search($this->owner->id, 'Int', $this->period);
        $queries = $connection->getQueryLog();
    } finally {
        $connection->flushQueryLog();
        if (! $wasLogging) {
            $connection->disableQueryLog();
        }
    }

    expect($output)->toHaveCount($expected)
        ->and($queries)->toHaveCount(1)
        ->and($queries[0]['bindings'])->toBe([$this->owner->id, 'Int', '2026-07-01', '2026-09-30'])
        ->and($queries[0]['query'])->toContain('LIMIT 5')
        ->and(DB::table('expenses')->orderBy('id')->get()->all())->toEqual($before);
})->with(['zero' => [0, 0], 'one' => [1, 1], 'five after limiting' => [6, 5]]);
