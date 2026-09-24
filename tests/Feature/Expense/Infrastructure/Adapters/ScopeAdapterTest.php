<?php

declare(strict_types=1);

use App\Core\Application\Ports\ScopePort;
use App\Expense\Application\Data\CreateExpenseInput;
use App\Expense\Application\UseCases\CreateExpenseUseCase;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;

it('runs as a limited role with forced RLS and no schema or truncate privileges', function (): void {
    $state = DB::selectOne(<<<'SQL'
        select current_user as role,
               r.rolsuper, r.rolbypassrls,
               c.relrowsecurity, c.relforcerowsecurity,
               c.relowner = r.oid as owns_expenses,
               has_table_privilege(current_user, 'expenses', 'TRUNCATE') as can_truncate,
               has_schema_privilege(current_user, 'public', 'CREATE') as can_create
        from pg_roles r, pg_class c
        where r.rolname = current_user and c.oid = 'expenses'::regclass
        SQL);

    expect($state->role)->toBe('trocado_runtime')
        ->and($state->rolsuper)->toBeFalse()
        ->and($state->rolbypassrls)->toBeFalse()
        ->and($state->relrowsecurity)->toBeTrue()
        ->and($state->relforcerowsecurity)->toBeTrue()
        ->and($state->owns_expenses)->toBeFalse()
        ->and($state->can_truncate)->toBeFalse()
        ->and($state->can_create)->toBeFalse();

    expect(fn () => DB::statement('ALTER TABLE expenses DISABLE ROW LEVEL SECURITY'))->toThrow(QueryException::class);
    expect(fn () => DB::statement('TRUNCATE expenses'))->toThrow(QueryException::class);
    expect(fn () => DB::statement('SET ROLE postgres'))->toThrow(QueryException::class);
});

it('isolates raw reads, writes and soft deleted rows and clears context after commit and rollback', function (): void {
    $a = signUpIdentityByApi($this);
    $b = signUpIdentityByApi($this, 'Pedro', 'Correct1', 'pedro@example.com');
    $create = app(CreateExpenseUseCase::class);
    $scope = app(ScopePort::class);
    $first = $create->execute(new CreateExpenseInput($a, 100, '2026-09-20'));
    $second = $create->execute(new CreateExpenseInput($b, 200, '2026-09-21'));

    $scope->execute($b, fn () => DB::table('expenses')->where('id', $second->id)->update(['deleted_at' => now()]));

    expect(DB::table('expenses')->count())->toBe(0)
        ->and($scope->execute($a, fn () => DB::table('expenses')->pluck('id')->all()))->toBe([$first->id])
        ->and($scope->execute($b, fn () => DB::table('expenses')->pluck('id')->all()))->toBe([$second->id]);

    $scope->execute($a, function () use ($second): void {
        expect(DB::table('expenses')->where('id', $second->id)->update(['amount' => 999]))->toBe(0)
            ->and(DB::table('expenses')->where('id', $second->id)->delete())->toBe(0);
    });

    expect(fn () => $scope->execute($a, fn () => DB::table('expenses')->where('id', $first->id)->update(['user_id' => $b])))
        ->toThrow(QueryException::class);
    expect(fn () => $scope->execute($a, fn () => DB::table('expenses')->insert([
        'user_id' => $b, 'amount' => 100, 'occurred_on' => '2026-09-20', 'category' => 'other', 'created_at' => now(),
    ])))->toThrow(QueryException::class);

    expect(DB::table('expenses')->count())->toBe(0)
        ->and(DB::connection('pgsql_maintenance')->table('expenses')->count())->toBe(2);
    expect(DB::table('expenses')->where('id', $first->id)->update(['amount' => 900]))->toBe(0)
        ->and(DB::table('expenses')->where('id', $first->id)->delete())->toBe(0);
    expect(fn () => DB::table('expenses')->insert([
        'user_id' => $a, 'amount' => 100, 'occurred_on' => '2026-09-20', 'category' => 'other', 'created_at' => now(),
    ]))->toThrow(QueryException::class);

    expect(fn () => $scope->execute($a, function (): void {
        throw new RuntimeException('rollback');
    }))->toThrow(RuntimeException::class);
    expect(DB::table('expenses')->count())->toBe(0)
        ->and($scope->execute($b, fn () => DB::table('expenses')->count()))->toBe(1);
});

it('refuses an outer transaction before accessing the repository', function (): void {
    $userId = signUpIdentityByApi($this);
    $create = app(CreateExpenseUseCase::class);

    expect(fn () => DB::transaction(fn () => $create->execute(new CreateExpenseInput($userId, 100, '2026-09-20'))))
        ->toThrow(LogicException::class);

    expect(DB::connection('pgsql_maintenance')->table('expenses')->count())->toBe(0);
});

it('reestablishes the principal on every serialization retry', function (): void {
    $userId = signUpIdentityByApi($this);
    $attempts = 0;

    $result = app(ScopePort::class)->execute($userId, function () use (&$attempts, $userId): int {
        $attempts++;

        expect(DB::selectOne("select current_setting('app.user_id') as value")->value)->toBe((string) $userId);

        if ($attempts === 1) {
            DB::statement("DO $$ BEGIN RAISE EXCEPTION USING ERRCODE = '40001'; END $$");
        }

        return DB::table('expenses')->count();
    });

    expect($attempts)->toBe(2)
        ->and($result)->toBe(0)
        ->and(DB::table('expenses')->count())->toBe(0);
});
