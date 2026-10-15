<?php

declare(strict_types=1);

use App\Expense\Application\Data\GetAllExpenseInput;
use App\Expense\Infrastructure\Repositories\Persistence\EloquentExpenseRepository;
use App\Identity\Domain\Enums\UserStatusEnum;
use Illuminate\Support\Facades\DB;
use Tests\Support\Core\Fixtures\UuidFixture;
use Tests\Support\Identity\Fixtures\IdentityFixture;

it('executes one bounded PostgreSQL statement per query and measures representative plans', function (): void {
    $owner = IdentityFixture::create(UserStatusEnum::Active, new DateTimeImmutable('2026-01-01'));
    $other = IdentityFixture::create(UserStatusEnum::Active, null, email: 'other@example.com');
    $rows = [];
    foreach ([$owner->id, $other->id] as $userId) {
        for ($index = 1; $index <= 1200; $index++) {
            $rows[] = ['id' => UuidFixture::at(count($rows) + 1), 'user_id' => $userId, 'amount' => $index, 'category' => $index % 2 === 0 ? 'food' : 'transport',
                'occurred_on' => sprintf('2026-%02d-%02d', 7 + $index % 3, 1 + $index % 28),
                'description' => $index % 2 === 0 ? 'Água' : 'Mercado',
                'created_at' => '2026-10-11 12:00:00', 'updated_at' => '2026-10-11 12:00:00'];
        }
    }
    DB::table('expenses')->insert($rows);
    DB::statement('ANALYZE expenses');
    $repository = app(EloquentExpenseRepository::class);
    $queries = [
        'default' => new GetAllExpenseInput,
        'combined' => new GetAllExpenseInput(from: '2026-09-01', to: '2026-09-30', categories: ['food'], amountMin: 500, amountMax: 1100),
        'alphabetic' => new GetAllExpenseInput(from: '2026-09-01', to: '2026-09-30', sorts: ['description', 'amount']),
    ];
    $metrics = [];
    foreach ($queries as $name => $input) {
        DB::enableQueryLog();
        DB::flushQueryLog();
        try {
            $page = $repository->getAll($owner->id, $input);
            $log = DB::getQueryLog();
        } finally {
            DB::disableQueryLog();
            DB::flushQueryLog();
        }
        expect($log)->toHaveCount(1)->and($page->items)->toHaveCount(20)
            ->and(strtolower($log[0]['query']))->not->toContain('offset');
        foreach ($page->items as $expense) {
            expect($expense->userId)->toBe($owner->id);
        }
        $result = DB::select('EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) '.$log[0]['query'], $log[0]['bindings']);
        $plan = json_decode($result[0]->{'QUERY PLAN'}, true, flags: JSON_THROW_ON_ERROR)[0];
        expect($plan['Plan']['Node Type'])->toBe('Limit')->and($plan['Plan']['Actual Rows'])->toBe(21);
        $metrics[$name] = ['execution_ms' => $plan['Execution Time'], 'planning_ms' => $plan['Planning Time'], 'rows' => $plan['Plan']['Actual Rows'], 'plan' => $plan['Plan']['Plans'][0]['Node Type']];
    }
    fwrite(STDOUT, "\nExpense query plans (2400 rows): ".json_encode($metrics, JSON_THROW_ON_ERROR)."\n");
});

it('creates only the explicit ICU collation and preserves nullable description and cursor indexes', function (): void {
    $collation = DB::selectOne("SELECT collprovider, collisdeterministic, colliculocale FROM pg_collation WHERE collname = 'expense_description_ci_ai'");
    expect($collation->collprovider)->toBe('i')->and($collation->collisdeterministic)->toBeFalse()->and($collation->colliculocale)->toBe('und-u-ks-level1');
    $column = DB::selectOne("SELECT is_nullable FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'expenses' AND column_name = 'description'");
    expect($column->is_nullable)->toBe('YES');
    $indexes = DB::select("SELECT indexname FROM pg_indexes WHERE schemaname = 'public' AND tablename = 'expenses'");
    expect(array_column($indexes, 'indexname'))->toContain('expenses_owner_cursor_index', 'expenses_user_id_occurred_on_index');
});
