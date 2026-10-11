<?php

declare(strict_types=1);

use App\Core\Domain\Enums\ExpenseCategoryEnum;
use App\Expense\Application\Data\ApplyExpenseClassificationInput;
use App\Expense\Application\Data\GetAllExpenseInput;
use App\Expense\Application\Data\UpdateExpenseInput;
use App\Expense\Application\Repositories\ExpenseCategorizationRepository;
use App\Expense\Application\Repositories\ExpenseRepository;
use App\Expense\Domain\Entities\ExpenseEntity;
use App\Identity\Domain\Enums\UserStatusEnum;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Tests\Support\Expense\Fixtures\ExpenseQueryHistoryFixture;
use Tests\Support\Identity\Fixtures\IdentityFixture;

it('shares equivalent categories and isolates every query cache dimension', function (string $store): void {
    config()->set('cache.default', $store);
    $owner = IdentityFixture::create(UserStatusEnum::Active, new DateTimeImmutable('2026-01-01'));
    $other = IdentityFixture::create(UserStatusEnum::Active, null, email: 'other@example.com');
    foreach (['2026-09-01', '2026-09-02', '2026-09-03'] as $date) {
        ExpenseQueryHistoryFixture::create($owner->id, $date, 1000, 'food', 'Água');
        ExpenseQueryHistoryFixture::create($other->id, $date, 1000, 'food', 'Água');
    }
    $repository = app(ExpenseRepository::class);
    $input = new GetAllExpenseInput(size: 1, from: '2026-09-01', to: '2026-09-30', categories: ['food', 'transport'], amountMin: 0, amountMax: 3000, sorts: ['amount', 'description']);
    $connection = DB::connection();
    $connection->enableQueryLog();
    $connection->flushQueryLog();

    try {
        $first = $repository->getAll($owner->id, $input);
        $equivalent = new GetAllExpenseInput(...array_replace(get_object_vars($input), ['categories' => ['transport', 'food', 'food']]));
        $hit = $repository->getAll($owner->id, $equivalent);
        expect($connection->getQueryLog())->toHaveCount(1)->and($hit)->toEqual($first);
        $repository->getAll($other->id, $input);
        $variants = [
            ['from' => '2026-09-02'], ['to' => '2026-09-02'], ['categories' => ['food']], ['amountMin' => 1], ['amountMax' => 2000],
            ['sorts' => ['-amount', 'description']], ['sorts' => ['description', 'amount']], ['size' => 2], ['cursor' => $first->nextCursor],
        ];
        foreach ($variants as $changes) {
            $variant = new GetAllExpenseInput(...array_replace(get_object_vars($input), $changes));
            $repository->getAll($owner->id, $variant);
            $repository->getAll($owner->id, $variant);
        }
        expect($connection->getQueryLog())->toHaveCount(11);
    } finally {
        $connection->disableQueryLog();
        $connection->flushQueryLog();
    }
})->with(['array', 'redis'])->group('integration', 'redis');

it('invalidates all query variants only after committed CRUD or classification and preserves other owners', function (string $operation, bool $commit): void {
    config()->set('cache.default', 'redis');
    $owner = IdentityFixture::create(UserStatusEnum::Active, new DateTimeImmutable('2026-01-01'));
    $other = IdentityFixture::create(UserStatusEnum::Active, null, email: 'other@example.com');
    $id = ExpenseQueryHistoryFixture::create($owner->id, '2026-09-01', 1000, $operation === 'classification' ? 'other' : 'food', 'Água');
    ExpenseQueryHistoryFixture::create($other->id, '2026-09-01', 1000, 'food', 'Água');
    $before = DB::table('expenses')->orderBy('id')->get()->all();
    $repository = app(ExpenseRepository::class);
    $queries = [new GetAllExpenseInput(categories: ['food'], sorts: ['description']), new GetAllExpenseInput(from: '2026-09-01', sorts: ['-amount'])];
    foreach ([$owner->id, $other->id] as $userId) {
        foreach ($queries as $input) {
            $repository->getAll($userId, $input);
        }
        Cache::tags("expense:pages:owner:{$userId}")->put('sentinel', 'old', 60);
    }
    $write = function () use ($repository, $owner, $id, $operation): void {
        if ($operation === 'create') {
            $repository->create(new ExpenseEntity(id: null, userId: $owner->id, amount: 2000, occurredOn: '2026-09-02', category: 'food'));
        } elseif ($operation === 'update') {
            $repository->update($id, $owner->id, new UpdateExpenseInput(category: 'transport', hasCategory: true));
        } elseif ($operation === 'delete') {
            $repository->delete($id, $owner->id);
        } else {
            $attempts = app(ExpenseCategorizationRepository::class);
            $attempts->beginClassificationAttempt($id, str_repeat('a', 32), new DateTimeImmutable('2099-01-01'));
            expect($attempts->applyClassificationAttempt(new ApplyExpenseClassificationInput($id, str_repeat('a', 32), 'Água', ExpenseCategoryEnum::Transport)))->toBe($owner->id);
        }
        expect(Cache::tags("expense:pages:owner:{$owner->id}")->get('sentinel'))->toBe('old');
    };
    if ($commit) {
        DB::transaction($write);
    } else {
        $sentinel = new RuntimeException('Abort the mutation.');
        try {
            DB::transaction(function () use ($write, $sentinel): void {
                $write();
                throw $sentinel;
            });
            $this->fail('The mutation must propagate its sentinel.');
        } catch (RuntimeException $exception) {
            expect($exception)->toBe($sentinel);
        }
        expect(DB::table('expenses')->orderBy('id')->get()->all())->toEqual($before);
    }
    expect(Cache::tags("expense:pages:owner:{$owner->id}")->get('sentinel'))->toBe($commit ? null : 'old')
        ->and(Cache::tags("expense:pages:owner:{$other->id}")->get('sentinel'))->toBe('old');

    DB::enableQueryLog();
    DB::flushQueryLog();
    try {
        foreach ($queries as $input) {
            $repository->getAll($owner->id, $input);
            $repository->getAll($other->id, $input);
        }
        expect(DB::getQueryLog())->toHaveCount($commit ? 2 : 0);
    } finally {
        DB::disableQueryLog();
        DB::flushQueryLog();
    }
})->with(['create commit' => ['create', true], 'create rollback' => ['create', false], 'update commit' => ['update', true], 'update rollback' => ['update', false], 'delete commit' => ['delete', true], 'delete rollback' => ['delete', false], 'classification commit' => ['classification', true], 'classification rollback' => ['classification', false]])->group('integration', 'redis');

it('expires pages after sixty seconds and does not reuse the old namespace', function (): void {
    Carbon::setTestNow('2026-10-11 12:00:00 UTC');
    $owner = IdentityFixture::create(UserStatusEnum::Active, new DateTimeImmutable('2026-01-01'));
    $id = ExpenseQueryHistoryFixture::create($owner->id, '2026-09-01', 1000, 'food');
    $oldKey = "expense:pages:v1:{$owner->id}:20:".hash('sha256', 'none');
    Cache::tags("expense:pages:owner:{$owner->id}")->put($oldKey, ['items' => [], 'nextCursor' => 'old', 'previousCursor' => null], 60);
    $repository = app(ExpenseRepository::class);
    $input = new GetAllExpenseInput;
    expect($repository->getAll($owner->id, $input)->items[0]->id)->toBe($id);
    DB::table('expenses')->where('id', $id)->update(['amount' => 2000]);
    expect($repository->getAll($owner->id, $input)->items[0]->amount)->toBe(1000);
    Carbon::setTestNow('2026-10-11 12:01:01 UTC');
    expect($repository->getAll($owner->id, $input)->items[0]->amount)->toBe(2000);
});
