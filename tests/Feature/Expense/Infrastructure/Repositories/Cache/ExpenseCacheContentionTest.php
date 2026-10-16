<?php

declare(strict_types=1);

use App\Expense\Application\Data\GetAllExpenseInput;
use App\Expense\Application\Data\UpdateExpenseInput;
use App\Expense\Application\Repositories\ExpenseRepository;
use App\Expense\Infrastructure\Repositories\Persistence\EloquentExpenseRepository;
use App\Identity\Domain\Enums\UserStatusEnum;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Tests\Support\Core\Fixtures\ConcurrentDatabaseProcess;
use Tests\Support\Expense\Fixtures\ExpenseCacheContentionFixture;
use Tests\Support\Expense\Fixtures\ExpenseQueryHistoryFixture;
use Tests\Support\Identity\Fixtures\IdentityFixture;

it('measures synchronized duplicate fills against bounded per-page lock prototypes', function (string $mode, string $sort): void {
    config()->set('cache.default', 'redis');
    $owner = IdentityFixture::create(UserStatusEnum::Active, new DateTimeImmutable('2026-01-01'));
    ExpenseCacheContentionFixture::seed($owner->id, 60000);
    $measurements = [];

    for ($round = 0; $round < 3; $round++) {
        $input = new GetAllExpenseInput(size: 20 + $round, sorts: [$sort]);
        $signals = $this->resources->namespace.'contention:'.$round;
        $key = ExpenseCacheContentionFixture::key($owner->id, $input);
        expect(Cache::tags('expense:pages:v3:owner:'.$owner->id)->has($key))->toBeFalse();
        $expected = app(EloquentExpenseRepository::class)->getAll($owner->id, $input);
        $first = new ConcurrentDatabaseProcess(static fn () => ExpenseCacheContentionFixture::reader($owner->id, $input, $mode, $signals, 'first'));
        $second = null;

        try {
            $second = new ConcurrentDatabaseProcess(static fn () => ExpenseCacheContentionFixture::reader($owner->id, $input, $mode, $signals, 'second'));
            $first->go();
            $second->go();
            ExpenseCacheContentionFixture::await($signals.':miss:first', true);
            ExpenseCacheContentionFixture::await($signals.':miss:second', true);
            Cache::put($signals.':release', true, 30);
            $first->done();
            $second->done();
            $results = [Cache::get($signals.':result:first'), Cache::get($signals.':result:second')];
            foreach ($results as $result) {
                expect($result['digest'])->toBe(ExpenseCacheContentionFixture::digest($expected));
            }
            expect(array_sum(array_column($results, 'queries')))->toBe($mode === 'original' ? 2 : 1);
            $measurements[] = [
                'read_ms' => array_column($results, 'read_ms'),
                'sql_ms' => array_column($results, 'sql_ms'),
                'wait_ms' => array_column($results, 'wait_ms'),
                'queries' => array_column($results, 'queries'),
            ];
        } finally {
            Cache::put($signals.':release', true, 30);
            $second?->close();
            $first->close();
        }
    }
    fwrite(STDOUT, "\nExpense cache contention: ".json_encode(['mode' => $mode, 'sort' => $sort, 'rounds' => $measurements], JSON_THROW_ON_ERROR)."\n");
})->with([
    'original default' => ['original', '-occurred_on'],
    'original description' => ['original', 'description'],
    'lock default polling default sort' => ['lock-250ms', '-occurred_on'],
    'lock default polling description' => ['lock-250ms', 'description'],
    'lock short polling default sort' => ['lock-5ms', '-occurred_on'],
    'lock short polling description' => ['lock-5ms', 'description'],
])->group('integration', 'redis', 'concurrency');

it('characterizes a committed invalidation during fill without assuming a page lock fences writes', function (string $mode): void {
    config()->set('cache.default', 'redis');
    $owner = IdentityFixture::create(UserStatusEnum::Active, new DateTimeImmutable('2026-01-01'));
    $id = ExpenseQueryHistoryFixture::create($owner->id, '2026-09-01', 1000, 'food', 'Água');
    $input = new GetAllExpenseInput(sorts: ['description']);
    $signals = $this->resources->namespace.'invalidation';
    $child = new ConcurrentDatabaseProcess(static fn () => ExpenseCacheContentionFixture::pauseAfterRead($owner->id, $input, $mode, $signals));

    try {
        $child->go();
        ExpenseCacheContentionFixture::await($signals.':loaded', true);
        DB::transaction(static fn () => app(ExpenseRepository::class)->update($id, $owner->id, new UpdateExpenseInput(amount: 2000, hasAmount: true)));
        expect(DB::table('expenses')->where('id', $id)->value('amount'))->toBe(2000);
        Cache::put($signals.':release', true, 30);
        $child->done();

        // This is a characterization of the rejected baseline/prototype, not a strengthened cache contract.
        expect(Cache::get($signals.':result')['amount'])->toBe(1000)
            ->and(app(ExpenseRepository::class)->getAll($owner->id, $input)->items[0]->amount)->toBe(1000)
            ->and(app(EloquentExpenseRepository::class)->getAll($owner->id, $input)->items[0]->amount)->toBe(2000);
    } finally {
        Cache::put($signals.':release', true, 30);
        $child->close();
    }
})->with(['original', 'page-lock'])->group('integration', 'redis', 'concurrency');
